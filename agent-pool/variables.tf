variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the agent pool"
  type        = string
}

variable "organization_scoped" {
  description = "Whether the agent pool is available to all workspaces in the organization. Defaults to true"
  type        = bool
  default     = true
}

variable "allowed_workspace_ids" {
  description = "Set of workspace IDs that are allowed to use this agent pool. Only used when organization_scoped is false. Defaults to empty set"
  type        = set(string)
  default     = []
}

variable "agent_tokens" {
  description = "Map of agent tokens to create. Key is a unique identifier for each token"
  type = map(object({
    description = string
  }))
  default = {}
}
