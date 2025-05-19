locals {
  environment = "dr"
  
  prefix = "dr"
  
  common_tags = {
    environment     = "disaster_recovery"
    managed_by      = "terraform"
    project         = var.project_name
    data_class      = "business_critical"
    compliance      = "iso27001"
    business_unit   = "platform"
    cost_center     = "platform-dr"
    owner           = "platform-team"
    purpose         = "disaster_recovery"
  }
  
  network_config = {
    azure = {
      vnet_cidr        = "10.1.0.0/16"
      app_subnet_cidr  = "10.1.1.0/24"
      data_subnet_cidr = "10.1.2.0/24"
      k8s_subnet_cidr  = "10.1.3.0/24"
      bastion_cidr     = "10.1.4.0/24"
    }
    gcp = {
      vpc_cidr           = "10.20.0.0/20"
      app_subnet_cidr    = "10.20.0.0/22"
      data_subnet_cidr   = "10.20.4.0/22"
      k8s_subnet_cidr    = "10.20.8.0/22"
      pod_range_cidr     = "10.110.0.0/16"
      service_range_cidr = "10.111.0.0/16"
    }
  }
  
  database_tiers = {
    azure = "S1"
    gcp   = "db-custom-2-7680"
  }
  
  kubernetes_config = {
    azure = {
      version       = "1.27"
      node_size     = "Standard_D2s_v3"
      node_count    = 2
    }
    gcp = {
      version       = "1.27"
      node_type     = "e2-standard-2"
      node_count    = 2
    }
  }

  resource_names = {
    resource_group     = "${local.prefix}-${var.project_name}-rg"
    vnet               = "${local.prefix}-${var.project_name}-vnet"
    vpc                = "${local.prefix}-${var.project_name}-vpc"
    k8s_azure          = "${local.prefix}-${var.project_name}-aks"
    k8s_gcp            = "${local.prefix}-${var.project_name}-gke"
    sql_azure          = "${local.prefix}-${var.project_name}-sqlserver"
    sql_gcp            = "${local.prefix}-${var.project_name}-db"
    sql_database       = "${local.prefix}-main-database"
    cognitive_account  = "${local.prefix}-${var.project_name}-ai"
  }

  prod_resource_names = {
    resource_group     = "prod-${var.project_name}-rg"
    vnet               = "prod-${var.project_name}-vnet"
    vpc                = "prod-${var.project_name}-vpc"
    k8s_azure          = "prod-${var.project_name}-aks"
    k8s_gcp            = "prod-${var.project_name}-gke"
    sql_azure          = "prod-${var.project_name}-sqlserver"
    sql_gcp            = "prod-${var.project_name}-db"
    sql_database       = "prod-main-database"
  }
}