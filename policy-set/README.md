# Terraform Enterprise Policy Set Module

This module manages Terraform Enterprise (TFE) policy sets, including policy attachments and exclusions for workspaces and projects.

## Features

- Create and configure TFE policy sets (Sentinel or OPA)
- Attach policy sets to specific workspaces
- Attach policy sets to specific projects
- Configure global policy sets with workspace/project exclusions
- Support for VCS-backed policy sets or local (non-VCS) policies
- Configurable policy enforcement and overrides

## Usage

### Basic Policy Set

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "security-policies"
  description  = "Security and compliance policies"
  organization = "my-organization"
  kind         = "sentinel"
}
```

### Policy Set with Workspace Attachments

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "dev-policies"
  organization = "my-organization"
  
  workspace_ids = {
    dev     = "ws-abc123"
    staging = "ws-def456"
    prod    = "ws-ghi789"
  }
}
```

### Policy Set with Project Attachments

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "project-policies"
  organization = "my-organization"
  
  project_ids = {
    platform = "prj-abc123"
    apps     = "prj-def456"
  }
}
```

### Global Policy Set with Exclusions

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "global-security-policies"
  description  = "Organization-wide security policies"
  organization = "my-organization"
  global       = true
  
  # Exclude specific workspaces (e.g., sandbox, testing)
  workspace_exclusion_ids = {
    sandbox = "ws-sandbox123"
    testing = "ws-testing456"
  }
  
  # Exclude specific projects (e.g., experimental projects)
  project_exclusion_ids = {
    experimental = "prj-experimental789"
  }
}
```

### VCS-Backed Policy Set

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "vcs-policies"
  organization = "my-organization"
  
  vcs_repo = {
    identifier         = "my-org/policy-repo"
    branch             = "main"
    ingress_submodules = false
    oauth_token_id     = "ot-abc123"
  }
  
  policies_path       = "policies/sentinel"
  policy_tool_version = "0.21.1"
}
```

### Policy Set with Local (non-VCS) Policies

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "local-policies"
  organization = "my-organization"
  kind         = "sentinel"

  policies = {
    require-tags = {
      description       = "Require tags on all resources"
      policy_path       = "${path.module}/policies/require-tags.sentinel"
      enforcement_level = "soft-mandatory"
    }
  }
}
```

### OPA Policy Set with Agent Execution

```hcl
module "policy_set" {
  source = "./policy-set"

  name         = "opa-policies"
  organization = "my-organization"
  kind         = "opa"
  agent_enabled = true
  overridable   = true
  
  workspace_ids = { primary = "ws-abc123" }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| tfe | >= 0.76.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the policy set | `string` | n/a | yes |
| organization | Name of the organization | `string` | n/a | yes |
| description | A description of the policy set's scope or purpose | `string` | `null` | no |
| global | Whether policies in this set apply to all workspaces | `bool` | `false` | no |
| kind | The policy-as-code framework (sentinel or opa) | `string` | `"sentinel"` | no |
| policies | Map of non VCS-managed policies to create and attach (key = policy name). Use only if no VCS integration is available | `map(object)` | `{}` | no |
| policies_path | Sub-path within VCS repository to crawl for policies | `string` | `null` | no |
| policy_tool_version | Version of the policy-as-code framework | `string` | `null` | no |
| workspace_ids | A map of workspace IDs to attach to the policy set | `map(string)` | `{}` | no |
| project_ids | A map of project IDs to attach to the policy set | `map(string)` | `{}` | no |
| workspace_exclusion_ids | A map of workspace IDs to exclude (only with global=true) | `map(string)` | `{}` | no |
| project_exclusion_ids | A map of project IDs to exclude (only with global=true) | `map(string)` | `{}` | no |
| vcs_repo | Settings for the policy set's VCS repository | `object` | `null` | no |
| agent_enabled | Whether the policy set is executed by HCPTF agents | `bool` | `false` | no |
| overridable | Whether the policy set is overridable | `bool` | `false` | no |
| slug | Settings for the policy set's slug | `any` | `null` | no |

### VCS Repository Object

The `vcs_repo` variable accepts an object with the following attributes:

```hcl
{
  identifier                 = string           # VCS repository identifier (e.g., "org/repo")
  branch                     = optional(string) # VCS branch (defaults to repository default)
  ingress_submodules         = optional(bool)   # Whether to include submodules
  oauth_token_id             = optional(string) # OAuth token ID for VCS authentication
  github_app_installation_id = optional(string) # GitHub App installation ID
}
```

### Policies Object

The `policies` variable creates `tfe_policy` resources from local files and attaches them to the policy set. Use it only when no VCS integration is available:

```hcl
{
  description       = optional(string)
  policy_path       = string # Path to a local, existing policy file
  enforcement_level = string # sentinel: advisory | soft-mandatory | hard-mandatory; opa: advisory | mandatory
}
```

Policy names (map keys) may only contain letters, numbers, dashes and underscores.

## Outputs

| Name | Description |
|------|-------------|
| policy_set_id | The ID of the policy set |
| policy_set_name | The name of the policy set |
| policy_set_workspace_ids | The IDs of the workspace policy set attachments |
| policy_set_project_ids | The IDs of the project policy set attachments |
| policy_set_workspace_exclusion_ids | The IDs of the workspace/s excluded from the policy set |
| policy_set_project_exclusion_ids | The IDs of the project/s excluded from the policy set |
| policy_set_vcs_repo | The VCS repository settings for the policy set |

## Important Notes

### Exclusions

- Workspace and project exclusions only work when `global = true`
- Exclusions are useful for applying policies broadly while making specific exceptions
- Common use cases include excluding sandbox, testing, or experimental workspaces/projects

### Policy Frameworks

- `sentinel`: HashiCorp's policy-as-code framework (default)
- `opa`: Open Policy Agent framework

### Attachments vs Global

- Use `workspace_ids` or `project_ids` for explicit attachments to specific resources
- Use `global = true` to apply policies to all workspaces in the organization
- Combine `global = true` with exclusions for "apply to all except" scenarios

## Examples

### Complete Example with All Features

```hcl
module "comprehensive_policy_set" {
  source = "./policy-set"

  name         = "comprehensive-policies"
  description  = "Complete policy set with all features"
  organization = "my-organization"
  global       = true
  kind         = "sentinel"
  
  # VCS configuration
  vcs_repo = {
    identifier         = "my-org/sentinel-policies"
    branch             = "production"
    ingress_submodules = false
    oauth_token_id     = "ot-xyz789"
  }
  
  policies_path       = "policies"
  policy_tool_version = "0.21.1"
  
  # Execution settings
  agent_enabled = false
  overridable   = true
  
  # Exclusions for global policy
  workspace_exclusion_ids = {
    sandbox = "ws-sandbox001"
    testing = "ws-testing002"
  }
  
  project_exclusion_ids = {
    experimental = "prj-experimental003"
  }
}
```
