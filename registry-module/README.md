# TFE Registry Module

This module publishes and manages modules in the Terraform Enterprise/HCP Terraform private registry, with optional no-code provisioning support.

## Features

- Publishes modules to TFE private registry
- VCS-backed module publishing
- Automatic version detection from VCS tags
- No-code provisioning support
- Test configuration for module validation

## Usage

### Basic Private Registry Module

```hcl
module "registry_module_vpc" {
  source = "./registry-module"

  organization    = "my-org"
  name            = "vpc"
  module_provider = "aws"

  vcs_repo = {
    display_identifier = "my-org/terraform-aws-vpc"
    identifier         = "my-org/terraform-aws-vpc"
    branch             = "main"
    oauth_token_id     = module.vcs_oauth.oauth_token_id
    tags               = true  # Use VCS tags for versioning
  }
}
```

### Module with No-Code Provisioning

```hcl
module "registry_module_s3" {
  source = "./registry-module"

  organization    = "my-org"
  name            = "s3-bucket"
  module_provider = "aws"

  vcs_repo = {
    display_identifier = "my-org/terraform-aws-s3-bucket"
    identifier         = "my-org/terraform-aws-s3-bucket"
    oauth_token_id     = module.vcs_oauth.oauth_token_id
    tags               = true
  }

  no_code_enabled = true
  no_code_variable_options = [
    {
      name    = "environment"
      type    = "string"
      options = ["dev", "staging", "production"]
    },
    {
      name    = "bucket_purpose"
      type    = "string"
      options = ["logs", "data", "backups", "artifacts"]
    }
  ]
}
```

### Module with Test Configuration

```hcl
module "registry_module_network" {
  source = "./registry-module"

  organization    = "my-org"
  name            = "network"
  module_provider = "azurerm"

  vcs_repo = {
    display_identifier = "my-org/terraform-azurerm-network"
    identifier         = "my-org/terraform-azurerm-network"
    oauth_token_id     = module.vcs_oauth.oauth_token_id
    tags               = true
  }

  test_config = [
    {
      tests_enabled = true
    }
  ]
}
```

### Module with Initial Version

```hcl
module "registry_module_compute" {
  source = "./registry-module"

  organization    = "my-org"
  name            = "compute"
  module_provider = "google"

  vcs_repo = {
    display_identifier = "my-org/terraform-google-compute"
    identifier         = "my-org/terraform-google-compute"
    oauth_token_id     = module.vcs_oauth.oauth_token_id
  }

  initial_version = "1.0.0"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the module | `string` | n/a | yes |
| module_provider | Provider of the module (aws, azurerm, google, etc.) | `string` | n/a | yes |
| namespace | Namespace of the module | `string` | `null` (uses organization) | no |
| registry_name | Registry name (private, public) | `string` | `"private"` | no |
| vcs_repo | VCS repository settings | `object` | `null` | no |
| initial_version | Initial version of the module | `string` | `null` | no |
| test_config | Test configuration | `list(object)` | `[]` | no |
| no_code_enabled | Enable no-code provisioning | `bool` | `false` | no |
| no_code_version_pin | Version pinned for no-code provisioning (only used when `no_code_enabled = true`) | `string` | `null` | no |
| no_code_variable_options | Variable options for no-code | `list(object)` | `[]` | no |

### VCS Repository Object

```hcl
{
  display_identifier         = string           # Display name of the repository
  identifier                 = string           # VCS repository identifier (e.g., "org/repo")
  oauth_token_id             = optional(string) # OAuth token ID for VCS authentication
  github_app_installation_id = optional(string) # GitHub App installation ID
  branch                     = optional(string) # Branch to publish from
  tags                       = optional(bool)   # Publish versions from tags (default false)
  source_directory           = optional(string) # Module source directory within the repo
  tag_prefix                 = optional(string) # Only consider tags with this prefix
}
```

### Test Config Object

```hcl
{
  tests_enabled        = optional(bool)   # default true
  agent_execution_mode = optional(string) # "remote" (default) or "agent"
  agent_pool_id        = optional(string) # Agent pool to use when agent_execution_mode = "agent"
}
```

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the registry module |
| name | The name of the module |
| organization | The organization name |
| namespace | The namespace of the module |
| module_provider | The provider of the module |
| registry_name | The registry name |
| publishing_mechanism | The publishing mechanism |
| no_code_module_id | The ID of the no-code module (if enabled) |

## Module Naming Convention

Modules in the private registry follow the naming convention:
```
<namespace>/<name>/<provider>
```

For example:
- `my-org/vpc/aws`
- `my-org/network/azurerm`
- `my-org/compute/google`

## VCS Integration

### Tag-Based Versioning

When `tags = true` in the VCS repo configuration:
- Module versions are automatically detected from Git tags
- Tags should follow semantic versioning (e.g., `v1.0.0`, `1.0.0`)
- New versions are published automatically when new tags are pushed

### Branch-Based Publishing

When `tags = false` or not specified:
- Module is published from the specified branch
- Version must be manually managed

## No-Code Provisioning

No-code provisioning allows users to deploy modules through the TFE UI without writing Terraform code:

1. Enable with `no_code_enabled = true`
2. Optionally pin a module version with `no_code_version_pin`
3. Define variable options to provide dropdown selections in the UI
4. Users can provision infrastructure by selecting from predefined options

**Use Cases:**
- Self-service infrastructure for developers
- Standardized deployments with limited customization
- Simplified provisioning for non-Terraform users

## Best Practices

1. **Use Semantic Versioning**: Tag releases with semantic versions (v1.0.0, v1.1.0, etc.)
2. **Enable Tests**: Configure test_config to validate module functionality
3. **Document Variables**: Ensure module README documents all variables for no-code provisioning
4. **Namespace Organization**: Use organization name as namespace for consistency
5. **Provider Naming**: Use official provider names (aws, azurerm, google, kubernetes, etc.)
6. **VCS Tags**: Enable tag-based versioning for automatic version management
7. **No-Code Options**: Provide meaningful, limited options for no-code variables

## Integration with Other Modules

```hcl
# VCS OAuth configuration
module "vcs_oauth" {
  source = "./vcs-oauth"
  
  organization     = "my-org"
  service_provider = "github"
  # ... other configuration
}

# Publish multiple modules
module "registry_module_vpc" {
  source = "./registry-module"
  
  organization    = "my-org"
  name            = "vpc"
  module_provider = "aws"
  
  vcs_repo = {
    display_identifier = "my-org/terraform-aws-vpc"
    identifier         = "my-org/terraform-aws-vpc"
    oauth_token_id     = module.vcs_oauth.oauth_token_id
    tags               = true
  }
}

module "registry_module_eks" {
  source = "./registry-module"
  
  organization    = "my-org"
  name            = "eks"
  module_provider = "aws"
  
  vcs_repo = {
    display_identifier = "my-org/terraform-aws-eks"
    identifier         = "my-org/terraform-aws-eks"
    oauth_token_id     = module.vcs_oauth.oauth_token_id
    tags               = true
  }
}

# Use published module in workspace
module "workspace" {
  source = "./workspace"
  
  organization = "my-org"
  name         = "app-infrastructure"
  
  # Workspace will use modules from private registry
  # via standard Terraform module sources:
  # module "vpc" {
  #   source  = "app.terraform.io/my-org/vpc/aws"
  #   version = "1.0.0"
  # }
}
```

## Module Repository Structure

Your module repository should follow Terraform module conventions:

```
terraform-<provider>-<name>/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── examples/
│   └── basic/
│       ├── main.tf
│       └── README.md
└── tests/
    └── basic.tftest.hcl
```
