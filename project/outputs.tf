output "id" {
  description = "The ID of the project"
  value       = tfe_project.this.id
}

output "name" {
  description = "The name of the project"
  value       = tfe_project.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_project.this.organization
}

output "description" {
  description = "The project description"
  value       = tfe_project.this.description
}
