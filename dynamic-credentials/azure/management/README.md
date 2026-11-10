# Azure Dynamic Credentials - Management Module

This module manages a single federated identity credential for a Terraform Enterprise/HCP Terraform workspace. It should be run by the TFE management workspace using dynamic credentials.

## Purpose

This is the **management layer** that creates a single `azuread_application_federated_identity_credential` for one workspace/run_phase combination. Responsibility for creating multiple credentials lies with the caller, use `for_each` on the module invocation rather than passing a collection into the module.

## Resources Created

- `azuread_application_federated_identity_credential.this`: A single federated identity credential for the given workspace and run phase

## Usage

```hcl
locals {
  credentials = {
    "my-org-my-project-workspace-1-plan" = {
      organization = "my-org"
      project      = "my-project"
      workspace    = "workspace-1"
      run_phase    = "plan"
    }
    "my-org-my-project-workspace-1-apply" = {
      organization = "my-org"
      project      = "my-project"
      workspace    = "workspace-1"
      run_phase    = "apply"
    }
  }
}

module "azure_dynamic_credentials_management" {
  source = "./dynamic-credentials/azure/management"

  for_each = local.credentials

  tfc_application_id = var.tfc_application_id
  organization       = each.value.organization
  project            = each.value.project
  workspace          = each.value.workspace
  run_phase          = each.value.run_phase

  # Optional overrides
  # tfc_hostname       = "app.terraform.io"
  # tfc_azure_audience = "api://AzureADTokenExchange"
  # display_name       = "custom-credential-name"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `tfc_application_id` | The Azure AD Application Object ID | `string` | n/a | yes |
| `organization` | TFE Organization name | `string` | n/a | yes |
| `project` | TFE Project name | `string` | n/a | yes |
| `workspace` | TFE Workspace name | `string` | n/a | yes |
| `run_phase` | TFE run phase (`plan`, `apply`, or `*`) | `string` | n/a | yes |
| `tfc_hostname` | TFE hostname | `string` | `"app.terraform.io"` | no |
| `tfc_azure_audience` | Audience value to use in run identity tokens | `string` | `"api://AzureADTokenExchange"` | no |
| `display_name` | Display name for the federated identity credential. Defaults to `<organization>-<project>-<workspace>-<run_phase>` | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | ID of the federated identity credential |
| `display_name` | Display name of the federated identity credential |
| `subject` | Subject of the federated identity credential |
