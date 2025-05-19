resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-logs"
  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  sku                 = "PerGB2018"
  retention_in_days   = 90
  
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

resource "azurerm_monitor_action_group" "critical" {
  name                = "${local.prefix}-critical-alerts"
  resource_group_name = module.azure_core.resource_group_name
  short_name          = "Critical"
  
  email_receiver {
    name          = "OperationsTeam"
    email_address = var.alert_email
  }
  
  webhook_receiver {
    name        = "SlackNotification"
    service_uri = "https://hooks.slack.com/services/${var.slack_token}"
  }
  
  sms_receiver {
    name         = "OpsManager"
    country_code = "39"
    phone_number = "REPLACE_WITH_PHONE_NUMBER"
  }
}

resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${local.prefix}-high-cpu-alert"
  resource_group_name = module.azure_core.resource_group_name
  scopes              = [module.azure_kubernetes.cluster_id]
  description         = "Azione attivata quando l'utilizzo CPU del cluster supera il 85%"
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
    action_group_id = azurerm_monitor_action_group.critical.id
  }
  
  tags = local.common_tags
}

resource "google_monitoring_notification_channel" "email" {
  project      = module.gcp_project.project_id
  display_name = "Operations Team"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_notification_channel" "slack" {
  project      = module.gcp_project.project_id
  display_name = "Slack Notifications"
  type         = "slack"
  
  labels = {
    channel_name = var.slack_channel
    auth_token   = var.slack_token
  }
  
  sensitive_labels {
    auth_token = var.slack_token
  }
}

resource "google_monitoring_alert_policy" "high_cpu" {
  project      = module.gcp_project.project_id
  display_name = "GKE Cluster High CPU Utilization"
  combiner     = "OR"
  
  conditions {
    display_name = "GKE Cluster CPU Utilization > 80%"
    
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/cpu/limit_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.namespace_name"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.slack.id
  ]
  
  documentation {
    content   = "Il cluster GKE ha un utilizzo CPU superiore all'80% per 5 minuti. Valutare lo scaling automatico."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "high_memory" {
  project      = module.gcp_project.project_id
  display_name = "GKE Cluster High Memory Utilization"
  combiner     = "OR"
  
  conditions {
    display_name = "GKE Cluster Memory Utilization > 80%"
    
    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/memory/limit_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields      = ["resource.label.namespace_name"]
      }
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.slack.id
  ]
  
  documentation {
    content   = "Il cluster GKE ha un utilizzo della memoria superiore all'80% per 5 minuti. Valutare lo scaling automatico."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_dashboard" "gke_dashboard" {
  project        = module.gcp_project.project_id
  dashboard_json = <<EOF
{
  "displayName": "GKE Cluster Overview",
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "CPU Utilization",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/cpu/limit_utilization\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_MEAN",
                    "groupByFields": ["resource.label.namespace_name"]
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Memory Utilization",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/memory/limit_utilization\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN",
                    "crossSeriesReducer": "REDUCE_MEAN",
                    "groupByFields": ["resource.label.namespace_name"]
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Network Traffic",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/network/received_bytes_count\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_SUM",
                    "groupByFields": []
                  }
                }
              }
            }
          ]
        }
      },
      {
        "title": "Pod Count",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${module.gcp_kubernetes.cluster_name}\" AND metric.type = \"kubernetes.io/container/uptime\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_COUNT",
                    "groupByFields": []
                  }
                }
              }
            }
          ]
        }
      }
    ]
  }
}
EOF
}

resource "google_monitoring_alert_policy" "database_cpu" {
  project      = module.gcp_project.project_id
  display_name = "Cloud SQL High CPU Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Cloud SQL CPU Utilization > 75%"
    
    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${module.gcp_database.instance_id}\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.75
      
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
    content   = "Il database Cloud SQL ha un utilizzo CPU superiore al 75% per 5 minuti. Valutare il dimensionamento."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "database_disk" {
  project      = module.gcp_project.project_id
  display_name = "Cloud SQL High Disk Utilization"
  combiner     = "OR"
  
  conditions {
    display_name = "Cloud SQL Disk Utilization > 85%"
    
    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${module.gcp_database.instance_id}\" AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      
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
    content   = "Il database Cloud SQL ha un utilizzo dello spazio su disco superiore all'85%. Valutare un aumento dello spazio su disco."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_uptime_check_config" "api_uptime" {
  project     = module.gcp_project.project_id
  display_name = "API Endpoint Health Check"
  timeout      = "10s"
  period       = "60s"
  
  http_check {
    path         = "/api/health"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      host = module.gcp_loadbalancer.load_balancer_ip
    }
  }
  
  content_matchers {
    content = "OK"
    matcher = "CONTAINS_STRING"
  }
}

resource "azurerm_monitor_activity_log_alert" "gcp_cluster_health" {
  name                = "${local.prefix}-gke-health-alert"
  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  description         = "Avvisa quando il cluster GKE non è disponibile"
  enabled             = true
  
  scopes = [
    module.azure_core.resource_group_id
  ]
  
  criteria {
    resource_id    = module.azure_kubernetes.cluster_id
    operation_name = "Microsoft.ContainerService/managedClusters/write"
    category       = "Administrative"
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
  
  tags = local.common_tags
}