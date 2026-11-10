output "id" {
  description = "The ID of the SSH key"
  value       = tfe_ssh_key.this.id
}

output "name" {
  description = "The name of the SSH key"
  value       = tfe_ssh_key.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_ssh_key.this.organization
}
