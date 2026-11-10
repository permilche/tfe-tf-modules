variable "tfc_azure_audience" {
  type        = string
  default     = "api://AzureADTokenExchange"
  description = "The audience value to use in run identity tokens"
}

variable "tfc_application_id" {
  type        = string
  description = "The Azure AD Application Object ID"
}

variable "tfc_hostname" {
  type        = string
  description = "TFE hostname (e.g., app.terraform.io)"
  default     = "app.terraform.io"
}

variable "organization" {
  type        = string
  description = "TFE Organization name"
}

variable "project" {
  type        = string
  description = "TFE Project name"
}

variable "workspace" {
  type        = string
  description = "TFE Workspace name"
}

variable "run_phase" {
  type        = string
  description = "TFE run phase (plan, apply, or *)"
  validation {
    condition     = contains(["plan", "apply", "*"], var.run_phase)
    error_message = "run_phase must be 'plan', 'apply', or '*'."
  }
}

variable "display_name" {
  type        = string
  description = "Display name for the federated identity credential. Defaults to <organization>-<project>-<workspace>-<run_phase>"
  default     = null
}
