output "tfc_application_id" {
  description = "The application (object) ID of the Azure application registration"
  value       = azuread_application_registration.tfc_application.id
}

output "tfc_application_client_id" {
  description = "The client ID of the Azure application registration"
  value       = azuread_application_registration.tfc_application.client_id
}

output "tfc_service_principal_object_id" {
  description = "The object ID of the service principal"
  value       = azuread_service_principal.tfc_service_principal.object_id
}
