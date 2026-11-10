# TFE Workspace Module

This module creates a Terraform Enterprise/HCP Terraform workspace with comprehensive configuration options including VCS integration, team access, variables, run triggers, and notifications.

## Features

- Creates a TFE workspace with full configuration
- Manages workspace settings (execution mode, agent pool) via separate resource
- VCS repository integration (GitHub, GitLab, Bitbucket, etc.)
- Team access management with granular permissions
- Workspace variables (Terraform and environment)
- Run triggers from other workspaces
- Notification configurations (Slack, email, webhooks, Microsoft Teams)
- Workspace run task attachments (by task ID or name)
- Optional SSH key association (`ssh_key_id`)
- Agent pool assignment for agent execution mode

## Usage

### Basic Workspace

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  description  = "Production infrastructure for my-app"
  project_id   = module.project.id
}
```

### Workspace with VCS Integration (GitHub/GitLab/Bitbucket - Automatic)

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  vcs_repo = {
    vcs_provider     = "github"  # or "gitlab", "bitbucket"
    vcs_organization = "my-org"
    repository       = "my-app-infrastructure"
    branch           = "main"
    oauth_token_id   = module.vcs_oauth.oauth_token_id
  }

  working_directory = "terraform/production"
  terraform_version = "1.5.0"
  auto_apply        = true
}
```

### Workspace with VCS Integration (Azure DevOps - Automatic)

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  vcs_repo = {
    vcs_provider     = "azure_devops"
    vcs_organization = "my-ado-org"
    vcs_project      = "my-ado-project"
    repository       = "my-app-infrastructure"
    branch           = "main"
    oauth_token_id   = module.vcs_oauth.oauth_token_id
  }

  working_directory = "terraform/production"
  terraform_version = "1.5.0"
  auto_apply        = true
}
```

### Workspace with VCS Integration (Manual Identifier Override)

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  vcs_repo = {
    identifier     = "my-org/my-app-infrastructure"  # Manual override
    branch         = "main"
    oauth_token_id = module.vcs_oauth.oauth_token_id
  }

  working_directory = "terraform/production"
  terraform_version = "1.5.0"
  auto_apply        = true
}
```

### Workspace with Team Access and Variables

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  team_access = {
    developers = {
      team_id = module.team_developers.id
      access  = "write"
    }
    operators = {
      team_id = module.team_operators.id
      access  = "custom"
      permissions = {
        runs              = "apply"
        variables         = "write"
        state_versions    = "read"
        sentinel_mocks    = "none"
        workspace_locking = true
        run_tasks         = false
      }
    }
  }

  variables = {
    environment = {
      value       = "production"
      category    = "terraform"
      description = "Environment name"
    }
    aws_region = {
      value    = "us-east-1"
      category = "terraform"
      hcl      = false
    }
    api_key = {
      value     = var.api_key
      category  = "env"
      sensitive = true
    }
  }
}
```

### Workspace with Notifications and Run Triggers

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  notification_configurations = {
    slack_notifications = {
      destination_type = "slack"
      url              = var.slack_webhook_url
      triggers         = ["run:created", "run:planning", "run:errored", "run:completed"]
    }
    email_notifications = {
      destination_type = "email"
      email_addresses  = ["ops-team@example.com"]
      triggers         = ["run:errored"]
    }
  }

  run_trigger_source_workspace_ids = [
    module.workspace_shared.id,
    module.workspace_networking.id


### Workspace with Run Tasks (Using task_id)

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  workspace_run_tasks = {
    security_scan = {
      task_id           = module.run_task_security.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
    cost_estimation = {
      task_id           = module.run_task_cost.id
      enforcement_level = "advisory"
      stage             = "pre_apply"
    }
    policy_check = {
      task_id           = module.run_task_policy.id
      enforcement_level = "mandatory"
      stage             = "pre_plan"
    }
  }
}
```

### Workspace with Run Tasks (Using task_name)

