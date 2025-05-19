module "azure_core" {
  source = "../../modules/azure/core/v1"

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
  source = "../../azure/modules/networking/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  vnet_name       = local.resource_names.vnet
  address_space   = [local.network_config.azure.primary.vnet_cidr]

  subnets = [
    {
      name             = "${local.prefix}-app-subnet"
      address_prefix   = local.network_config.azure.primary.app_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-data-subnet"
      address_prefix   = local.network_config.azure.primary.data_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-k8s-subnet"
      address_prefix   = local.network_config.azure.primary.k8s_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.ContainerRegistry"]
    },
    {
      name             = "${local.prefix}-bastion-subnet"
      address_prefix   = local.network_config.azure.primary.bastion_cidr
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

module "azure_networking_dr" {
  count  = var.enable_disaster_recovery ? 1 : 0
  source = "../../azure/modules/networking/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_dr_region
  environment         = "${local.environment}-dr"

  vnet_name      = local.resource_names.dr_vnet
  address_space  = [local.network_config.azure.dr.vnet_cidr]

  subnets = [
    {
      name             = "${local.prefix}-dr-app-subnet"
      address_prefix   = local.network_config.azure.dr.app_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-dr-data-subnet"
      address_prefix   = local.network_config.azure.dr.data_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-dr-k8s-subnet"
      address_prefix   = local.network_config.azure.dr.k8s_subnet_cidr
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.ContainerRegistry"]
    }
  ]

  vnet_peerings = [{
    name                         = "peer-to-primary"
    remote_vnet_id               = module.azure_networking.vnet_id
    allow_virtual_network_access = true
    allow_forwarded_traffic      = true
    allow_gateway_transit        = false
    use_remote_gateways          = true
  }]

  tags = merge(local.common_tags, {
    purpose = "disaster_recovery"
  })
}

module "azure_database" {
  source = "../../modules/azure/database/v1"

  resource_group_name  = module.azure_core.resource_group_name
  location             = var.azure_region
  environment          = local.environment

  instance_name       = local.resource_names.sql_azure
  database_name       = local.resource_names.sql_database
  database_username   = var.database_admin_username
  database_password   = var.database_admin_password

  private_network     = true
  private_subnet_id   = module.azure_networking.subnet_ids["${local.prefix}-data-subnet"]

  database_tier       = local.database_tiers.azure.prod
  backup_enabled      = true
}

module "azure_database_dr" {
  count  = var.enable_disaster_recovery ? 1 : 0
  source = "../../modules/azure/database/v1"

  resource_group_name  = module.azure_core.resource_group_name
  location             = var.azure_dr_region
  environment          = "${local.environment}-dr"

  instance_name       = "${local.resource_names.sql_azure}-dr"
  database_name       = "${local.resource_names.sql_database}-dr"
  database_username   = var.database_admin_username
  database_password   = var.database_admin_password

  private_network     = true
  private_subnet_id   = module.azure_networking_dr[0].subnet_ids["${local.prefix}-dr-data-subnet"]

  database_tier       = local.database_tiers.azure.dr
  backup_enabled      = true
}

module "azure_kubernetes" {
  source = "../../modules/azure/containers/aks/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  cluster_name       = local.resource_names.k8s_azure
  kubernetes_version = local.kubernetes_config.azure.version
  node_count         = local.kubernetes_config.azure.prod_node_count
  node_vm_size       = local.kubernetes_config.azure.prod_node_size

  network_plugin     = "azure"
  network_policy     = "calico"
  vnet_subnet_id     = module.azure_networking.subnet_ids["${local.prefix}-k8s-subnet"]

  enable_auto_scaling = true
  min_node_count      = 3
  max_node_count      = 10

  tags = local.common_tags
}

module "azure_kubernetes_dr" {
  count  = var.enable_disaster_recovery ? 1 : 0
  source = "../../modules/azure/containers/aks/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_dr_region
  environment         = "${local.environment}-dr"

  cluster_name       = local.resource_names.dr_k8s_azure
  kubernetes_version = local.kubernetes_config.azure.version
  node_count         = local.kubernetes_config.azure.dr_node_count
  node_vm_size       = local.kubernetes_config.azure.dr_node_size

  network_plugin     = "azure"
  network_policy     = "calico"
  vnet_subnet_id     = module.azure_networking_dr[0].subnet_ids["${local.prefix}-dr-k8s-subnet"]

  enable_auto_scaling = true
  min_node_count      = 2
  max_node_count      = 5

  tags = merge(local.common_tags, {
    purpose = "disaster_recovery"
  })
}

module "azure_ai" {
  source = "../../modules/azure/ai/v1"

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
      scale_capacity = 10
    }
  }

  network_default_action = "Deny"
  network_ip_rules       = [var.bastion_admin_cidr]

  enable_customer_managed_key = true

  additional_tags = local.common_tags
}

module "gcp_project" {
  source = "../../modules/gcp/core/project/v1"

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
  source = "../../modules/gcp/networking/v1"

  project_id         = module.gcp_project.project_id
  vpc_name           = local.resource_names.vpc
  region             = var.gcp_region
  create_nat_gateway = true
  create_private_service_access = true

  subnets = [
    {
      name   = "${local.prefix}-app-subnet"
      region = var.gcp_region
      cidr   = local.network_config.gcp.primary.app_subnet_cidr
      secondary_ranges = []
    },
    {
      name   = "${local.prefix}-data-subnet"
      region = var.gcp_region
      cidr   = local.network_config.gcp.primary.data_subnet_cidr
      secondary_ranges = []
    },
    {
      name   = "${local.prefix}-k8s-subnet"
      region = var.gcp_region
      cidr   = local.network_config.gcp.primary.k8s_subnet_cidr
      secondary_ranges = [
        { name = "pod-range", cidr = local.network_config.gcp.primary.pod_range_cidr },
        { name = "svc-range", cidr = local.network_config.gcp.primary.service_range_cidr }
      ]
    }
  ]
}

module "gcp_networking_dr" {
  count  = var.enable_disaster_recovery ? 1 : 0
  source = "../../modules/gcp/networking/v1"

  project_id         = module.gcp_project.project_id
  vpc_name           = local.resource_names.dr_vpc
  region             = var.gcp_dr_region
  create_nat_gateway = true
  create_private_service_access = true

  subnets = [
    {
      name   = "${local.prefix}-dr-app-subnet"
      region = var.gcp_dr_region
      cidr   = local.network_config.gcp.dr.app_subnet_cidr
      secondary_ranges = []
    },
    {
      name   = "${local.prefix}-dr-data-subnet"
      region = var.gcp_dr_region
      cidr   = local.network_config.gcp.dr.data_subnet_cidr
      secondary_ranges = []
    },
    {
      name   = "${local.prefix}-dr-k8s-subnet"
      region = var.gcp_dr_region
      cidr   = local.network_config.gcp.dr.k8s_subnet_cidr
      secondary_ranges = [
        { name = "pod-range", cidr = local.network_config.gcp.dr.pod_range_cidr },
        { name = "svc-range", cidr = local.network_config.gcp.dr.service_range_cidr }
      ]
    }
  ]
}

module "gcp_iam" {
  source = "../../modules/gcp/iam/v1"

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
  source = "../../modules/gcp/database/v1"

  project_id      = module.gcp_project.project_id
  environment     = local.environment
  region          = var.gcp_region

  instance_name   = local.resource_names.sql_gcp
  database_name   = local.resource_names.sql_database
  database_version = "POSTGRES_13"
  database_tier   = local.database_tiers.gcp.prod

  availability_type = "REGIONAL"
  backup_enabled    = true
  backup_start_time = "02:00"
  backup_location   = "eu"

  network_id        = module.gcp_networking.vpc_id
  private_network   = true

  database_username = var.database_admin_username
  database_password = var.database_admin_password

  maintenance_day   = 1 
  maintenance_hour  = 2  

  enable_deletion_protection = true
  prevent_destroy = true

  max_connections = "300"

  additional_database_flags = {
    "log_statement" = "all"
    "log_min_duration_statement" = "1000"
  }
}

module "gcp_database_dr" {
  count  = var.enable_disaster_recovery ? 1 : 0
  source = "../../modules/gcp/database/v1"

  project_id      = module.gcp_project.project_id
  environment     = "${local.environment}-dr"
  region          = var.gcp_dr_region

  instance_name   = "${local.resource_names.sql_gcp}-dr"
  database_name   = "${local.resource_names.sql_database}-dr"
  database_version = "POSTGRES_13"
  database_tier   = local.database_tiers.gcp.dr

  availability_type = "ZONAL"
  backup_enabled    = true
  backup_start_time = "03:00"
  backup_location   = "eu"

  network_id        = module.gcp_networking_dr[0].vpc_id
  private_network   = true

  database_username = var.database_admin_username
  database_password = var.database_admin_password
}

module "gcp_kubernetes" {
  source = "../../modules/gcp/containers/gke/v1"

  project_id          = module.gcp_project.project_id
  cluster_name        = local.resource_names.k8s_gcp
  region              = var.gcp_region
  zone                = "${var.gcp_region}-b"
  environment         = local.environment
  regional_cluster    = true

  kubernetes_version  = local.kubernetes_config.gcp.version
  node_count          = local.kubernetes_config.gcp.prod_node_count
  node_machine_type   = local.kubernetes_config.gcp.prod_node_type

  network_id          = module.gcp_networking.vpc_id
  subnetwork_id       = module.gcp_networking.subnet_ids["${local.prefix}-k8s-subnet"]
  cluster_secondary_range_name = "pod-range"
  services_secondary_range_name = "svc-range"

  private_cluster     = true
  private_endpoint    = true
  master_ipv4_cidr_block = "172.16.0.0/28"

  service_account_email = module.gcp_iam.service_account_email

  enable_dr           = var.enable_disaster_recovery
  dr_location         = var.enable_disaster_recovery ? var.gcp_dr_region : ""
  dr_node_count       = var.enable_disaster_recovery ? local.kubernetes_config.gcp.dr_node_count : 0
}

module "multi_cloud_interconnect" {
  source = "../../modules/multi_cloud/interconnect/v1"

  environment        = local.environment
  gcp_project_id     = module.gcp_project.project_id
  gcp_region         = var.gcp_region
  gcp_network_id     = module.gcp_networking.vpc_id
  gcp_router_id      = module.gcp_networking.router_id

  azure_resource_group_name = module.azure_core.resource_group_name
  azure_location            = var.azure_region

  create_azure_express_route = true

  express_route_name = "${local.prefix}-expressroute"
  interconnect_name  = "${local.prefix}-interconnect"

  create_gcp_vpn_backup  = true
  create_azure_vpn_backup = true
  vpn_shared_secret      = var.vpn_shared_secret
}

module "gcp_security" {
  source = "../../modules/gcp/security/v1"

  project_id = module.gcp_project.project_id
  environment = local.environment
  region     = var.gcp_region

  enable_kms = true
  crypto_keys = {
    "application-key" = {
      rotation_period  = "7776000s" 
      algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
      protection_level = "SOFTWARE"
    }
  }

  enable_cloud_armor = true
  enable_ddos_protection = true

  cloud_armor_rules = [
    {
      action      = "deny(403)"
      priority    = 1000
      expression  = "evaluatePreconfiguredExpr('xss-stable')"
      description = "Previene attacchi XSS"
    },
    {
      action      = "deny(403)"
      priority    = 1100
      expression  = "evaluatePreconfiguredExpr('sqli-stable')"
      description = "Previene attacchi SQL Injection"
    },
    {
      action      = "deny(403)"
      priority    = 1200
      expression  = "origin.region_code == 'RU' || origin.region_code == 'CN'"
      description = "Geo-filtering per regioni ad alto rischio"
    }
  ]

  enable_ssl_policy = true
  ssl_policy_profile = "RESTRICTED"
  ssl_min_tls_version = "TLS_1_2"

  enable_binary_authorization = true
  binary_auth_policy_mode = "GLOBAL"
  binary_auth_default_rule = "REQUIRE_ATTESTATION"
  binary_auth_enforce = true
  binary_auth_whitelist_images = [
    "gcr.io/${module.gcp_project.project_id}/*",
    "europe-west1-docker.pkg.dev/${module.gcp_project.project_id}/*"
  ]

  secrets = {
    "api-key" = {
      data = "REPLACE_WITH_SECURE_API_KEY"
      auto_replication = true
    },
    "encryption-key" = {
      data = "REPLACE_WITH_SECURE_ENCRYPTION_KEY"
      auto_replication = true
    }
  }

  secret_access_bindings = {
    "api-key-binding" = {
      secret_id = "api-key"
      role      = "roles/secretmanager.secretAccessor"
      members   = ["serviceAccount:${module.gcp_iam.service_account_email}"]
    }
  }
}

module "gcp_loadbalancer" {
  source = "../../modules/gcp/network/loadbalancer/v1"

  project_id      = module.gcp_project.project_id
  environment     = local.environment
  instance_group_1 = module.gcp_kubernetes.cluster_node_pool_id

  region           = var.gcp_region
  domain_name      = "app.${var.project_name}.com"
  enable_https     = true
  enable_cdn       = true

  security_policy  = module.gcp_security.cloud_armor_policy_id

  enable_session_affinity = true

  health_check_path = "/health"
  health_check_port = 80
}

module "gcp_monitoring" {
  source = "../../modules/gcp/monitoring/v1"

  project_id = module.gcp_project.project_id
  network_id = module.gcp_networking.vpc_id
  environment = local.environment

  common_rules = {
    "allow-health-checks" = {
      direction     = "INGRESS"
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
      target_tags  = ["http-server", "https-server"]
      description  = "Consente il traffico dagli health check"
    },
    "allow-internal-secure" = {
      direction     = "INGRESS"
      source_ranges = [local.network_config.gcp.primary.vpc_cidr]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "3306", "5432", "6379"]
        }
      ]
      target_tags  = ["internal"]
      description  = "Traffico interno per porte sicure"
    }
  }

  environment_rules = {
    production = {
      "prod-allow-internal" = {
        direction     = "INGRESS"
        source_ranges = [local.network_config.gcp.primary.vpc_cidr]
        allow = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          },
          {
            protocol = "icmp"
            ports    = []
          }
        ]
        target_tags  = ["internal"]
        description  = "Consente tutto il traffico interno tra risorse di produzione"
      },
      "prod-restrict-external" = {
        direction     = "INGRESS"
        source_ranges = ["0.0.0.0/0"]
        allow = [
          {
            protocol = "tcp"
            ports    = ["80", "443"]
          }
        ]
        target_tags  = ["http-server", "https-server"]
        description  = "Restringe traffico esterno a sole porte HTTP(S)"
      }
    }
  }
}

