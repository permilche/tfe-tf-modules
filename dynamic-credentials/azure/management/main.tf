# Creates a single federated identity credential for one workspace/run_phase combination
# Callers are responsible for invoking this module with for_each to create multiple credentials

resource "azuread_application_federated_identity_credential" "this" {
  application_id = var.tfc_application_id
  display_name   = var.display_name != null ? var.display_name : "${var.organization}-${var.project}-${var.workspace}-${var.run_phase}"
  description    = "Dynamic credential for ${var.organization}/${var.project}/${var.workspace} during ${var.run_phase}"
  audiences      = [var.tfc_azure_audience]
  issuer         = "https://${var.tfc_hostname}"
  subject        = "organization:${var.organization}:project:${var.project}:workspace:${var.workspace}:run_phase:${var.run_phase}"
}