```hcl
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "my-app-prod"
  project_id   = module.project.id

  workspace_run_tasks = {
    security_scan = {
      task_name         = "snyk-security-scan"
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
    cost_estimation = {
      task_name         = "infracost-estimation"
      enforcement_level = "advisory"
      stage             = "pre_apply"
    }
    policy_check = {
      task_name         = "custom-compliance-check"
      enforcement_level = "mandatory"
      stage             = "pre_plan"
    }
  }
}
```

  ]
}
```

### Workspace with Agent Execution

```hcl
module "workspace" {
  source = "./workspace"

  organization   = "my-org"
  name           = "my-app-private"
  project_id     = module.project.id
  execution_mode = "agent"
  agent_pool_id  = module.agent_pool.id
}
```

### Workspace with Remote State Management

```hcl
# Example 1: Allow all workspaces in organization to access state
module "workspace_shared" {
  source = "./workspace"

  organization        = "my-org"
  name                = "shared-infrastructure"
  project_id          = module.project.id
  global_remote_state = true
}

# Example 2: Allow only workspaces in the same project to access state
module "workspace_project" {
  source = "./workspace"

  organization         = "my-org"
  name                 = "project-shared-resources"
  project_id           = module.project.id
  project_remote_state = true
}

# Example 3: Explicit remote state consumers (recommended for security)
module "workspace_restricted" {
  source = "./workspace"

