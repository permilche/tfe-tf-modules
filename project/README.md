# TFE Project Module

This module creates a Terraform Enterprise/HCP Terraform project with optional team access configurations.

## Features

- Creates a TFE project
- Configures team access with granular permissions
- Supports custom project and workspace access levels

## Usage

```hcl
module "project" {
  source = "./project"

  organization = "my-org"
  name         = "my-project"
  description  = "Project for application infrastructure"

  team_access = {
    developers = {
      team_id = module.team_developers.id
      access  = "write"
    }
    admins = {
      team_id = module.team_admins.id
      access  = "admin"
    }
    viewers = {
      team_id = module.team_viewers.id
      access  = "custom"
      workspace_access = {
        runs           = "read"
        state_versions = "read"
        variables      = "none"
      }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the project | `string` | n/a | yes |
| description | A description for the project | `string` | `null` | no |
| team_access | Map of team access configurations | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the project |
| name | The name of the project |
| organization | The organization name |
| description | The project description |

## Team Access Levels

- `read`: Read-only access to the project
- `write`: Write access to workspaces
- `maintain`: Maintain access with additional permissions
- `admin`: Full administrative access
- `custom`: Custom permissions defined via `project_access` and `workspace_access`

### Project Access (project_access)

When using `access = "custom"`, you can define granular project-level permissions:

- `settings`: Permission for project settings. Valid values: `read` (default), `update`, `delete`
- `teams`: Permission for project teams. Valid values: `none` (default), `read`, `manage`
- `variable_sets`: Permission for project variable sets. Valid values: `none` (default), `read`, `write`

### Workspace Access (workspace_access)

When using `access = "custom"`, you can define granular workspace-level permissions:

- `create`: Permission to create workspaces in the project. Valid values: `true`, `false` (default)
- `delete`: Permission to delete workspaces. Valid values: `true`, `false` (default)
- `locking`: Permission to manually lock/unlock workspaces. Valid values: `true`, `false` (default)
- `move`: Permission to move workspaces into/out of the project. Valid values: `true`, `false` (default)
- `policy_overrides`: Permission to override soft-mandatory policy evaluations. Valid values: `true`, `false` (default)
- `run_tasks`: Permission to manage run tasks within workspaces. Valid values: `true`, `false` (default)
- `runs`: Permission for workspace runs. Valid values: `read` (default), `plan`, `apply`
- `sentinel_mocks`: Permission for Sentinel mocks. Valid values: `none` (default), `read`
- `state_versions`: Permission for state versions. Valid values: `none` (default), `read-outputs`, `read`, `write`
- `variables`: Permission for workspace variables. Valid values: `none` (default), `read`, `write`

### Example with Custom Permissions

```hcl
team_access = {
  custom_team = {
    team_id = module.team_custom.id
    access  = "custom"
    project_access = {
      settings      = "update"
      teams         = "read"
      variable_sets = "write"
    }
    workspace_access = {
      create           = true
      delete           = false
      locking          = true
      move             = true
      policy_overrides = false
      run_tasks        = true
      runs             = "apply"
      sentinel_mocks   = "read"
      state_versions   = "read"
      variables        = "write"
    }
  }
}
```
