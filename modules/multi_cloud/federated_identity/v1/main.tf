resource "google_iam_workload_identity_pool" "main" {
  count = var.create_gcp_identity_pool ? 1 : 0
  
  project                   = var.gcp_project_id
  workload_identity_pool_id = "${var.environment}-${var.identity_pool_name}"
  display_name              = "Federated Identity Pool for ${var.environment}"
  description               = "Identity pool per l'integrazione multi-cloud con Azure"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "azure_provider" {
  count = var.create_gcp_identity_pool ? 1 : 0
  
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.main[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "azure-${var.environment}"
  display_name                       = "Azure Identity Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.tenant_id"  = "assertion.tid"
    "attribute.object_id"  = "assertion.oid"
  }
  
  oidc {
    issuer_uri        = "https://sts.windows.net/${var.azure_tenant_id}/"
    allowed_audiences = ["api://AzureADTokenExchange"]
  }
}

resource "google_service_account" "federated_sa" {
  count = var.create_gcp_identity_pool ? 1 : 0
  
  project      = var.gcp_project_id
  account_id   = "${var.environment}-${var.federated_sa_name}"
  display_name = "Service Account per identità federata con Azure"
  description  = "Service account che può essere impersonato da Azure"
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  count = var.create_gcp_identity_pool ? 1 : 0
  
  service_account_id = google_service_account.federated_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main[0].name}/attribute.tenant_id/${var.azure_tenant_id}${var.azure_identity_filter}"
  ]
}

resource "google_project_iam_member" "federated_sa_roles" {
  for_each = var.create_gcp_identity_pool ? toset(var.gcp_sa_roles) : []
  
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.federated_sa[0].email}"
}

resource "azuread_application" "gcp_integration" {
  count = var.create_azure_app ? 1 : 0
  
  display_name     = "${var.environment}-gcp-integration"
  identifier_uris  = ["api://GCPIntegration-${var.environment}"]
  sign_in_audience = "AzureADMyOrg"
  
  web {
    redirect_uris = ["https://iam.googleapis.com/projects/${var.gcp_project_number}/locations/global/workloadIdentityPools/${var.environment}-${var.identity_pool_name}/providers/azure-${var.environment}/callback"]
  }
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "gcp_integration" {
  count = var.create_azure_app ? 1 : 0
  
  display_name         = "Secret-${azuread_application.gcp_integration[0].display_name}"
  client_id             = azuread_application.gcp_integration[0].application_id
}

resource "azuread_application_password" "gcp_integration_secret" {
  count = var.create_azure_app ? 1 : 0
  
  application_id = azuread_application.gcp_integration[0].application_id
  display_name   = "GCP Integration Secret"
  end_date       = "2024-12-31T23:59:59Z"
}

resource "azurerm_user_assigned_identity" "azure_identity" {
  count = var.create_azure_managed_identity ? 1 : 0
  
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  name                = "${var.environment}-${var.azure_identity_name}"
}

resource "azurerm_role_assignment" "azure_identity_roles" {
  for_each = var.create_azure_managed_identity ? { for idx, role in var.azure_identity_roles : idx => role } : {}
  
  scope                = var.azure_subscription_id != "" ? "/subscriptions/${var.azure_subscription_id}" : var.azure_role_scope
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.azure_identity[0].principal_id
}