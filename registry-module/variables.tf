variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "namespace" {
  description = "The namespace of the module. For private modules, this is the organization name. Defaults to organization if not specified"
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the module"
  type        = string
}

variable "module_provider" {
  description = "The provider of the module (e.g., 'aws', 'azurerm', 'google')"
  type        = string
}

variable "registry_name" {
  description = "The registry name. Valid values are 'private' and 'public'. Defaults to 'private'"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.registry_name)
    error_message = "Valid values for registry_name are 'private' and 'public'"
  }
}

variable "vcs_repo" {
  description = "Settings for the module's VCS repository"
  type = object({
    display_identifier         = string
    identifier                 = string
    oauth_token_id             = optional(string)
    github_app_installation_id = optional(string)
    branch                     = optional(string)
    tags                       = optional(bool, false)
    source_directory           = optional(string)
    tag_prefix                 = optional(string)
  })
  default = null
}

variable "initial_version" {
  description = "The initial version of the module. Only used when creating a new module. Defaults to null"
  type        = string
  default     = null
}

variable "test_config" {
  description = "Test configuration for the module. Defaults to empty list"
  type = list(object({
    tests_enabled = optional(bool, true)
    agent_execution_mode = optional(string, "remote")
    agent_pool_id = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for tc in var.test_config : contains(["remote", "agent"], tc.agent_execution_mode)])
    error_message = "agent_execution_mode must be either 'remote' or 'agent'"
  }
}

variable "no_code_enabled" {
  description = "Whether to enable no-code provisioning for this module. Defaults to false"
  type        = bool
  default     = false
}

variable "no_code_version_pin" {
  description = "The pinned version for no-code provisioning. Only used when no_code_enabled is true"
  type        = string
  default     = null
}

variable "no_code_variable_options" {
  description = "Variable options for no-code provisioning. Only used when no_code_enabled is true"
  type = list(object({
    name    = string
    type    = string
    options = list(string)
  }))
  default = []
}
