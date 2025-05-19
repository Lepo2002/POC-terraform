module "azure_core" {
  source = "../../modules/azure_core/v1"

  resource_group_name = local.resource_names.resource_group
  location            = var.azure_region
  environment         = local.environment
  enable_resource_lock = true
  lock_level          = "CanNotDelete"

  additional_tags = local.common_tags

  role_assignments = {
    "platform_admin" = {
      role         = "Contributor"
      principal_id = var.azure_platform_admin_id
    }
  }
}

module "azure_networking" {
  source = "../../modules/azure_networking/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  vnet_name       = local.resource_names.vnet
  address_space   = [local.network_config.azure.vnet_cidr]

  subnets = [
    {
      name             = "${local.prefix}-app-subnet"
      address_prefix   = local.network_config.azure.app_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-data-subnet"
      address_prefix   = local.network_config.azure.data_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-k8s-subnet"
      address_prefix   = local.network_config.azure.k8s_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.ContainerRegistry"]
    },
    {
      name             = "${local.prefix}-bastion-subnet"
      address_prefix   = local.network_config.azure.bastion_cidr
      service_endpoints = []
    }
  ]

  bastion_host = {
    name           = "${local.prefix}-bastion"
    subnet_name    = "${local.prefix}-bastion-subnet"
    public_ip_name = "${local.prefix}-bastion-pip"
  }

  firewall = {
    name           = "${local.prefix}-firewall"
    sku_name       = "Premium"
    sku_tier       = "Premium"
    subnet_name    = "AzureFirewallSubnet"
    public_ip_name = "${local.prefix}-firewall-pip"
  }

  ddos_protection_plan = {
    name = "${local.prefix}-ddos-plan"
  }

  tags = local.common_tags
}

