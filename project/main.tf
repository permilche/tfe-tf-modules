resource "tfe_project" "this" {
  organization = var.organization
  name         = var.name
  description  = var.description
}

resource "tfe_team_project_access" "this" {
  for_each = var.team_access

  access     = each.value.access
  team_id    = each.value.team_id
  project_id = tfe_project.this.id

  dynamic "project_access" {
    for_each = each.value.project_access != null ? [each.value.project_access] : []
    content {
      settings          = project_access.value.settings
      teams             = project_access.value.teams
      variable_sets     = project_access.value.variable_sets 
    }
  }

  dynamic "workspace_access" {
    for_each = each.value.workspace_access != null ? [each.value.workspace_access] : []
    content {
      create           = workspace_access.value.create
      locking          = workspace_access.value.locking
      delete           = workspace_access.value.delete
      move             = workspace_access.value.move
      policy_overrides = workspace_access.value.policy_overrides
      runs             = workspace_access.value.runs
      run_tasks        = workspace_access.value.run_tasks
      sentinel_mocks   = workspace_access.value.sentinel_mocks
      state_versions   = workspace_access.value.state_versions
      variables        = workspace_access.value.variables
    }
  }
}
