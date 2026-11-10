variable "organization" {
  description = "Name of the Terraform Enterprise organization"
  type        = string
}

variable "service_provider" {
  description = "VCS service provider type"
  type        = string
  default     = "ado_services"

  validation {
    condition = contains([
      "ado_server",
      "ado_services",
      "bitbucket_hosted",
      "bitbucket_server",
      "github",
      "github_enterprise",
      "gitlab_hosted",
      "gitlab_community_edition",
      "gitlab_enterprise_edition"
    ], var.service_provider)
    error_message = "service_provider must be a valid VCS provider type."
  }
}

variable "api_url" {
  description = "The base URL of your VCS provider's API (e.g., https://dev.azure.com for Azure DevOps Services)"
  type        = string
}

variable "http_url" {
  description = "The homepage of your VCS provider (e.g., https://dev.azure.com for Azure DevOps Services)"
  type        = string
}

variable "name" {
  description = "Display name for the OAuth Client"
  type        = string
  default     = null
}

variable "key" {
  description = "The OAuth Client ID. Required for some service providers (e.g., Azure DevOps, GitHub)"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret" {
  description = "The OAuth Client Secret. Required for some service providers (e.g., Azure DevOps, GitHub)"
  type        = string
  default     = null
  sensitive   = true
}

variable "rsa_public_key" {
  description = "The text of the SSH public key associated with your VCS provider. Required for some service providers (e.g., Bitbucket Server, GitLab)"
  type        = string
  default     = null
  sensitive   = true
}

variable "private_key" {
  description = "The text of the private key associated with your VCS provider. Required for some service providers"
  type        = string
  default     = null
  sensitive   = true
}

variable "oauth_token" {
  description = "The token string you were given by your VCS provider"
  type        = string
  default     = null
  sensitive   = true
}

variable "agent_pool_id" {
  description = "The ID of the agent pool to use for this OAuth client"
  type        = string
  default     = null
}

variable "organization_scoped" {
  description = "Whether the OAuth client is organization scoped. Defaults to true"
  type        = bool
  default     = true
}

variable "manage_project_attachments" {
  description = "Whether to manage project-level OAuth client attachments"
  type        = bool
  default     = false

  validation {
    condition     = var.manage_project_attachments ? !var.organization_scoped : true
    error_message = "manage_project_attachments can only be true when organization_scoped is false."
  }
}

variable "project_ids" {
  description = "A set of project IDs to attach the OAuth client to when manage_project_attachments is true"
  type        = set(string)
  default     = []

  validation {
    condition     = var.manage_project_attachments ? length(var.project_ids) > 0 : true
    error_message = "project_ids must be non-empty when manage_project_attachments is true."
  }
}