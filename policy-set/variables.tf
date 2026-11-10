variable "name" {
  description = "Name of the policy set"
  type        = string
}

variable "description" {
  description = "A description of the policy set's scope or purpose. Defaults to null"
  type        = string
  default     = null
}

variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "global" {
  description = "Whether or not policies in this set will apply to all workspaces. Defaults to false"
  type        = bool
  default     = false
}

variable "kind" {
  description = "The policy-as-code framework for the policies in this set. Valid values are sentinel and opa. Defaults to sentinel"
  type        = string
  default     = "sentinel"

  # at the moment terraform policy is not available in the provider so only two available values are these
  validation {
    condition     = contains(["sentinel", "opa"], var.kind)
    error_message = "Valid values for kind are 'sentinel' and 'opa'"
  }
}

variable "policies" {
  description = "Map of non vcs-managed policies to create and attach to a policy set. Use only if no VCS integration is available"
  type = map(object({
    description       = optional(string)
    policy_path       = string
    enforcement_level = string
  }))
  default = {}

  # policy names follow the same naming rule enforced by the TFE UI/API
  validation {
    condition = alltrue([
      for name, _ in var.policies : can(regex("^[A-Za-z0-9_-]+$", name))
    ])
    error_message = "Policy names may only contain letters, numbers, dashes (-), and underscores (_)"
  }

  # fail fast if a policy_path doesn't actually point to a path
  validation {
    condition = alltrue([
      for _, p in var.policies : fileexists(p.policy_path)
    ])
    error_message = "Each policy_path must point to an existing, readable path"
  }

  validation {
    condition = var.kind != "sentinel" ? true : alltrue([
      for _, p in var.policies : contains(["advisory", "soft-mandatory", "hard-mandatory"], p.enforcement_level)
    ])
    error_message = "For Sentinel policies (kind = \"sentinel\"), enforcement_level must be one of: \"advisory\", \"soft-mandatory\", \"hard-mandatory\"."
  }

  validation {
    condition = var.kind != "opa" ? true : alltrue([
      for _, p in var.policies : contains(["advisory", "mandatory"], p.enforcement_level)
    ])
    error_message = "For OPA policies (kind = \"opa\"), enforcement_level must be one of: \"advisory\", \"mandatory\""
  }
}

variable "policies_path" {
  description = "The sub-path within the attached VCS repository to crawl for policies. Policies outside this path will be ignored. Defaults to null"
  type        = string
  default     = null
}

variable "policy_tool_version" {
  description = "The version of the policy-as-code framework to use. Defaults to null so it is unspecified, therefore, using the latest version"
  type        = string
  default     = null
}

variable "workspace_ids" {
  description = "A map of workspace IDs to attach to the policy set. Defaults to empty"
  type        = map(string)
  default     = {}
}

variable "project_ids" {
  description = "A map of project IDs to attach to the policy set. Defaults to empty"
  type        = map(string)
  default     = {}
}

variable "vcs_repo" {
  description = "Settings for the policy set's VCS repository. Defaults to null"
  type = object({
    identifier                 = string
    branch                     = optional(string)
    ingress_submodules         = optional(bool)
    oauth_token_id             = optional(string)
    github_app_installation_id = optional(string)
  })
  default = null
}

variable "agent_enabled" {
  description = "Whether or not the policy set is executed by HCP Terraform agents. Defaults to false"
  type        = bool
  default     = false
}

variable "overridable" {
  description = "Whether or not the policy set is overridable. Defaults to false"
  type        = bool
  default     = false
}

variable "slug" {
  description = "Settings for the policy set's slug. Requires a data of type tfe_slug in order to work. Defaults to null"
  type        = any
  default     = null
}

variable "workspace_exclusion_ids" {
  description = "A map of workspace IDs to exclude from the policy map. Only works when the policy set is global"
  type        = map(string)
  default     = {}
}

variable "project_exclusion_ids" {
  description = "A map of project IDs to exclude from the policy map. Only works when the policy set is global"
  type        = map(string)
  default     = {}
}
