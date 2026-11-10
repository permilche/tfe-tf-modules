output "id" {
  description = "ID of the federated identity credential"
  value       = azuread_application_federated_identity_credential.this.id
}

output "display_name" {
  description = "Display name of the federated identity credential"
  value       = azuread_application_federated_identity_credential.this.display_name
}

output "subject" {
  description = "Subject of the federated identity credential"
  value       = azuread_application_federated_identity_credential.this.subject
}
