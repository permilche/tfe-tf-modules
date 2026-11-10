output "id" {
  description = "The ID of the registry module"
  value       = tfe_registry_module.this.id
}

output "name" {
  description = "The name of the module"
  value       = tfe_registry_module.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_registry_module.this.organization
}

output "namespace" {
  description = "The namespace of the module"
  value       = tfe_registry_module.this.namespace
}

output "module_provider" {
  description = "The provider of the module"
  value       = tfe_registry_module.this.module_provider
}

output "registry_name" {
  description = "The registry name"
  value       = tfe_registry_module.this.registry_name
}

output "publishing_mechanism" {
  description = "The publishing mechanism for the module"
  value       = tfe_registry_module.this.publishing_mechanism
}

output "no_code_module_id" {
  description = "The ID of the no-code module configuration (if enabled)"
  value       = var.no_code_enabled ? tfe_no_code_module.this[0].id : null
}
