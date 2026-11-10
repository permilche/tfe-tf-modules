variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "email" {
  description = "Admin email address for the organization"
  type        = string
}

variable "session_timeout_minutes" {
  description = "Session timeout after inactivity (minutes). Defaults to 20160 (14 days)"
  type        = number
  default     = 20160
}

variable "session_remember_minutes" {
  description = "Session expiration (minutes). Defaults to 20160 (14 days)"
  type        = number
  default     = 20160
}

variable "collaborator_auth_policy" {
  description = "Authentication policy for collaborators. Valid values are 'password', 'two_factor_mandatory'. Defaults to 'password'"
  type        = string
  default     = "password"

  validation {
    condition     = contains(["password", "two_factor_mandatory"], var.collaborator_auth_policy)
    error_message = "Valid values for collaborator_auth_policy are 'password' and 'two_factor_mandatory'"
  }
}

variable "cost_estimation_enabled" {
  description = "Whether cost estimation is enabled for all workspaces. Defaults to true"
  type        = bool
  default     = true
}

variable "owners_team_saml_role_id" {
  description = "SAML role ID for the owners team. Defaults to null"
  type        = string
  default     = null
}

variable "send_passing_statuses_for_untriggered_speculative_plans" {
  description = "Whether to send VCS status updates for untriggered speculative plans. Defaults to false"
  type        = bool
  default     = false
}

variable "aggregated_commit_status_enabled" {
  description = "Whether to enable aggregated VCS commit status. Defaults to true"
  type        = bool
  default     = true
}

variable "assessments_enforced" {
  description = "Whether to enforce health assessments. Defaults to false"
  type        = bool
  default     = false
}

variable "allow_force_delete_workspaces" {
  description = "Whether to allow force deletion of workspaces. Defaults to false"
  type        = bool
  default     = false
}

variable "default_execution_mode" {
  description = "The default execution mode for new workspaces. Valid values are 'remote', 'local', and 'agent'. Defaults to 'remote'"
  type        = string
  default     = "remote"

  validation {
    condition     = contains(["remote", "local", "agent"], var.default_execution_mode)
    error_message = "Valid values for default_execution_mode are 'remote', 'local', and 'agent'"
  }
}

variable "default_agent_pool_id" {
  description = "The ID of the default agent pool for new workspaces when default_execution_mode is 'agent'. Defaults to null"
  type        = string
  default     = null
}

variable "tfe_admin_smtp_settings" {
  description = "Configuration for the TFE instance's admin SMTP settings"
  type = object({
    enabled             = optional(bool, true)
    host                = string
    port                = optional(number, 587)
    sender              = string
    auth                = optional(string, "none")
    username            = optional(string)
    password_wo         = optional(string)
    password_wo_version = optional(number)
    test_email_address  = optional(string)
  })
  default = null
  sensitive = true
}
