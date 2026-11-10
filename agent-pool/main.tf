resource "tfe_agent_pool" "this" {
  organization                  = var.organization
  name                          = var.name
  organization_scoped           = var.organization_scoped
}

resource "tfe_agent_token" "this" {
  for_each = var.agent_tokens

  agent_pool_id = tfe_agent_pool.this.id
  description   = each.value.description
}

resource "tfe_agent_pool_allowed_workspaces" "this" {
  count = var.organization_scoped ? 0 : 1

  agent_pool_id         = tfe_agent_pool.this.id
  allowed_workspace_ids = var.allowed_workspace_ids
}
