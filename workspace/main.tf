# Local variables for VCS identifier construction
locals {
  # Construct VCS identifier based on provider type
  vcs_identifier = var.vcs_repo == null ? null : (
    var.vcs_repo.identifier != null ? var.vcs_repo.identifier : (
      var.vcs_repo.vcs_provider == "azure_devops" ?
      "${var.vcs_repo.vcs_organization}/${var.vcs_repo.vcs_project}/_git/${var.vcs_repo.repository}" :
      "${var.vcs_repo.vcs_organization}/${var.vcs_repo.repository}"
    )
  )
}

resource "tfe_workspace" "this" {
  organization = var.organization
  name         = var.name
  project_id   = var.project_id

  # Execution settings
  allow_destroy_plan     = var.allow_destroy_plan
  auto_apply_run_trigger = var.auto_apply_run_trigger
  file_triggers_enabled  = var.file_triggers_enabled
  queue_all_runs         = var.queue_all_runs
  speculative_enabled    = var.speculative_enabled

  # Terraform settings
  terraform_version = var.terraform_version
  working_directory = var.working_directory
  trigger_prefixes  = var.trigger_prefixes
  trigger_patterns  = var.trigger_patterns

  # VCS settings
  dynamic "vcs_repo" {
    for_each = var.vcs_repo != null ? [var.vcs_repo] : []
    content {
      identifier                 = local.vcs_identifier
      branch                     = vcs_repo.value.branch
      github_app_installation_id = vcs_repo.value.github_app_installation_id
      ingress_submodules         = vcs_repo.value.ingress_submodules
      oauth_token_id             = vcs_repo.value.oauth_token_id
      tags_regex                 = vcs_repo.value.tags_regex
    }
  }

  # Structured run output
  structured_run_output_enabled = var.structured_run_output_enabled

  ssh_key_id = var.ssh_key_id
}

# Workspace settings (manages execution mode, agent pool, remote state, and other settings)
resource "tfe_workspace_settings" "this" {
  workspace_id              = tfe_workspace.this.id
  execution_mode            = var.execution_mode
  agent_pool_id             = var.agent_pool_id
  global_remote_state       = var.global_remote_state
  project_remote_state      = var.project_remote_state
  remote_state_consumer_ids = var.remote_state_consumer_ids
  auto_apply                = var.auto_apply
  assessments_enabled       = var.assessments_enabled
  description               = var.description
  tags                      = var.tags
}

# Team access for workspace
resource "tfe_team_access" "this" {
  for_each = var.team_access

  access       = each.value.access
  team_id      = each.value.team_id
  workspace_id = tfe_workspace.this.id

  dynamic "permissions" {
    for_each = each.value.permissions != null ? [each.value.permissions] : []
    content {
      runs              = permissions.value.runs
      variables         = permissions.value.variables
      state_versions    = permissions.value.state_versions
      sentinel_mocks    = permissions.value.sentinel_mocks
      workspace_locking = permissions.value.workspace_locking
      run_tasks         = permissions.value.run_tasks
    }
  }
}

# Variables
resource "tfe_variable" "this" {
  for_each = var.variables

  key          = each.key
  value        = each.value.value
  category     = each.value.category
  description  = each.value.description
  hcl          = each.value.hcl
  sensitive    = each.value.sensitive
  workspace_id = tfe_workspace.this.id
}


# Data source to lookup run tasks by name
data "tfe_organization_run_task" "lookup" {
  for_each = {
    for k, v in var.workspace_run_tasks :
    k => v if v.task_name != null
  }

  organization = var.organization
  name         = each.value.task_name
}

# Workspace run tasks
resource "tfe_workspace_run_task" "this" {
  for_each = var.workspace_run_tasks

  workspace_id      = tfe_workspace.this.id
  task_id           = each.value.task_id != null ? each.value.task_id : data.tfe_organization_run_task.lookup[each.key].id
  enforcement_level = each.value.enforcement_level
  stage             = each.value.stage
}

# Run triggers
resource "tfe_run_trigger" "this" {
  for_each = var.run_trigger_source_workspace_ids

  workspace_id         = tfe_workspace.this.id
  sourceable_id        = each.value
}

# Notification configurations
resource "tfe_notification_configuration" "this" {
  for_each = var.notification_configurations

  name             = each.key
  destination_type = each.value.destination_type
  enabled          = each.value.enabled
  workspace_id     = tfe_workspace.this.id

  # Triggers
  triggers = each.value.triggers

  # Destination-specific settings
  url              = each.value.url
  token            = each.value.token
  email_user_ids   = each.value.email_user_ids
  email_addresses  = each.value.email_addresses
}
