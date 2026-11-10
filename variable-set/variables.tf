variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the variable set"
  type        = string
}

variable "description" {
  description = "A description of the variable set. Defaults to null"
  type        = string
  default     = null
}

variable "global" {
  description = "Whether the variable set applies to all workspaces in the organization. Defaults to false"
  type        = bool
  default     = false
}

variable "priority" {
  description = "Whether the variables in this set can be overwritten by other variable sets. Defaults to false (can be overwritten)"
  type        = bool
  default     = false
}

variable "variables" {
  description = "Map of variables to create in the variable set. Key is the variable name"
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

# first approach was this but if we called it from the same source as you could do when bootstrapping TFE you get this error:
# │ Error: Invalid for_each argument
# │
# │   on .terraform/modules/varset_azure_credentials/main.tf line 29, in resource "tfe_project_variable_set" "this":
# │   29:   for_each = var.project_ids
# │     ├────────────────
# │     │ var.project_ids is set of string with 6 elements
# │
# │ The "for_each" set includes values derived from resource attributes that cannot be determined until apply, and so
# │ Terraform cannot determine the full set of keys that will identify the instances of this resource.
# │
# │ When working with unknown values in for_each, it's better to use a map value where the keys are defined statically in
# │ your configuration and where only the values contain apply-time results.
# │
# │ Alternatively, you could use the -target planning option to first apply only the resources that the for_each value
# │ depends on, and then apply a second time to fully converge.
# because projects hasn't been created yet so the key is unknown at plan time. Example of the invocation of the module that caused this error:
# module "varset_azure_credentials" {
#   source = "tfe.achene.sbx.hashidemos.io/achene-02-org/variable-set/tfe"
#   version = "0.0.1"

#   organization = var.organization_name
#   name         = "Azure Credentials Variable Set"
#   description  = "Contains AZURE_CREDENTIALS for all application projects"
  
#   project_ids = [
#     for project_key, project in var.projects : module.projects[project_key].id
#     if project.app_type != "bootstrap"
#   ]

#   variables = {
#     AZURE_CREDENTIALS = {
#       value     = var.azure_credentials
#       category  = "env"
#       sensitive = true
#     }
#   }
# }
# switching the module invocation from:
# project_ids = [
#   for project_key, project in var.projects : module.projects[project_key].id
# ]
# to:
# project_ids = {
#   for project_key, project in var.projects :
#   project_key => module.projects[project_key].id
#   if project.app_type != "bootstrap"
# }
# to have static keys for the map and only the values are unknown at plan time. 
# original variables:
# variable "workspace_ids" {
#   description = "Set of workspace IDs to apply the variable set to. Defaults to empty set"
#   type        = set(string)
#   default     = []
# }

# variable "project_ids" {
#   description = "Set of project IDs to apply the variable set to. Defaults to empty set"
#   type        = set(string)
#   default     = []
# }

variable "workspace_ids_map" {
  description = "Map of workspace IDs to apply the variable set to. Defaults to empty map"
  type        = map(string)
  default     = {}
}

variable "project_ids_map" {
  description = "Map of project IDs to apply the variable set to. Defaults to empty map"
  type = map(string)
  default = {}
}
