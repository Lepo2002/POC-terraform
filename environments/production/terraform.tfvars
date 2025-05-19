project_name = "saas-multicloud"

azure_region             = "westeurope"
azure_dr_region          = "northeurope"
azure_platform_admin_id  = "00000000-0000-0000-0000-000000000000"

gcp_project_id           = "prod-saas-multicloud-12345"
gcp_region               = "europe-west1"
gcp_dr_region            = "europe-west4"
gcp_organization_id      = "123456789012"
gcp_billing_account      = "ABCDEF-GHIJKL-MNOPQR"

database_admin_username  = "saas_prod_admin"
database_admin_password  = "REPLACE_WITH_SECURE_PASSWORD"

vpn_shared_secret        = "REPLACE_WITH_SECURE_SECRET"

alert_email              = "alerts@saas-multicloud.com"
slack_channel            = "prod-alerts"
slack_token              = "xoxb-your-slack-token"

enable_full_ha           = true
enable_disaster_recovery = true
bastion_admin_cidr       = "10.100.0.0/24"