resource "tfe_oauth_client" "this" {
  organization     = var.organization
  api_url          = var.api_url
  http_url         = var.http_url
  service_provider = var.service_provider

  name                = var.name
  key                 = var.key
  secret              = var.secret
  rsa_public_key      = var.rsa_public_key
  private_key         = var.private_key
  oauth_token         = var.oauth_token
  agent_pool_id       = var.agent_pool_id
  organization_scoped = var.organization_scoped
}

resource "tfe_project_oauth_client" "this" {
  for_each = var.manage_project_attachments ? var.project_ids : []

  oauth_client_id = tfe_oauth_client.this.id
  project_id      = each.value
}