resource "azurerm_virtual_network_peering" "dr_to_prod" {
  name                      = "dr-to-prod-peer"
  resource_group_name       = module.azure_core.resource_group_name
  virtual_network_name      = module.azure_networking.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.prod_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

module "azure_database" {
  source = "../../modules/azure_database/v1"

  resource_group_name  = module.azure_core.resource_group_name
  location             = var.azure_region
  environment          = local.environment

  instance_name       = local.resource_names.sql_azure
  database_name       = local.resource_names.sql_database
  database_username   = var.database_admin_username
  database_password   = var.database_admin_password

  private_network     = true
  private_subnet_id   = module.azure_networking.subnet_ids["${local.prefix}-data-subnet"]

  database_tier       = local.database_tiers.azure
  backup_enabled      = true
}

module "azure_kubernetes" {
  source = "../../modules/azure_kubernetes/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  cluster_name       = local.resource_names.k8s_azure
  kubernetes_version = local.kubernetes_config.azure.version
  node_count         = local.kubernetes_config.azure.node_count
  node_vm_size       = local.kubernetes_config.azure.node_size

  network_plugin     = "azure"
  network_policy     = "calico"
  vnet_subnet_id     = module.azure_networking.subnet_ids["${local.prefix}-k8s-subnet"]

  enable_auto_scaling = true
  min_node_count      = 2
  max_node_count      = 5
  
  tags = local.common_tags
}

module "azure_ai" {
  source = "../../modules/azure_ai/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  account_name        = local.resource_names.cognitive_account
  account_kind        = "Cognitive"
  sku_name            = "S0"

  model_deployments = {
    "gpt-model" = {
      model_format   = "OpenAI"
      model_name     = "gpt-4"
      model_version  = "0613"
      scale_type     = "Standard"
      scale_capacity = 5 
    }
  }
  
  network_default_action = "Deny"
  network_ip_rules       = [var.bastion_admin_cidr]
  
  additional_tags = local.common_tags
}

module "gcp_project" {
  source = "../../modules/gcp_project/v1"

  project_name        = "${local.prefix}-${var.project_name}"
  project_id          = var.gcp_project_id
  organization_id     = var.gcp_organization_id
  billing_account     = var.gcp_billing_account
  folder_name         = "${local.prefix}-INFRA"
  environment         = local.environment
  enable_lien         = true
  
  project_metadata = {
    environment = local.environment
    owner       = var.alert_email
  }
}

module "gcp_networking" {
  source = "../../modules/gcp_networking/v1"

  project_id         = module.gcp_project.project_id
  vpc_name           = local.resource_names.vpc
  region             = var.gcp_region
  create_nat_gateway = true
  create_private_service_access = true

  subnets = [
    {
      name   = "${local.prefix}-app-subnet"
      region = var.gcp_region
      cidr   = local.network_config.gcp.app_subnet_cidr
      secondary_ranges = []
    },
    {
      name   = "${local.prefix}-data-subnet"
      region = var.gcp_region
      cidr   = local.network_config.gcp.data_subnet_cidr
      secondary_ranges = []
    },
    {
      name   = "${local.prefix}-k8s-subnet"
      region = var.gcp_region
      cidr   = local.network_config.gcp.k8s_subnet_cidr
      secondary_ranges = [
        { name = "pod-range", cidr = local.network_config.gcp.pod_range_cidr },
        { name = "svc-range", cidr = local.network_config.gcp.service_range_cidr }
      ]
    }
  ]
}

resource "google_compute_network_peering" "dr_to_prod" {
  name         = "dr-to-prod-peering"
  network      = module.gcp_networking.vpc_self_link
  peer_network = data.google_compute_network.prod_vpc.self_link
  
  import_custom_routes = true
  export_custom_routes = true
  
  depends_on = [
    module.gcp_networking
  ]
}

module "gcp_iam" {
  source = "../../modules/gcp_iam/v1"

  project_id = module.gcp_project.project_id
  environment = local.environment
  service_account_name = "${local.prefix}-service-account"
  
  service_account_roles = [
    "roles/compute.admin",
    "roles/container.admin",
    "roles/storage.admin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudsql.admin"
  ]
  
  enable_audit_logging = true
  audit_services = {
    "allServices" = {
      "DATA_READ"  = []
      "DATA_WRITE" = []
      "ADMIN_READ" = []
    }
  }
  
  custom_role_definitions = {
    "customReadOnly" = {
      title       = "Custom Read Only Role"
      description = "Ruolo personalizzato con accesso in sola lettura"
      permissions = [
        "compute.instances.get",
        "compute.instances.list",
        "container.clusters.get",
        "container.clusters.list"
      ]
      stage = "GA"
    }
  }
}

module "gcp_database" {
  source = "../../modules/gcp_database/v1"

  project_id      = module.gcp_project.project_id
  environment     = local.environment
  region          = var.gcp_region

  instance_name   = local.resource_names.sql_gcp
  database_name   = local.resource_names.sql_database
  database_version = "POSTGRES_13"
  database_tier   = local.database_tiers.gcp

  availability_type = "ZONAL" 
  backup_enabled    = true
  backup_start_time = "02:00"
  backup_location   = "eu"

  network_id        = module.gcp_networking.vpc_id
  private_network   = true

  database_username = var.database_admin_username
  database_password = var.database_admin_password
  
  maintenance_day   = 2  
  maintenance_hour  = 2  
  
  enable_deletion_protection = true
  
  max_connections = "300"
  
  additional_database_flags = {
    "log_statement" = "all"
    "log_min_duration_statement" = "1000"
  }
}

module "gcp_kubernetes" {
  source = "../../modules/gcp_kubernetes/v1"

  project_id          = module.gcp_project.project_id
  cluster_name        = local.resource_names.k8s_gcp
  region              = var.gcp_region
  zone                = "${var.gcp_region}-b"
  environment         = local.environment
  regional_cluster    = false  

  kubernetes_version  = local.kubernetes_config.gcp.version
  node_count          = local.kubernetes_config.gcp.node_count
  node_machine_type   = local.kubernetes_config.gcp.node_type

  network_id          = module.gcp_networking.vpc_id
  subnetwork_id       = module.gcp_networking.subnet_ids["${local.prefix}-k8s-subnet"]
  cluster_secondary_range_name = "pod-range"
  services_secondary_range_name = "svc-range"

  private_cluster     = true
  private_endpoint    = true
  master_ipv4_cidr_block = "172.16.1.0/28" 

  service_account_email = module.gcp_iam.service_account_email
}

data "azurerm_resource_group" "prod_rg" {
  name = var.prod_azure_resource_group
}

data "azurerm_virtual_network" "prod_vnet" {
  name                = local.prod_resource_names.vnet
  resource_group_name = data.azurerm_resource_group.prod_rg.name
}

data "google_compute_network" "prod_vpc" {
  name    = local.prod_resource_names.vpc
  project = var.prod_gcp_project_id
}

resource "azurerm_mssql_database" "geo_replica" {
  name                        = "${local.resource_names.sql_database}-replica"
  server_id                   = module.azure_database.instance_id
  create_mode                 = "Secondary"
  creation_source_database_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.prod_azure_resource_group}/providers/Microsoft.Sql/servers/${local.prod_resource_names.sql_azure}/databases/${local.prod_resource_names.sql_database}"
}

