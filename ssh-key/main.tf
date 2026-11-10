resource "tfe_ssh_key" "this" {
  organization   = var.organization
  name           = var.name
  key_wo         = var.key
  key_wo_version = var.key_version
}
