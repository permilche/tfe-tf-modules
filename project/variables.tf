variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the project"
  type        = string
}

variable "description" {
  description = "A description for the project. Defaults to null"
  type        = string
  default     = null
}

variable "team_access" {
  description = "Map of team access configurations for the project. Key is a unique identifier for each team access"
  type = map(object({
    team_id = string
    access  = optional(string)
    project_access  = optional(object({
      settings      = optional(string)
      teams         = optional(string)
      variable_sets = optional(string)
    }))
    workspace_access   = optional(object({
      create           = optional(bool)
      locking          = optional(bool)
      delete           = optional(bool)
      move             = optional(bool)
      policy_overrides = optional(bool)
      runs             = optional(string)
      run_tasks        = optional(bool)
      sentinel_mocks   = optional(string)
      state_versions   = optional(string)
      variables        = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.team_access :
      v.access == null || contains(["read", "write", "maintain", "admin", "custom"], v.access)
    ])
    error_message = "Valid values for access are 'read', 'write', 'maintain', 'admin', or 'custom'"
  }

  validation {
    condition = alltrue([
      for k, v in var.team_access :
      v.project_access == null || (
        (v.project_access.settings == null || contains(["read", "update", "delete"], v.project_access.settings)) &&
        (v.project_access.teams == null || contains(["none", "read", "manage"], v.project_access.teams)) &&
        (v.project_access.variable_sets == null || contains(["none", "read", "write"], v.project_access.variable_sets))
      )
    ])
    error_message = "Valid values for project_access: settings ('read', 'update', 'delete'), teams ('none', 'read', 'manage'), variable_sets ('none', 'read', 'write')"
  }

  validation {
    condition = alltrue([
      for k, v in var.team_access :
      v.workspace_access == null || (
        (v.workspace_access.runs == null || contains(["read", "plan", "apply"], v.workspace_access.runs)) &&
        (v.workspace_access.sentinel_mocks == null || contains(["none", "read"], v.workspace_access.sentinel_mocks)) &&
        (v.workspace_access.state_versions == null || contains(["none", "read-outputs", "read", "write"], v.workspace_access.state_versions)) &&
        (v.workspace_access.variables == null || contains(["none", "read", "write"], v.workspace_access.variables))
      )
    ])
    error_message = "Valid values for workspace_access: runs ('read', 'plan', 'apply'), sentinel_mocks ('none', 'read'), state_versions ('none', 'read-outputs', 'read', 'write'), variables ('none', 'read', 'write')"
  }
}
