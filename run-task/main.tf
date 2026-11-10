resource "tfe_organization_run_task" "this" {
  organization = var.organization
  name         = var.name
  url          = var.url
  description  = var.description
  enabled      = var.enabled
  hmac_key     = var.hmac_key
  category     = var.category
}

resource "tfe_workspace_run_task" "this" {
  for_each = var.workspace_run_tasks

  workspace_id      = each.value.workspace_id
  task_id           = tfe_organization_run_task.this.id
  enforcement_level = each.value.enforcement_level
  stage             = each.value.stage
}
