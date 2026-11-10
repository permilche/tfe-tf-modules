variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the workspace"
  type        = string
}

variable "description" {
  description = "A description for the workspace. Defaults to null"
  type        = string
  default     = null
}

variable "project_id" {
  description = "ID of the project to which the workspace belongs. Defaults to null (organization's default project)"
  type        = string
  default     = null
}

# Execution settings
variable "execution_mode" {
  description = "Which execution mode to use. Valid values are remote, local, and agent. Defaults to remote"
  type        = string
  default     = "remote"

  validation {
    condition     = contains(["remote", "local", "agent"], var.execution_mode)
    error_message = "Valid values for execution_mode are 'remote', 'local', and 'agent'"
  }
}

variable "agent_pool_id" {
  description = "The ID of an agent pool to assign to the workspace. Required when execution_mode is set to agent. Defaults to null"
  type        = string
  default     = null
}

variable "global_remote_state" {
  description = "Whether the workspace allows all workspaces in the organization to access its state data during runs. If false, then only specifically approved workspaces can access its state. Cannot be true if project_remote_state is true. Defaults to null (uses organization default)"
  type        = bool
  default     = null
}

variable "project_remote_state" {
  description = "Whether the workspace allows all workspaces in the project to access its state data during runs. If false, then only specifically approved workspaces can access its state. Cannot be true if global_remote_state is true. Defaults to null"
  type        = bool
  default     = null
}

variable "remote_state_consumer_ids" {
  description = "The set of workspace IDs set as explicit remote state consumers for the given workspace. To set this attribute, global_remote_state and project_remote_state must be false. Defaults to empty set"
  type        = set(string)
  default     = []
}

variable "allow_destroy_plan" {
  description = "Whether destroy plans can be queued on the workspace. Defaults to true"
  type        = bool
  default     = true
}

variable "auto_apply" {
  description = "Whether to automatically apply changes when a Terraform plan is successful. Defaults to false"
  type        = bool
  default     = false
}

variable "auto_apply_run_trigger" {
  description = "Whether to automatically apply changes for runs that were created by run triggers from another workspace. Defaults to false"
  type        = bool
  default     = false
}

variable "file_triggers_enabled" {
  description = "Whether to filter runs based on the changed files in a VCS push. Defaults to true"
  type        = bool
  default     = true
}

variable "queue_all_runs" {
  description = "Whether runs should be queued immediately after workspace creation. Defaults to true"
  type        = bool
  default     = true
}

variable "speculative_enabled" {
  description = "Whether this workspace allows automatic speculative plans. Defaults to true"
  type        = bool
  default     = true
}

variable "assessments_enabled" {
  description = "Whether to regularly run health assessments. Defaults to false"
  type        = bool
  default     = false
}

# Terraform settings
variable "terraform_version" {
  description = "The version of Terraform to use for this workspace. Defaults to the latest available version in TFE (check https://tfe.achene.sbx.hashidemos.io/app/admin/terraform-versions URL for the latest version or to add a new one)"
  type        = string
  default     = null
}

variable "working_directory" {
  description = "A relative path that Terraform will execute within. Defaults to the root of the repository"
  type        = string
  default     = null
}

variable "trigger_prefixes" {
  description = "List of repository-root-relative paths which should be tracked for changes. Defaults to null"
  type        = list(string)
  default     = null
}

variable "trigger_patterns" {
  description = "List of glob patterns that describe the files HCP Terraform monitors for changes. Defaults to null"
  type        = list(string)
  default     = null
}

