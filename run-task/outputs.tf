output "id" {
  description = "The ID of the run task"
  value       = tfe_organization_run_task.this.id
}

output "name" {
  description = "The name of the run task"
  value       = tfe_organization_run_task.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_organization_run_task.this.organization
}

output "url" {
  description = "The URL of the run task"
  value       = tfe_organization_run_task.this.url
}

output "category" {
  description = "The category of the run task"
  value       = tfe_organization_run_task.this.category
}

output "enabled" {
  description = "Whether the run task is enabled"
  value       = tfe_organization_run_task.this.enabled
}

output "workspace_run_task_ids" {
  description = "Map of workspace run task association IDs"
  value = {
    for k, v in tfe_workspace_run_task.this : k => v.id
  }
}