  organization              = "my-org"
  name                      = "production-database"
  project_id                = module.project.id
  global_remote_state       = false
  project_remote_state      = false
  remote_state_consumer_ids = [
    module.workspace_app.id,
    module.workspace_api.id
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the workspace | `string` | n/a | yes |
| description | A description for the workspace | `string` | `null` | no |
| project_id | ID of the project | `string` | `null` | no |
| execution_mode | Execution mode (remote, local, agent). Managed via tfe_workspace_settings | `string` | `"remote"` | no |
| agent_pool_id | Agent pool ID (required for agent mode). Managed via tfe_workspace_settings | `string` | `null` | no |
| global_remote_state | Allow all workspaces in org to access state. Managed via tfe_workspace_settings | `bool` | `null` | no |
| project_remote_state | Allow all workspaces in project to access state. Managed via tfe_workspace_settings | `bool` | `null` | no |
| remote_state_consumer_ids | Explicit workspace IDs that can access state. Managed via tfe_workspace_settings | `set(string)` | `[]` | no |
| auto_apply | Automatically apply changes. Managed via tfe_workspace_settings | `bool` | `false` | no |
| assessments_enabled | Enable health assessments. Managed via tfe_workspace_settings | `bool` | `false` | no |
| allow_destroy_plan | Allow destroy plans | `bool` | `true` | no |
| auto_apply_run_trigger | Auto-apply for run triggers | `bool` | `false` | no |
| file_triggers_enabled | Filter runs based on changed files | `bool` | `true` | no |
| queue_all_runs | Queue runs immediately after creation | `bool` | `true` | no |
| speculative_enabled | Allow speculative plans | `bool` | `true` | no |
| terraform_version | Terraform version to use | `string` | `null` | no |
| working_directory | Working directory path | `string` | `null` | no |
| trigger_prefixes | Paths to track for changes | `list(string)` | `null` | no |
| trigger_patterns | Glob patterns for file monitoring | `list(string)` | `null` | no |
| vcs_repo | VCS repository settings. Supports automatic identifier construction based on provider or manual override. See VCS Configuration section below. | `object` | `null` | no |
| tag_names | List of tags | `list(string)` | `[]` | no |
| tags | Map of key-value tags. Managed via tfe_workspace_settings | `map(string)` | `{}` | no |
| structured_run_output_enabled | Enable structured run output | `bool` | `true` | no |
| team_access | Team access configurations | `map(object)` | `{}` | no |
| variables | Workspace variables | `map(object)` | `{}` | no |
| run_trigger_source_workspace_ids | Source workspace IDs for run triggers | `set(string)` | `[]` | no |
| workspace_run_tasks | Workspace run task configurations | `map(object)` | `{}` | no |
| notification_configurations | Notification configurations | `map(object)` | `{}` | no |
| ssh_key_id | ID of the SSH key to associate with the workspace for Git access (see the [ssh-key](../ssh-key) module) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the workspace |
| name | The name of the workspace |
| organization | The organization name |
| project_id | The ID of the project |
| html_url | The URL to the workspace in the UI |
| resource_count | Number of resources managed |
| terraform_version | Terraform version configured |
| execution_mode | The execution mode of the workspace (from workspace_settings) |
| agent_pool_id | The agent pool ID (from workspace_settings) |
| global_remote_state | Whether workspace allows all org workspaces to access its state |
| project_remote_state | Whether workspace allows all project workspaces to access its state |
| remote_state_consumer_ids | Set of workspace IDs that can access this workspace's state |
| auto_apply | Whether to automatically apply changes when a plan is successful |
| assessments_enabled | Whether to regularly run health assessments |
| description | The description of the workspace |
| tags | The tags configured for the workspace |
| effective_tags | All tags including inherited tags from the project |
| vcs_repo | VCS repository configuration |
| workspace_run_task_ids | Map of workspace run task IDs |

## VCS Configuration

The module supports automatic VCS identifier construction based on the provider type, eliminating the need to manually format identifiers for different VCS providers.

### Automatic Identifier Construction

**GitHub, GitLab, Bitbucket:**
```hcl
vcs_repo = {
  vcs_provider     = "github"  # or "gitlab", "bitbucket"
  vcs_organization = "my-org"
  repository       = "my-repo"
  # Automatically constructs: "my-org/my-repo"
}
```

**Azure DevOps:**
```hcl
vcs_repo = {
  vcs_provider     = "azure_devops"
  vcs_organization = "my-ado-org"
  vcs_project      = "my-ado-project"
  repository       = "my-repo"
  # Automatically constructs: "my-ado-org/my-ado-project/_git/my-repo"
}
```

### Manual Identifier Override

If you prefer to provide the identifier manually or have a custom format:
```hcl
vcs_repo = {
  identifier = "my-org/my-repo"  # Manual override - ignores vcs_provider, vcs_organization, etc.
}
```

### VCS Repository Object Properties

- `vcs_provider` (optional, default: "github"), VCS provider type: "github", "gitlab", "bitbucket", or "azure_devops"
- `vcs_organization` (optional), VCS organization name (required for automatic construction)
- `vcs_project` (optional), Azure DevOps project name (required only for Azure DevOps)
- `repository` (optional), Repository name (required for automatic construction)
- `identifier` (optional), Manual identifier override. If provided, automatic construction is skipped
- `branch` (optional), Repository branch (defaults to repository's default branch)
- `ingress_submodules` (optional), Whether to fetch submodules
- `oauth_token_id` (optional), OAuth token ID for VCS connection
- `github_app_installation_id` (optional), GitHub App installation ID (conflicts with oauth_token_id)
- `tags_regex` (optional), Regular expression to trigger runs for matching Git tags

**Note:** Either provide `identifier` for manual control, or provide `vcs_organization` + `repository` (+ `vcs_project` for Azure DevOps) for automatic construction.

## Architecture

This module creates two main resources:

1. **tfe_workspace**: The main workspace resource with core configuration
2. **tfe_workspace_settings**: Manages execution settings (execution_mode, agent_pool_id, remote state settings)

The separation follows HCP Terraform's resource structure where workspace settings are managed independently from the workspace itself. This allows for better management of deprecated arguments that have been moved to the workspace_settings resource.

### Important Notes

**Deprecated Arguments Migration**: The following arguments were deprecated in `tfe_workspace` and are now managed via `tfe_workspace_settings`:
- `execution_mode`: Now managed in tfe_workspace_settings
- `agent_pool_id`: Now managed in tfe_workspace_settings  
- `global_remote_state`: Now managed in tfe_workspace_settings
- `remote_state_consumer_ids`: Now managed in tfe_workspace_settings
- `operations`: Deprecated, use execution_mode instead

**Properties Managed in tfe_workspace_settings**: To avoid dual management conflicts and follow best practices, this module manages the following properties exclusively in `tfe_workspace_settings`:
- `auto_apply`: Automatically apply changes when a plan is successful
- `assessments_enabled`: Enable health assessments like drift detection
- `description`: Workspace description
- `tags`: Key-value tags for the workspace (note: `tag_names` list is still in tfe_workspace)

**Important**: Do not attempt to manage these properties in both `tfe_workspace` and `tfe_workspace_settings` as it will cause permanent drift.

**Remote State Security**: HashiCorp recommends following the principle of least privilege for remote state access. Instead of using `global_remote_state = true`, explicitly specify which workspaces can access state using `remote_state_consumer_ids` for better security.

## Workspace Run Tasks

Run tasks allow you to integrate external systems into your Terraform workflow at specific stages. You can attach organization-level run tasks to workspaces with configurable enforcement levels and execution stages.

### Parameters

- `task_id` (optional): The ID of the organization run task to attach (reference to module output or resource ID)
- `task_name` (optional): The name of an existing organization run task to lookup and attach
  - **Note**: Specify either `task_id` OR `task_name`, not both
  - Use `task_id` when referencing run tasks created in the same Terraform configuration (via module outputs)
  - Use `task_name` when referencing run tasks created outside Terraform or in separate configurations
- `enforcement_level` (required): Determines how run task results affect the run
  - `advisory`: Results are displayed but don't block the run
  - `mandatory`: Failed results block the run from proceeding
- `stage` (optional, default: `post_plan`): When the run task executes
  - `pre_plan`: Before Terraform plan
  - `post_plan`: After Terraform plan (most common)
  - `pre_apply`: Before Terraform apply
  - `post_apply`: After Terraform apply

### Example Use Cases

**Security Scanning**: Run security checks after planning to identify potential issues before apply
```hcl
workspace_run_tasks = {
  security = {
    task_id           = module.run_task_security.id  # Using module output
    enforcement_level = "mandatory"
    stage             = "post_plan"
  }
}
```

**Cost Estimation**: Estimate infrastructure costs before applying changes
```hcl
workspace_run_tasks = {
  cost = {
    task_name         = "infracost-estimation"  # Using existing run task name
    enforcement_level = "advisory"
    stage             = "pre_apply"
  }
}
```

**Policy Validation**: Validate configurations against organizational policies
```hcl
workspace_run_tasks = {
  policy = {
    task_id           = module.run_task_policy.id
    enforcement_level = "mandatory"
    stage             = "pre_plan"
  }
}
```

**Mixed Approach**: Combine both methods in the same workspace
```hcl
workspace_run_tasks = {
  # Reference run task created in same config via module
  security = {
    task_id           = module.run_task_security.id
    enforcement_level = "mandatory"
    stage             = "post_plan"
  }
  # Reference existing run task by name
  cost = {
    task_name         = "infracost-estimation"
    enforcement_level = "advisory"
    stage             = "post_plan"
  }
  # Reference run task from another Terraform state
  compliance = {
    task_name         = "company-compliance-check"
    enforcement_level = "mandatory"
    stage             = "pre_apply"
  }
}
```

**Note**: Organization run tasks must be created separately (either via the run-task module or directly) before they can be attached to workspaces. Use `task_id` for run tasks in the same configuration, or `task_name` to reference existing run tasks.

## Team Access Levels

- `read`: Read-only access
- `plan`: Can queue plans
- `write`: Can queue plans and applies
- `admin`: Full administrative access
- `custom`: Custom permissions via `permissions` block

## Notification Triggers

- `run:created`: Run is created
- `run:planning`: Run is planning
- `run:needs_attention`: Run needs attention
- `run:applying`: Run is applying
- `run:completed`: Run completed successfully
- `run:errored`: Run encountered an error
- `assessment:drifted`: Drift detected
- `assessment:failed`: Assessment failed
