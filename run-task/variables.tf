variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the run task"
  type        = string
}

variable "url" {
  description = "URL of the run task endpoint"
  type        = string
}

variable "description" {
  description = "A description of the run task. Defaults to null"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the run task is enabled. Defaults to true"
  type        = bool
  default     = true
}

variable "hmac_key" {
  description = "HMAC key for request verification. Defaults to null"
  type        = string
  default     = null
  sensitive   = true
}

variable "category" {
  description = "The category of the run task. Valid values are 'task' and 'test'. Defaults to 'task'"
  type        = string
  default     = "task"

  validation {
    condition     = contains(["task", "test"], var.category)
    error_message = "Valid values for category are 'task' and 'test'"
  }
}

variable "workspace_run_tasks" {
  description = "Map of workspace run task associations. Key is a unique identifier for each association"
  type = map(object({
    workspace_id      = string
    enforcement_level = string
    stage             = optional(string, "post_plan")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.workspace_run_tasks :
      contains(["advisory", "mandatory"], v.enforcement_level)
    ])
    error_message = "Valid values for enforcement_level are 'advisory' and 'mandatory'"
  }

  validation {
    condition = alltrue([
      for k, v in var.workspace_run_tasks :
      v.stage == null || contains(["pre_plan", "post_plan", "pre_apply"], v.stage)
    ])
    error_message = "Valid values for stage are 'pre_plan', 'post_plan', and 'pre_apply'"
  }
}
