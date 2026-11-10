variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the team"
  type        = string
}

variable "visibility" {
  description = "The visibility of the team. Valid values are 'secret' and 'organization'. Defaults to 'organization'"
  type        = string
  default     = "organization"

  validation {
    condition     = contains(["secret", "organization"], var.visibility)
    error_message = "Valid values for visibility are 'secret' and 'organization'"
  }
}

variable "sso_team_id" {
  description = "The SSO Team ID. This is the ID of the team in the identity provider (e.g., Azure AD group ID). Defaults to null"
  type        = string
  default     = null
}

variable "organization_access" {
  description = "Settings for the team's organization access. Defaults to null (no organization-level permissions)"
  type = object({
    access_secret_teams         = optional(bool, false)
    delegate_policy_overrides   = optional(bool, false)
    manage_agent_pools          = optional(bool, false)
    manage_membership           = optional(bool, false)
    manage_modules              = optional(bool, false)
    manage_organization_access  = optional(bool, false)
    manage_policies             = optional(bool, false)
    manage_policy_overrides     = optional(bool, false)
    manage_projects             = optional(bool, false)
    manage_providers            = optional(bool, false)
    manage_run_tasks            = optional(bool, false)
    manage_teams                = optional(bool, false)
    manage_vcs_settings         = optional(bool, false)
    manage_workspaces           = optional(bool, false)
    read_projects               = optional(bool, false)
    read_workspaces             = optional(bool, false)
  })
  default = null

  validation {
    condition     = var.organization_access == null || !var.organization_access.manage_projects || var.organization_access.manage_workspaces
    error_message = "manage_projects requires manage_workspaces to be set to true"
  }

  validation {
    condition     = var.organization_access == null || !var.organization_access.read_projects || var.organization_access.read_workspaces
    error_message = "read_projects requires read_workspaces to be set to true"
  }
}

variable "organization_member_ids" {
  description = "Set of organization membership IDs to add to the team. Defaults to empty set"
  type        = set(string)
  default     = []
}
