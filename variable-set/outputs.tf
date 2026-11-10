output "id" {
  description = "The ID of the variable set"
  value       = tfe_variable_set.this.id
}

output "name" {
  description = "The name of the variable set"
  value       = tfe_variable_set.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_variable_set.this.organization
}

output "description" {
  description = "The variable set description"
  value       = tfe_variable_set.this.description
}

output "global" {
  description = "Whether the variable set is global"
  value       = tfe_variable_set.this.global
}

output "priority" {
  description = "Whether the variable set has priority"
  value       = tfe_variable_set.this.priority
}
