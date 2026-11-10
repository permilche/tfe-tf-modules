# Azure Dynamic Credentials - Configuration Module

This module bootstraps the Azure Entra ID resources required for Terraform Enterprise/HCP Terraform dynamic credentials. It can be used in multiple scenarios:

1. **Initial Bootstrap**: Run once by a platform engineer using local Azure credentials with sufficient directory permissions
2. **Management Bootstrap**: Used by the management module with dynamic credentials to create additional service principals for different tenants, subscriptions, or advanced multi-environment scenarios

## Purpose

This is the **configuration layer** for Azure dynamic credentials. It creates the application identity that Terraform Enterprise/HCP Terraform will use to manage federated identity credentials from the companion management module.

Specifically, this module bootstraps:

- An Azure application registration
- A service principal for that application
- Microsoft Graph application access required to manage owned applications
- Ownership assignments required so the application can manage its own federated identity credentials later
- Azure subscription or resource group role assignments for the service principal

## Resources Created

This module creates the following resources:

- `azuread_application_registration.tfc_application`: Azure application registration used for dynamic credentials
- `azuread_application_api_access.tfc_graph_access`: Declares required Microsoft Graph application access on the application registration
- `azuread_service_principal.tfc_service_principal`: Service principal for the application registration
- `azuread_application_owner.bootstrap_user`: Optionally assigns the bootstrap identity as an owner of the application registration when `add_bootstrap_user_ownership` is enabled
- `azuread_application_owner.self`: Assigns the application's own service principal as an owner of the application registration
- `azuread_app_role_assignment.tfc_graph_permissions`: Grants the service principal the Microsoft Graph `Application.ReadWrite.OwnedBy` application permission
- `azurerm_role_assignment.tfc_role_assignment`: Assigns Azure roles to the service principal at subscription or resource group level

## Provider Requirements

This module uses both the `azuread` and `azurerm` providers.

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.60.0"
    }
  }
}
```

## Usage

### Basic Usage (Default Configuration)

```hcl
module "azure_dynamic_credentials_config" {
  source = "./dynamic-credentials/azure/configuration"
}
```

When no `role_assignments` parameter is provided, the module defaults to assigning the `Contributor` role at the subscription level.

### Custom Role Assignments

```hcl
module "azure_dynamic_credentials_config" {
  source = "./dynamic-credentials/azure/configuration"
  
  role_assignments = {
    contributor = {
      role_definition_name = "Contributor"
    }
  }
}
```

## Role Assignments

The module supports flexible role assignments at subscription or resource group level:

### Subscription-Level Permissions (Default)

```hcl
module "dynamic_creds_config" {
  source = "./dynamic-credentials/azure/configuration"
  
  role_assignments = {
    contributor = {
      role_definition_name = "Contributor"
    }
  }
}
```

### Resource Group-Level Permissions

```hcl
module "dynamic_creds_config" {
  source = "./dynamic-credentials/azure/configuration"
  
  role_assignments = {
    dev_rg = {
      role_definition_name = "Contributor"
      resource_group       = "rg-dev"
    }
  }
}
```

### Multiple Role Assignments

```hcl
module "dynamic_creds_config" {
  source = "./dynamic-credentials/azure/configuration"
  
