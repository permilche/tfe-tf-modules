resource "tfe_policy" "this" {
  for_each = var.policies

  name         = each.key
  description  = each.value.description
  organization = var.organization
  kind         = var.kind
  policy       = file(each.value.policy_path)
  enforce_mode = each.value.enforcement_level
}

resource "tfe_policy_set" "this" {
  name                = var.name
  description         = var.description
  organization        = var.organization
  global              = var.global
  kind                = var.kind
  policies_path       = var.policies_path # different thatn policy_path from the tfe_policy resource
  policy_tool_version = var.policy_tool_version
  agent_enabled       = var.agent_enabled
  overridable         = var.overridable
  slug                = var.slug
  # attach the policies created above by ID if non vcs-managed
  policy_ids = [for p in tfe_policy.this : p.id]

  dynamic "vcs_repo" {
    for_each = var.vcs_repo != null ? [var.vcs_repo] : []
    content {
      identifier                 = vcs_repo.value.identifier
      branch                     = vcs_repo.value.branch
      ingress_submodules         = vcs_repo.value.ingress_submodules
      oauth_token_id             = vcs_repo.value.oauth_token_id
      github_app_installation_id = vcs_repo.value.github_app_installation_id
    }
  }
}

resource "tfe_workspace_policy_set" "this" {
  for_each      = var.workspace_ids
  policy_set_id = tfe_policy_set.this.id
  workspace_id  = each.value
}

resource "tfe_project_policy_set" "this" {
  for_each      = var.project_ids
  policy_set_id = tfe_policy_set.this.id
  project_id    = each.value
}

resource "tfe_workspace_policy_set_exclusion" "this" {
  for_each      = var.global ? var.workspace_exclusion_ids : {}
  policy_set_id = tfe_policy_set.this.id
  workspace_id  = each.value
}

resource "tfe_project_policy_set_exclusion" "this" {
  for_each      = var.global ? var.project_exclusion_ids : {}
  policy_set_id = tfe_policy_set.this.id
  project_id    = each.value
}
