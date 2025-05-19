locals {
  environment = "production"
  
  prefix = "prod"
  
  common_tags = {
    environment     = "production"
    managed_by      = "terraform"
    project         = var.project_name
    data_class      = "business_critical"
    compliance      = "iso27001"
    business_unit   = "platform"
    cost_center     = "platform-prod"
    owner           = "platform-team"
  }
  
  network_config = {
    azure = {
      primary = {
        vnet_cidr        = "10.0.0.0/16"
        app_subnet_cidr  = "10.0.1.0/24"
        data_subnet_cidr = "10.0.2.0/24"
        k8s_subnet_cidr  = "10.0.3.0/24"
        bastion_cidr     = "10.0.4.0/24"
      }
      dr = {
        vnet_cidr        = "10.1.0.0/16"
        app_subnet_cidr  = "10.1.1.0/24"
        data_subnet_cidr = "10.1.2.0/24"
        k8s_subnet_cidr  = "10.1.3.0/24"
        bastion_cidr     = "10.1.4.0/24"
      }
    }
    gcp = {
      primary = {
        vpc_cidr           = "10.10.0.0/20"
        app_subnet_cidr    = "10.10.0.0/22"
        data_subnet_cidr   = "10.10.4.0/22"
        k8s_subnet_cidr    = "10.10.8.0/22"
        pod_range_cidr     = "10.100.0.0/16"
        service_range_cidr = "10.101.0.0/16"
      }
      dr = {
        vpc_cidr           = "10.20.0.0/20"
        app_subnet_cidr    = "10.20.0.0/22"
        data_subnet_cidr   = "10.20.4.0/22"
        k8s_subnet_cidr    = "10.20.8.0/22"
        pod_range_cidr     = "10.110.0.0/16"
        service_range_cidr = "10.111.0.0/16"
      }
    }
  }
  
  database_tiers = {
    azure = {
      prod  = "S3"
      dr    = "S1"
    }
    gcp = {
      prod  = "db-custom-4-15360"
      dr    = "db-custom-2-7680"
    }
  }
  
  kubernetes_config = {
    azure = {
      version        = "1.27"
      prod_node_size = "Standard_D4s_v3"
      dr_node_size   = "Standard_D2s_v3"
      prod_node_count = 3
      dr_node_count   = 2
    }
    gcp = {
      version        = "1.27"
      prod_node_type = "e2-standard-4"
      dr_node_type   = "e2-standard-2"
      prod_node_count = 3
      dr_node_count   = 2
    }
  }
 
  resource_names = {
    resource_group     = "${local.prefix}-${var.project_name}-rg"
    vnet               = "${local.prefix}-${var.project_name}-vnet"
    dr_vnet            = "${local.prefix}-${var.project_name}-dr-vnet"
    vpc                = "${local.prefix}-${var.project_name}-vpc"
    dr_vpc             = "${local.prefix}-${var.project_name}-dr-vpc"
    k8s_azure          = "${local.prefix}-${var.project_name}-aks"
    k8s_gcp            = "${local.prefix}-${var.project_name}-gke"
    dr_k8s_azure       = "${local.prefix}-${var.project_name}-dr-aks"
    dr_k8s_gcp         = "${local.prefix}-${var.project_name}-dr-gke"
    sql_azure          = "${local.prefix}-${var.project_name}-sqlserver"
    sql_gcp            = "${local.prefix}-${var.project_name}-db"
    sql_database       = "${local.prefix}-main-database"
    cognitive_account  = "${local.prefix}-${var.project_name}-ai"
  }
}