  role_assignments = {
    reader_sub = {
      role_definition_name = "Reader"
      # Subscription-level
    }
    contributor_rg = {
      role_definition_name = "Contributor"
      resource_group       = "rg-app"
    }
    key_vault_admin = {
      role_definition_name = "Key Vault Administrator"
      resource_group       = "rg-shared"
    }
  }
}
```

### Backward Compatibility

If `role_assignments` is not provided, the module defaults to:
- Role: Contributor
- Scope: Subscription-level

## Outputs

The module outputs the following values needed by the management module:

- `tfc_application_id`: The application object ID used by the management module when creating federated identity credentials
- `tfc_application_client_id`: The application client ID. Use this value as `<app-client-id>` when validating application owners with the Azure CLI
- `tfc_service_principal_object_id`: The object ID of the service principal created for the application

## Why self-ownership is required

The service principal created by this module must be added as an owner of its own application registration.

This is required because the downstream management workflow authenticates as that service principal when creating federated identity credentials. Microsoft Graph allows the `Application.ReadWrite.OwnedBy` permission to manage only applications that the calling principal owns. By making the service principal an owner of its own application registration, later operations against that same application are treated as changes to an owned application.

Without this self-ownership assignment, the service principal may authenticate successfully but still be unable to create federated identity credentials for the application because the application would not be considered owned by the calling principal.

## Why `Application.ReadWrite.OwnedBy` is required

The management module creates `azuread_application_federated_identity_credential` resources through Microsoft Graph. When that operation is performed by a service principal, ownership alone is not enough. The calling service principal also needs the Microsoft Graph application permission `Application.ReadWrite.OwnedBy`.

This permission is needed because Microsoft Graph requires explicit application-level authorization for a service principal to create or modify federated identity credentials on applications it owns. Without it, the management module fails with a `403 Forbidden` / `Authorization_RequestDenied` error when attempting to create federated identity credentials.

In this module, that requirement is handled in two parts:

1. `azuread_application_api_access.tfc_graph_access` declares that the application requires the Microsoft Graph `Application.ReadWrite.OwnedBy` application permission.
2. `azuread_app_role_assignment.tfc_graph_permissions` grants that permission to the created service principal.

Together with self-ownership, this enables the service principal to manage federated identity credentials for its own application registration.

## Ownership behavior

This module always assigns the created service principal as an owner of its own application registration.

The bootstrap user ownership is optional and controlled by `add_bootstrap_user_ownership`:

- When `add_bootstrap_user_ownership = true`, the identity running the bootstrap is also added as an owner.
- When `add_bootstrap_user_ownership = false`, only the service principal self-ownership is configured by this module.

Keeping bootstrap user ownership optional lets you decide whether a human operator should retain direct ownership after the initial setup.

## Validate application owners

After applying the module, you can verify the owners of the application registration with the Azure CLI:

```bash
az ad app owner list --id <app-client-id>
```

Use the Terraform output `tfc_application_client_id` as the `<app-client-id>` value.

Validate that the returned owners include:

- Your bootstrap user, if `add_bootstrap_user_ownership` was enabled
- The service principal created by this module

This is a useful post-bootstrap check to confirm that both the optional human owner and the required service principal owner were configured as expected.

## Bootstrap Process

### Initial Bootstrap (Platform Engineer)

1. Authenticate locally to Azure with an identity that can create application registrations, service principals, ownership assignments, Microsoft Graph app role assignments, and Azure role assignments.
2. Run this module to create the Azure application registration and its service principal.
3. If `add_bootstrap_user_ownership` is enabled, the module assigns the bootstrap identity as an owner so the application can be administered after creation.
4. The module assigns the service principal as an owner of its own application registration.
5. The module configures and grants the Microsoft Graph `Application.ReadWrite.OwnedBy` permission required for later federated identity credential management.
6. The module assigns Azure roles to the service principal based on the `role_assignments` parameter (defaults to Contributor at subscription level).
7. Capture the output values from this module, especially `tfc_application_client_id` for ownership validation and downstream configuration.
8. Optionally validate the configured owners with `az ad app owner list --id <app-client-id>`.
9. Pass the output values into the Azure dynamic credentials management module, which will create federated identity credentials for Terraform Enterprise/HCP Terraform workspaces.


### Management Bootstrap (Dynamic Credentials)

When using this module from a management workspace with dynamic credentials to create service principals for other tenants or subscriptions:

1. Configure the `azuread` and `azurerm` providers with appropriate authentication (dynamic credentials or service principal).
2. Use provider aliases to target different Azure subscriptions or tenants.
3. Call this module multiple times with different provider configurations to create service principals for each environment.
4. Set `add_bootstrap_user_ownership = false` when the calling identity is a service principal (not a human user).
5. Configure `role_assignments` based on the specific permissions needed for each environment.
6. The created service principals can then be used by the management module to create federated identity credentials for workspace-specific dynamic credentials.

This pattern enables a centralized management approach where one set of dynamic credentials can bootstrap additional service principals across multiple Azure environments.


## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `app_registration_name` | Name of the Azure AD application registration used for dynamic credentials in TFE | `string` | `"tfe-dynamic-credentials"` | no |
| `add_bootstrap_user_ownership` | Whether to add the bootstrap identity running Terraform as an owner of the application registration | `bool` | `true` | no |
| `role_assignments` | Map of role assignments for the service principal. If resource_group is provided, scope is limited to that RG. If omitted, scope is the entire subscription. | `map(object({ role_definition_name = string, resource_group = optional(string), skip_service_principal_aad_check = optional(bool, false) }))` | `null` (defaults to Contributor at subscription level) | no |