data "azurerm_subscription" "current" {}

resource "google_sql_database_instance" "replica" {
  name                = "${local.resource_names.sql_gcp}-replica"
  project             = module.gcp_project.project_id
  database_version    = "POSTGRES_13"
  region              = var.gcp_region
  
  master_instance_name = "${var.prod_gcp_project_id}:${var.prod_gcp_region}:${local.prod_resource_names.sql_gcp}"
  
  replica_configuration {
    failover_target = false
  }
  
  settings {
    tier              = local.database_tiers.gcp
    availability_type = "ZONAL"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.gcp_networking.vpc_id
    }
    
    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
    
    user_labels = {
      environment = local.environment
    }
  }
  
  deletion_protection = true
}

resource "random_id" "storage_suffix" {
  byte_length = 4
}

module "azure_storage" {
  source = "../../modules/azure_storage/v1"
  
  environment = local.environment
  resource_group_name = module.azure_core.resource_group_name
  location = var.azure_region
  storage_account_name = "${local.prefix}storacc${random_id.storage_suffix.hex}"
  
  account_tier = "Standard"
  replication_type = "LRS"
  access_tier = "Hot"
  
  enable_https_traffic_only = true
  min_tls_version = "TLS1_2"
  allow_public_access = false
  enable_blob_versioning = true
  enable_change_feed = true
  blob_soft_delete_retention_days = 14
  container_soft_delete_retention_days = 14
  network_default_action = "Deny"
  
  subnet_ids = [
    module.azure_networking.subnet_ids["${local.prefix}-app-subnet"],
    module.azure_networking.subnet_ids["${local.prefix}-data-subnet"]
  ]
  
  containers = [
    {
      name = "data"
      access_type = "private"
    },
    {
      name = "backup"
      access_type = "private"
    },
    {
      name = "logs"
      access_type = "private"
    }
  ]
  
  enable_private_endpoint = true
  private_endpoint_subnet_id = module.azure_networking.subnet_ids["${local.prefix}-data-subnet"]
  private_endpoint_subresources = ["blob"]
  
  enable_advanced_threat_protection = true
  
  blob_data_contributors = [module.azure_kubernetes.kubelet_identity_object_id]
  
  tags = local.common_tags
}

module "gcp_loadbalancer" {
  source = "../../modules/gcp_loadbalancer/v1"

  project_id      = module.gcp_project.project_id
  environment     = local.environment
  instance_group_1 = module.gcp_kubernetes.cluster_node_pool_id
  
  region           = var.gcp_region
  domain_name      = "dr.${var.project_name}.com"
  enable_https     = true
  enable_cdn       = false  
  
  health_check_path = "/health"
  health_check_port = 80
}