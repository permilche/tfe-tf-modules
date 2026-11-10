# Data source used to get information about the current Azure AD tenant.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config
data "azuread_client_config" "current" {}

# Data source used to get the current subscription's ID.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription
data "azurerm_subscription" "current" {}

# Data source to look up the Microsoft Graph service principal in the current tenant.
# Every Azure AD tenant has this SP auto-provisioned. We look it up by its
# well-known, universal application (client) ID, same across all tenants.
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment#example-usage
# but instead of managing Graph with TF from here as shown in the example we will just use a data since we only need the ID
data "azuread_application_published_app_ids" "well_known" {}
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}

# Creates an application registration within Azure Active Directory.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
resource "azuread_application_registration" "tfc_application" {
  display_name = var.app_registration_name
}

resource "azuread_application_api_access" "tfc_graph_access" {
  application_id = azuread_application_registration.tfc_application.id
  api_client_id = data.azuread_service_principal.msgraph.client_id
  
  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
  ]
}

# Creates a service principal associated with the previously created application registration.
#
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal
resource "azuread_service_principal" "tfc_service_principal" {
  client_id = azuread_application_registration.tfc_application.client_id
}

# Creates a role assignment which controls the permissions the service
# principal has within the Azure subscription to deploy resources.
#
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment
locals {
  role_assignments = coalesce(var.role_assignments, {
    contributor = {
      role_definition_name             = "Contributor"
      resource_group                   = null
      skip_service_principal_aad_check = false
    }
  })
}

resource "azurerm_role_assignment" "tfc_role_assignment" {
  for_each = local.role_assignments

  principal_id                     = azuread_service_principal.tfc_service_principal.object_id
  role_definition_name             = each.value.role_definition_name
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check

  scope = each.value.resource_group != null ? "${data.azurerm_subscription.current.id}/resourceGroups/${each.value.resource_group}" : data.azurerm_subscription.current.id
}

resource "azuread_application_owner" "bootstrap_user" {
  count = var.add_bootstrap_user_ownership ? 1 : 0

  application_id = azuread_application_registration.tfc_application.id
  owner_object_id = data.azuread_client_config.current.object_id
}

# Self-ownership: the SP owns its own app registration (to allow creation of Federated Identity credentials afterwards)
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential#api-permissions
resource "azuread_application_owner" "self" {
  application_id = azuread_application_registration.tfc_application.id
  owner_object_id = azuread_service_principal.tfc_service_principal.object_id
}

# we need this app role assignment to be able to create federated identity credentials in the management module, otherwise we get this error:
# Error: Adding federated identity credential for Application (Application: "ad6e2d92-4d38-47a8-b223-8c18a10dc5e1")
# with module.dynamic_credentials_azure_management.azuread_application_federated_identity_credential.this["dev-app-1-backend-apply"]
# on .terraform/modules/dynamic_credentials_azure_management/main.tf line 4, in resource "azuread_application_federated_identity_credential" "this":
# resource "azuread_application_federated_identity_credential" "this" {
# unexpected status 403 (403 Forbidden) with error: Authorization_RequestDenied: Insufficient privileges to complete the operation.
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential#api-permissions
resource "azuread_app_role_assignment" "tfc_graph_permissions" {
  app_role_id = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
  principal_object_id = azuread_service_principal.tfc_service_principal.object_id
  resource_object_id = data.azuread_service_principal.msgraph.object_id
}
