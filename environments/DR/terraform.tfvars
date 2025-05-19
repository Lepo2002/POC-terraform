project_name = "saas-multicloud"

azure_region             = "northeurope"
azure_platform_admin_id  = "00000000-0000-0000-0000-000000000000"

gcp_project_id           = "dr-saas-multicloud-12345"
gcp_region               = "europe-west4"
gcp_organization_id      = "123456789012"
gcp_billing_account      = "ABCDEF-GHIJKL-MNOPQR"

database_admin_username  = "saas_dr_admin"
database_admin_password  = "REPLACE_WITH_SECURE_PASSWORD"

vpn_shared_secret        = "REPLACE_WITH_SECURE_SECRET"

alert_email              = "alerts@saas-multicloud.com"
slack_channel            = "dr-alerts"
slack_token              = "xoxb-your-slack-token"

prod_gcp_project_id      = "prod-saas-multicloud-12345"
prod_azure_resource_group = "prod-saas-multicloud-rg"
prod_azure_region        = "westeurope"
prod_gcp_region          = "europe-west1"

bastion_admin_cidr       = "10.100.0.0/24"