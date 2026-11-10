output "organization" {
  description = "The full organization object"
  value       = tfe_organization.this
}

output "organization_name" {
  description = "The organization name"
  value       = tfe_organization.this.name
}

output "organization_id" {
  description = "The organization ID"
  value       = tfe_organization.this.id
}

# output "default_execution_mode" {
#   description = "The default execution mode for new workspaces"
#   value       = var.default_execution_mode == "agent" ? tfe_organization_default_settings.this_with_agent[0].default_execution_mode : tfe_organization_default_settings.this[0].default_execution_mode
# }

# output "default_agent_pool_id" {
#   description = "The ID of the default agent pool"
#   value       = var.default_execution_mode == "agent" ? tfe_organization_default_settings.this_with_agent[0].default_agent_pool_id : null
# }