# VCS settings
variable "vcs_repo" {
  description = "Settings for the workspace's VCS repository. Defaults to null. The identifier format is automatically constructed based on vcs_provider."
  type = object({
    vcs_provider               = optional(string, "github") # github, gitlab, bitbucket, azure_devops
    vcs_organization           = optional(string)           # VCS organization name
    vcs_project                = optional(string)           # Required for Azure DevOps, ignored for others
    repository                 = optional(string)           # Repository name
    identifier                 = optional(string)           # Manual override, if provided, vcs_provider/vcs_organization/vcs_project/repository are ignored
    branch                     = optional(string)
    ingress_submodules         = optional(bool)
    oauth_token_id             = optional(string)
    github_app_installation_id = optional(string)
    tags_regex                 = optional(string)
  })
  default = null

  validation {
    condition = var.vcs_repo == null || (
      var.vcs_repo.identifier != null || 
      (var.vcs_repo.vcs_organization != null && var.vcs_repo.repository != null)
    )
    error_message = "Either 'identifier' must be provided, or both 'vcs_organization' and 'repository' must be provided."
  }

  validation {
    condition = var.vcs_repo == null || (
      var.vcs_repo.identifier != null ||
      var.vcs_repo.vcs_provider != "azure_devops" ||
      var.vcs_repo.vcs_project != null
    )
    error_message = "For Azure DevOps (vcs_provider='azure_devops'), 'vcs_project' is required when using automatic identifier construction."
  }

  validation {
    condition = var.vcs_repo == null || (
      var.vcs_repo.vcs_provider == null ||
      contains(["github", "gitlab", "bitbucket", "azure_devops"], var.vcs_repo.vcs_provider)
    )
    error_message = "Valid values for vcs_provider are 'github', 'gitlab', 'bitbucket', or 'azure_devops'."
  }
}

# Tags
variable "tag_names" {
  description = "A list of tag names for this workspace. Defaults to empty list"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of key-value tags for this workspace. Managed via tfe_workspace_settings. Defaults to empty map"
  type        = map(string)
  default     = {}
}

variable "structured_run_output_enabled" {
  description = "Whether to enable structured run output for this workspace. Defaults to true"
  type        = bool
  default     = true
}

# Team access
variable "team_access" {
  description = "Map of team access configurations for the workspace. Key is a unique identifier for each team access"
  type = map(object({
    team_id = string
    access  = optional(string)
    permissions = optional(object({
      runs              = string
      variables         = string
      state_versions    = string
      sentinel_mocks    = string
      workspace_locking = bool
      run_tasks         = bool
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.team_access :
      v.access == null || contains(["read", "plan", "write", "admin", "custom"], v.access)
    ])
    error_message = "Valid values for access are 'read', 'plan', 'write', 'admin', or 'custom'"
  }
}

# Variables
variable "variables" {
  description = "Map of variables to create in the workspace. Key is the variable name"
  type = map(object({
    value       = string
    category    = string
    description = optional(string)
    hcl         = optional(bool, false)
    sensitive   = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.variables :
      contains(["terraform", "env"], v.category)
    ])
    error_message = "Variable category must be either 'terraform' or 'env'"
  }
}

# Run triggers
variable "run_trigger_source_workspace_ids" {
  description = "Set of workspace IDs that will trigger runs in this workspace. Defaults to empty set"
  type        = set(string)
  default     = []
}

# Notification configurations
variable "notification_configurations" {
  description = "Map of notification configurations for the workspace. Key is the notification name"
  type = map(object({
    destination_type = string
    enabled          = optional(bool, true)
    triggers         = optional(list(string))
    url              = optional(string)
    token            = optional(string)
    email_user_ids   = optional(list(string))
    email_addresses  = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.notification_configurations :
      contains(["email", "generic", "slack", "microsoft-teams"], v.destination_type)
    ])
    error_message = "Valid destination_type values are 'email', 'generic', 'slack', or 'microsoft-teams'"
  }
}

# Workspace run tasks
variable "workspace_run_tasks" {
  description = "Map of run task configurations for the workspace. Key is a unique identifier for each run task association. Specify either task_id (for module outputs) or task_name (to lookup existing run task by name)"
  type = map(object({
    task_id           = optional(string)
    task_name         = optional(string)
    enforcement_level = string
    stage             = optional(string, "post_plan")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.workspace_run_tasks :
      (v.task_id != null && v.task_name == null) || (v.task_id == null && v.task_name != null)
    ])
    error_message = "Each run task must specify either task_id or task_name, but not both"
  }

  validation {
    condition = alltrue([
      for k, v in var.workspace_run_tasks :
      contains(["advisory", "mandatory"], v.enforcement_level)
    ])
    error_message = "Valid values for enforcement_level are 'advisory' or 'mandatory'"
  }

  validation {
    condition = alltrue([
      for k, v in var.workspace_run_tasks :
      contains(["pre_plan", "post_plan", "pre_apply", "post_apply"], v.stage)
    ])
    error_message = "Valid values for stage are 'pre_plan', 'post_plan', 'pre_apply', or 'post_apply'"
  }
}

variable "ssh_key_id" {
  description = "The ID of the SSH key to associate with the workspace for Git access"
  type        = string
  default     = null
}
