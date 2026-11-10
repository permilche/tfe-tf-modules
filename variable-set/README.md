# TFE Variable Set Module

This module creates a Terraform Enterprise/HCP Terraform variable set that can be shared across multiple workspaces or projects.

## Features

- Creates a TFE variable set
- Manages variables within the set (Terraform and environment variables)
- Applies variable set to specific workspaces or projects
- Supports global variable sets (applied to all workspaces)
- Priority control to prevent variable overwriting

## Usage

### Global Variable Set

```hcl
module "global_vars" {
  source = "./variable-set"

  organization = "my-org"
  name         = "global-configuration"
  description  = "Global variables for all workspaces"
  global       = true

  variables = {
    organization_name = {
      value       = "my-org"
      category    = "terraform"
      description = "Organization name"
    }
    default_region = {
      value    = "us-east-1"
      category = "terraform"
    }
  }
}
```

### Project-Scoped Variable Set

```hcl
module "project_vars" {
  source = "./variable-set"

  organization = "my-org"
  name         = "project-common-vars"
  description  = "Common variables for project workspaces"

  project_ids_map = {
    app            = module.project_app.id
    infrastructure = module.project_infrastructure.id
  }

  variables = {
    environment = {
      value       = "production"
      category    = "terraform"
      description = "Environment name"
    }
    aws_region = {
      value    = "us-west-2"
      category = "terraform"
    }
  }
}
```

### Workspace-Scoped Variable Set with Sensitive Variables

```hcl
module "aws_credentials" {
  source = "./variable-set"

  organization = "my-org"
  name         = "aws-credentials"
  description  = "AWS credentials for specific workspaces"
  priority     = true  # Prevent overwriting

  workspace_ids_map = {
    prod    = module.workspace_prod.id
    staging = module.workspace_staging.id
  }

  variables = {
    AWS_ACCESS_KEY_ID = {
      value     = var.aws_access_key_id
      category  = "env"
      sensitive = true
    }
    AWS_SECRET_ACCESS_KEY = {
      value     = var.aws_secret_access_key
      category  = "env"
      sensitive = true
    }
    AWS_DEFAULT_REGION = {
      value    = "us-east-1"
      category = "env"
    }
  }
}
```

### Variable Set with HCL Variables

```hcl
module "complex_vars" {
  source = "./variable-set"

  organization = "my-org"
  name         = "complex-configuration"

  project_ids_map = {
    my_project = module.project.id
  }

  variables = {
    tags = {
      value = jsonencode({
        Environment = "production"
        ManagedBy   = "terraform"
        Team        = "platform"
      })
      category    = "terraform"
      description = "Common tags for resources"
      hcl         = true
    }
    allowed_cidrs = {
      value = jsonencode([
        "10.0.0.0/8",
        "172.16.0.0/12"
      ])
      category = "terraform"
      hcl      = true
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the variable set | `string` | n/a | yes |
| description | A description of the variable set | `string` | `null` | no |
| global | Apply to all workspaces in the organization | `bool` | `false` | no |
| priority | Prevent variables from being overwritten | `bool` | `false` | no |
| variables | Map of variables to create | `map(object)` | `{}` | no |
| workspace_ids_map | Map of workspace IDs to apply to (key = static label, value = workspace ID) | `map(string)` | `{}` | no |
| project_ids_map | Map of project IDs to apply to (key = static label, value = project ID) | `map(string)` | `{}` | no |

> **Note:** Map inputs (`workspace_ids_map` / `project_ids_map`) are required instead of sets so that Terraform can determine stable `for_each` keys at plan time, even when the IDs are unknown until apply (e.g. when projects or workspaces are created in the same run).

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the variable set |
| name | The name of the variable set |
| organization | The organization name |
| description | The variable set description |
| global | Whether the variable set is global |
| priority | Whether the variable set has priority |

## Variable Categories

- `terraform`: Terraform input variables (accessible as `var.name`)
- `env`: Environment variables (accessible as shell environment variables)

## Best Practices

1. **Use Global Variable Sets Sparingly**: Only for truly universal values like organization name or default tags
2. **Project-Scoped for Common Config**: Use project-scoped variable sets for values shared across related workspaces
3. **Workspace-Scoped for Specific Needs**: Use workspace-scoped for credentials or workspace-specific configuration
4. **Priority for Credentials**: Set `priority = true` for credential variable sets to prevent accidental overwriting
5. **Sensitive Variables**: Always mark credentials and secrets as `sensitive = true`
6. **HCL for Complex Types**: Use `hcl = true` for maps, lists, and objects
7. **Clear Naming**: Use descriptive names that indicate the scope and purpose (e.g., "aws-prod-credentials", "global-tags")
8. **Static Map Keys**: Use meaningful, static keys in `workspace_ids_map` and `project_ids_map` (e.g., `prod`, `staging`) so Terraform can plan correctly when IDs are only known at apply time

## Integration with Other Modules

```hcl
# Create project
module "project" {
  source = "./project"

  organization = "my-org"
  name         = "my-project"
}

# Create workspaces
module "workspace_prod" {
  source = "./workspace"

  organization = "my-org"
  name         = "app-prod"
  project_id   = module.project.id
}

module "workspace_staging" {
  source = "./workspace"

  organization = "my-org"
  name         = "app-staging"
  project_id   = module.project.id
}

# Apply variable set to project (affects all workspaces in project)
module "project_vars" {
  source = "./variable-set"

  organization = "my-org"
  name         = "project-common"

  project_ids_map = {
    my_project = module.project.id
  }

  variables = {
    project_name = {
      value    = "my-project"
      category = "terraform"
    }
  }
}

# Apply variable set to specific workspaces
module "prod_vars" {
  source = "./variable-set"

  organization = "my-org"
  name         = "production-config"

  workspace_ids_map = {
    prod = module.workspace_prod.id
  }

  variables = {
    environment = {
      value    = "production"
      category = "terraform"
    }
  }
}
```
