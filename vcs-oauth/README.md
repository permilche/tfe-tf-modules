# TFE VCS OAuth Module

Terraform module to create and manage VCS OAuth clients in Terraform Enterprise/HCP Terraform.

This module creates a `tfe_oauth_client` resource with full configuration support for all VCS providers.

## Features

- Create `tfe_oauth_client` with all available arguments
- Support for all VCS providers (GitHub, GitLab, Bitbucket, Azure DevOps)
- Optional `tfe_project_oauth_client` attachments for selected projects
- Outputs for downstream workspace and policy set modules (`oauth_token_id`)

## Supported VCS Providers

- `ado_server`: Azure DevOps Server
- `ado_services`: Azure DevOps Services
- `bitbucket_hosted`: Bitbucket Cloud
- `bitbucket_server`: Bitbucket Server
- `github`: GitHub.com
- `github_enterprise`: GitHub Enterprise
- `gitlab_hosted`: GitLab.com
- `gitlab_community_edition`: GitLab CE
- `gitlab_enterprise_edition`: GitLab EE

## Prerequisites

### Azure DevOps Services

Follow the official HashiCorp documentation:

1. In Azure DevOps Services, enable third-party application access via OAuth
2. In TFE organization settings, start adding a new VCS provider (Azure DevOps Services) and capture the callback URL
3. In Microsoft Entra, register an app with the callback URL, add Azure DevOps API permissions (`vso.code`, `vso.code_status`), and create a client secret
4. Use the Application (client) ID, Directory (tenant) ID, and Client Secret in this module

Reference: https://developer.hashicorp.com/terraform/enterprise/vcs/azure-devops-services

### Other VCS Providers

Refer to the Terraform Enterprise documentation for your specific VCS provider setup requirements.

## Usage

### Azure DevOps Services OAuth Client

```hcl
module "vcs_ado_oauth" {
  source = "./vcs-oauth"

  organization     = "example-org"
  service_provider = "ado_services"
  
  api_url  = "https://dev.azure.com"
  http_url = "https://dev.azure.com"
  
  # OAuth credentials from Microsoft Entra app registration
  key    = "your-application-client-id"
  secret = "your-client-secret"
  
  name                = "ado-services-oauth"
  organization_scoped = false
  
  # Attach to specific projects (requires organization_scoped = false)
  manage_project_attachments = true
  project_ids = [
    "prj-abc123",
    "prj-def456",
  ]
}
```

### GitHub Enterprise OAuth Client

```hcl
module "vcs_github" {
  source = "./vcs-oauth"

  organization     = "example-org"
  service_provider = "github_enterprise"
  
  api_url  = "https://github.example.com/api/v3"
  http_url = "https://github.example.com"
  
  key    = "your-github-oauth-app-id"
  secret = "your-github-oauth-app-secret"
  
  name = "github-enterprise-oauth"
}
```

### GitLab Self-Managed with SSH

```hcl
module "vcs_gitlab" {
  source = "./vcs-oauth"

  organization     = "example-org"
  service_provider = "gitlab_enterprise_edition"
  
  api_url  = "https://gitlab.example.com/api/v4"
  http_url = "https://gitlab.example.com"
  
  rsa_public_key = file("~/.ssh/gitlab_rsa.pub")
  private_key    = file("~/.ssh/gitlab_rsa")
  
  name = "gitlab-ee-oauth"
}
```

### Use with Policy Sets

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "sentinel-baseline"
  organization = "example-org"

  vcs_repo = {
    identifier     = "my-ado-org/my-project/_git/policies"
    oauth_token_id = module.vcs_ado_oauth.oauth_token_id
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the Terraform Enterprise organization | `string` | n/a | yes |
| api_url | Base URL of VCS provider's API | `string` | n/a | yes |
| http_url | Homepage of VCS provider | `string` | n/a | yes |
| service_provider | VCS service provider type | `string` | `"ado_services"` | no |
| name | Display name for OAuth client | `string` | `null` | no |
| key | OAuth Client ID (required for some providers) | `string` | `null` | no |
| secret | OAuth Client Secret (required for some providers) | `string` | `null` | no |
| rsa_public_key | SSH public key (required for some providers) | `string` | `null` | no |
| private_key | Private key (required for some providers) | `string` | `null` | no |
| oauth_token | OAuth token from VCS provider | `string` | `null` | no |
| agent_pool_id | Agent pool ID for this OAuth client | `string` | `null` | no |
| organization_scoped | Whether OAuth client is organization scoped | `bool` | `true` | no |
| manage_project_attachments | Whether to manage project-level OAuth client attachments (only valid when `organization_scoped = false`) | `bool` | `false` | no |
| project_ids | Set of project IDs to attach OAuth client to (must be non-empty when `manage_project_attachments = true`) | `set(string)` | `[]` | no |

### Authentication Requirements by Provider

Different VCS providers require different authentication arguments:

- **Azure DevOps (ado_services, ado_server)**: `key` + `secret`
- **GitHub (github, github_enterprise)**: `key` + `secret`
- **GitLab (gitlab_*)**: `key` + `secret` OR `rsa_public_key` + `private_key`
- **Bitbucket Server**: `key` + `rsa_public_key`
- **Bitbucket Cloud**: `key` + `secret`

## Outputs

| Name | Description |
|------|-------------|
| oauth_client_id | The ID of the OAuth client |
| oauth_token_id | The ID of the OAuth token (use for VCS repo connections) |
| name | The name of the OAuth client |
| service_provider | The VCS service provider type |
| api_url | The base URL of the VCS provider's API |
| http_url | The homepage of the VCS provider |
| organization | The organization name |
| organization_scoped | Whether the OAuth client is organization scoped |
| project_attachment_ids | Map of project IDs to OAuth client attachment IDs |

## Notes

- For Azure DevOps, use `dev.azure.com` repositories. Legacy `visualstudio.com` domains are not supported
- Keep OAuth client secrets secure and use sensitive variable handling
- Ensure you have completed the VCS provider setup before creating OAuth clients
- The callback URL is generated by TFE during the OAuth flow setup

## Migration from Data Source

If you were previously using this module with a data source to lookup existing OAuth clients, this is a **breaking change**. The module now only creates OAuth clients as resources.

To migrate:
1. Import existing OAuth clients into Terraform state
2. Update your module calls to provide all required arguments
3. Run `terraform plan` to verify no changes are needed