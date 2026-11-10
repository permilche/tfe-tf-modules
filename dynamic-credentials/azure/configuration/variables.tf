variable "app_registration_name" {
  description = "Name of the Azure AD application registration used for dynamic credentials in TFE"
  type        = string
  default     = "tfe-dynamic-credentials"
}

variable "add_bootstrap_user_ownership" {
  description = "Whether to explicitly manage the bootstrap user as an application owner. Set to false in tenants where the creator is automatically added as owner (e.g. delegated/user-context creation), to avoid an 'already exists' error. Set to true in tenants/auth contexts where auto-assignment does not occur (e.g. app-only/service-principal creation)."
  type        = bool
  default     = true
}

variable "role_assignments" {
  type = map(object({
    role_definition_name             = string
    resource_group                   = optional(string)
    skip_service_principal_aad_check = optional(bool, false)
  }))

  description = <<-EOT
    Map of role assignments for the service principal.

    If resource_group is provided, scope is limited to that RG.
    If omitted, scope is the entire subscription. It relies on the provider
    calling the module to get the subscription id through a data resource.

    Examples:

    {
      contributor_sub = {
        role_definition_name = "Contributor"
        # No resource_group = subscription-level
      }
      contributor_rg = {
        role_definition_name = "Contributor"
        resource_group       = "rg-dev"  # RG-level
      }
    }
  EOT

  default = null
}
