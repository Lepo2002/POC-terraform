resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-logs"
  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  sku                 = "PerGB2018"
  retention_in_days   = 30  
  
  tags = local.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = "${local.prefix}-app-insights"
  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = local.common_tags
}

resource "azurerm_monitor_action_group" "dr_alerts" {
  name                = "${local.prefix}-alerts"
  resource_group_name = module.azure_core.resource_group_name
  short_name          = "DRAlerts"
  
  email_receiver {
    name          = "DrTeam"
    email_address = var.alert_email
  }
  
  webhook_receiver {
    name        = "SlackNotification"
    service_uri = "https://hooks.slack.com/services/${var.slack_token}"
  }
}

resource "azurerm_monitor_metric_alert" "dr_health" {
  name                = "${local.prefix}-health-alert"
  resource_group_name = module.azure_core.resource_group_name
  scopes              = [module.azure_kubernetes.cluster_id]
  description         = "Monitoraggio salute ambiente DR"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.dr_alerts.id
  }
  
  tags = local.common_tags
}

resource "google_monitoring_notification_channel" "email" {
  project      = module.gcp_project.project_id
  display_name = "DR Operations Team"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_notification_channel" "slack" {
  project      = module.gcp_project.project_id
  display_name = "DR Slack Notifications"
  type         = "slack"
  
  labels = {
    channel_name = var.slack_channel
    auth_token   = var.slack_token
  }
  
  sensitive_labels {
    auth_token = var.slack_token
  }
}

resource "google_monitoring_alert_policy" "dr_ready" {
  project      = module.gcp_project.project_id
  display_name = "DR Environment Readiness"
  combiner     = "OR"
  
  conditions {
    display_name = "DR GKE Cluster Availability"
    
    condition_threshold {
      filter          = "resource.type = \"k8s_cluster\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/cluster/node_scheduleability\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.slack.id
  ]
  
  documentation {
    content   = "Verifica dello stato di prontezza dell'ambiente DR: il cluster GKE potrebbe non essere in grado di pianificare pod."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "replication_lag" {
  project      = module.gcp_project.project_id
  display_name = "Database Replication Lag"
  combiner     = "OR"
  
  conditions {
    display_name = "Cloud SQL Replication Lag > 60s"
    
    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${google_sql_database_instance.replica.id}\" AND metric.type = \"cloudsql.googleapis.com/database/replication/lag\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 60
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.slack.id
  ]
  
  documentation {
    content   = "Il ritardo di replica del database Cloud SQL è superiore a 60 secondi. Controllare la connettività e la configurazione della replica."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_dashboard" "dr_dashboard" {
  project        = module.gcp_project.project_id
  dashboard_json = <<EOF
{
  "displayName": "DR Environment Readiness Dashboard",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Database Replication Lag",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${google_sql_database_instance.replica.id}\" AND metric.type = \"cloudsql.googleapis.com/database/replication/lag\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Kubernetes Node Readiness",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"k8s_cluster\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/cluster/node_scheduleability\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Network Connectivity to Production",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"gce_network_peering\" AND resource.labels.network_name = \"${module.gcp_networking.vpc_name}\" AND metric.type = \"networking.googleapis.com/peering/connectivity\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "DR Environment Health Score",
        "scorecard": {
          "timeSeriesQuery": {
            "timeSeriesFilter": {
              "filter": "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/uptime\"",
              "aggregation": {
                "alignmentPeriod": "60s",
                "perSeriesAligner": "ALIGN_RATE",
                "crossSeriesReducer": "REDUCE_COUNT"
              }
            }
          },
          "thresholds": [
            { "value": 0, "color": "RED" },
            { "value": 5, "color": "YELLOW" }, 
            { "value": 10, "color": "GREEN" }
          ],
          "gaugeView": {
            "lowerBound": 0,
            "upperBound": 20
          }
        }
      }
    ]
  }
}
EOF
}

resource "google_cloud_scheduler_job" "failover_test" {
  name        = "dr-failover-test"
  project     = module.gcp_project.project_id
  region      = var.gcp_region
  description = "Test periodico del processo di failover DR"
  schedule    = "0 8 15 * *"  
  time_zone   = "Europe/Rome"
  
  http_target {
    uri         = "https://dr-test.${var.project_name}.internal/failover-test"
    http_method = "POST"
    
    oauth_token {
      service_account_email = module.gcp_iam.service_account_email
    }
    
    body = base64encode(jsonencode({
      "testMode": true,
      "testComponents": ["database", "kubernetes", "network"],
      "notifyEmail": var.alert_email
    }))
  }
}

resource "azurerm_monitor_activity_log_alert" "peering_disconnected" {
  name                = "${local.prefix}-peering-alert"
  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  description         = "Avvisa quando il peering di rete con produzione non è disponibile"
  enabled             = true
  
  scopes = [
    module.azure_core.resource_group_id
  ]
  
  criteria {
    resource_id    = azurerm_virtual_network_peering.dr_to_prod.id
    operation_name = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write"
    category       = "Administrative"
    level          = "Critical"
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.dr_alerts.id
  }
  
  tags = local.common_tags
}