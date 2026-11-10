resource "tfe_variable_set" "this" {
  organization = var.organization
  name         = var.name
  description  = var.description
  global       = var.global
  priority     = var.priority
}

resource "tfe_variable" "this" {
  for_each = var.variables

  key             = each.key
  value           = each.value.value
  category        = each.value.category
  description     = each.value.description
  hcl             = each.value.hcl
  sensitive       = each.value.sensitive
  variable_set_id = tfe_variable_set.this.id
}

resource "tfe_workspace_variable_set" "this" {
  for_each = var.workspace_ids_map

  variable_set_id = tfe_variable_set.this.id
  workspace_id    = each.value
}

resource "tfe_project_variable_set" "this" {
  for_each = var.project_ids_map

  variable_set_id = tfe_variable_set.this.id
  project_id      = each.value
}