module "multi_cloud_identity_federation" {
  source = "../../modules/multi_cloud/federated_identity/v1"

  environment = local.environment
  gcp_project_id = module.gcp_project.project_id
  gcp_project_number = module.gcp_project.project_number

  create_gcp_identity_pool = true
  identity_pool_name = "${local.prefix}-federated-pool"
  federated_sa_name = "${local.prefix}-federated-sa"

  create_azure_app = true
  azure_tenant_id = "REPLACE_WITH_TENANT_ID"

  gcp_sa_roles = [
    "roles/storage.objectAdmin",
    "roles/pubsub.publisher"
  ]

  create_azure_managed_identity = true
  azure_resource_group_name = module.azure_core.resource_group_name
  azure_location = var.azure_region
  azure_identity_name = "${local.prefix}-gcp-identity"

  azure_identity_roles = [
    "Reader",
    "Storage Blob Data Reader"
  ]
}

module "azure_storage" {
  source = "../../modules/azure/storage/v1"

  environment = local.environment
  resource_group_name = module.azure_core.resource_group_name
  location = var.azure_region
  storage_account_name = "${local.prefix}storacc${random_id.storage_suffix.hex}"

  account_tier = "Standard"
  replication_type = "ZRS"
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

  lifecycle_rules = [
    {
      name = "archive-old-data"
      prefix_match = ["data/"]
      blob_types = ["blockBlob"]
      base_blob = {
        tier_to_cool_after_days = 30
        tier_to_archive_after_days = 90
        delete_after_days = 365
      }
    }
  ]

  enable_private_endpoint = true
  private_endpoint_subnet_id = module.azure_networking.subnet_ids["${local.prefix}-data-subnet"]
  private_endpoint_subresources = ["blob"]

  enable_advanced_threat_protection = true

  blob_data_contributors = [module.azure_kubernetes.kubelet_identity_object_id]
  blob_data_readers = []

  prevent_destroy = true

  tags = local.common_tags
}

resource "azurerm_recovery_services_vault" "backup_vault" {
  name                = "${local.prefix}-backup-vault"
  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  sku                 = "Standard"
  soft_delete_enabled = true

  tags = local.common_tags
}

resource "random_id" "storage_suffix" {
  byte_length = 4
}