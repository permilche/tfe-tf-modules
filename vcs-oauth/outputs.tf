output "oauth_client_id" {
  description = "The ID of the OAuth client"
  value       = tfe_oauth_client.this.id
}

output "oauth_token_id" {
  description = "The ID of the OAuth token associated with the OAuth client"
  value       = tfe_oauth_client.this.oauth_token_id
}

output "name" {
  description = "The name of the OAuth client"
  value       = tfe_oauth_client.this.name
}

output "service_provider" {
  description = "The VCS service provider type"
  value       = tfe_oauth_client.this.service_provider
}

output "api_url" {
  description = "The base URL of the VCS provider's API"
  value       = tfe_oauth_client.this.api_url
}

output "http_url" {
  description = "The homepage of the VCS provider"
  value       = tfe_oauth_client.this.http_url
}

output "organization" {
  description = "The organization name"
  value       = var.organization
}

output "organization_scoped" {
  description = "Whether the OAuth client is organization scoped"
  value       = tfe_oauth_client.this.organization_scoped
}

output "project_attachment_ids" {
  description = "Map of project IDs to their OAuth client attachment IDs"
  value = {
    for k, v in tfe_project_oauth_client.this : k => v.id
  }
}