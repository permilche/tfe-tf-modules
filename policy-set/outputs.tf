output "policy_set_id" {
  description = "The ID of the policy set"
  value       = tfe_policy_set.this.id
}

output "policy_set_name" {
  description = "The name of the policy set"
  value       = tfe_policy_set.this.name
}

output "policy_set_workspace_ids" {
  description = "The IDs of the workspace policy set attachments"
  value       = { for k, v in tfe_workspace_policy_set.this : k => v.id }
}

output "policy_set_project_ids" {
  description = "The IDs of the project policy set attachments"
  value       = { for k, v in tfe_project_policy_set.this : k => v.id }
}

output "policy_set_vcs_repo" {
  description = "The VCS repository settings for the policy set"
  value       = tfe_policy_set.this.vcs_repo
}

output "policy_set_workspace_exclusion_ids" {
  description = "The IDs of the workspace/s excluded from the policy set"
  value       = { for k, v in tfe_workspace_policy_set_exclusion.this : k => v.id }
}

output "policy_set_project_exclusion_ids" {
  description = "The IDs of the project/s excluded from the policy set"
  value       = { for k, v in tfe_project_policy_set_exclusion.this : k => v.id }
}

