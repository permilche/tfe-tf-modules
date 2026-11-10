output "id" {
  description = "The ID of the workspace"
  value       = tfe_workspace.this.id
}

output "name" {
  description = "The name of the workspace"
  value       = tfe_workspace.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_workspace.this.organization
}

output "project_id" {
  description = "The ID of the project"
  value       = tfe_workspace.this.project_id
}

output "html_url" {
  description = "The URL to the workspace in the HCP Terraform UI"
  value       = tfe_workspace.this.html_url
}

output "resource_count" {
  description = "The number of resources managed by the workspace"
  value       = tfe_workspace.this.resource_count
}

output "terraform_version" {
  description = "The Terraform version configured for the workspace"
  value       = tfe_workspace.this.terraform_version
}

output "execution_mode" {
  description = "The execution mode of the workspace"
  value       = tfe_workspace_settings.this.execution_mode
}

output "agent_pool_id" {
  description = "The agent pool ID configured for the workspace"
  value       = tfe_workspace_settings.this.agent_pool_id
}

output "global_remote_state" {
  description = "Whether the workspace allows all workspaces in the organization to access its state"
  value       = tfe_workspace_settings.this.global_remote_state
}

output "project_remote_state" {
  description = "Whether the workspace allows all workspaces in the project to access its state"
  value       = tfe_workspace_settings.this.project_remote_state
}

output "remote_state_consumer_ids" {
  description = "The set of workspace IDs set as explicit remote state consumers"
  value       = tfe_workspace_settings.this.remote_state_consumer_ids
}

output "auto_apply" {
  description = "Whether to automatically apply changes when a Terraform plan is successful"
  value       = tfe_workspace_settings.this.auto_apply
}

output "assessments_enabled" {
  description = "Whether to regularly run health assessments"
  value       = tfe_workspace_settings.this.assessments_enabled
}

output "description" {
  description = "The description of the workspace"
  value       = tfe_workspace_settings.this.description
}

output "tags" {
  description = "The tags configured for the workspace"
  value       = tfe_workspace_settings.this.tags
}

output "effective_tags" {
  description = "All tags for the workspace including inherited tags from the project"
  value       = tfe_workspace_settings.this.effective_tags
}

output "vcs_repo" {
  description = "The VCS repository configuration"
  value       = var.vcs_repo
  sensitive   = false
}


output "workspace_run_task_ids" {
  description = "Map of workspace run task IDs"
  value       = { for k, v in tfe_workspace_run_task.this : k => v.id }
}
