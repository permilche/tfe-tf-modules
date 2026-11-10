# TFE Team Module

This module creates a Terraform Enterprise/HCP Terraform team with organization-level permissions and member management.

> **Note**: This module is for creating **non-SCIM managed teams** (manually managed teams or teams with SSO mapping via `sso_team_id`). 
> 
> For **SCIM-managed teams** that are automatically synchronized from your Identity Provider (IdP), use the [saml-sso-and-scim](../saml-sso-and-scim) module instead. SCIM teams are created and managed through the SCIM integration and should not be created manually.

## Features

- Creates a TFE team (non-SCIM managed)
- Configures organization-level access permissions
- Manages team membership manually
- Supports SSO team mapping via `sso_team_id` (for SSO without SCIM)

## Usage

### Basic Team

```hcl
module "team_developers" {
  source = "./team"

  organization = "my-org"
  name         = "developers"
  visibility   = "organization"
}
```

### Team with Organization Access

```hcl
module "team_admins" {
  source = "./team"

  organization = "my-org"
  name         = "admins"
  visibility   = "organization"

  organization_access = {
    read_workspaces   = true
    read_projects     = true
    manage_workspaces = true
    manage_projects   = true
    manage_vcs_settings = true
  }
}
```

### Team with SSO Mapping (SCIM)

```hcl
module "team_platform" {
  source = "./team"

  organization = "my-org"
  name         = "platform-team"
  visibility   = "organization"
  
  # Azure AD group ID or other IdP group identifier
  sso_team_id = "12345678-1234-1234-1234-123456789abc"

  organization_access = {
    read_workspaces     = true
    read_projects       = true
    manage_run_tasks    = true
    manage_providers    = true
    manage_modules      = true
  }
}
```

### Team with Members

```hcl
data "tfe_organization_membership" "users" {
  for_each = toset(["user1@example.com", "user2@example.com"])
  
  organization = "my-org"
  email        = each.value
}

module "team_ops" {
  source = "./team"

  organization = "my-org"
  name         = "operations"

  organization_member_ids = [
    for membership in data.tfe_organization_membership.users : membership.id
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the team | `string` | n/a | yes |
| visibility | Visibility of the team (secret, organization) | `string` | `"organization"` | no |
| sso_team_id | SSO Team ID from identity provider | `string` | `null` | no |
| organization_access | Organization-level access permissions | `object` | `null` | no |
| organization_member_ids | Set of organization membership IDs | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the team |
| name | The name of the team |
| organization | The organization name |
| visibility | The visibility of the team |
| sso_team_id | The SSO Team ID |

## Organization Access Permissions

When `organization_access` is configured, you can grant the following permissions:

- `access_secret_teams`: Allow members access to secret teams up to the level of permissions granted by their team permissions setting
- `delegate_policy_overrides`: Allow members to override failed policy evaluations on projects and workspaces they manage
- `manage_agent_pools`: Create, edit, and delete agent pools
- `manage_membership`: Add/remove users from the organization and visible teams
- `manage_modules`: Publish and delete modules in the private registry
- `manage_organization_access`: Update organization access settings of teams
- `manage_policies`: Create, edit, and delete Sentinel policies
- `manage_policy_overrides`: Override soft-mandatory policy checks
- `manage_projects`: Create and administrate all projects (requires `manage_workspaces`)
- `manage_providers`: Publish and delete providers in the private registry
- `manage_run_tasks`: Create, edit, and delete run tasks
- `manage_teams`: Create, update, and delete teams
- `manage_vcs_settings`: Manage VCS providers and SSH keys
- `manage_workspaces`: Create and administrate all workspaces
- `read_projects`: View all projects (requires `read_workspaces`)
- `read_workspaces`: View all workspaces

**Note**: Some permissions have dependencies:
- `manage_projects` requires `manage_workspaces` to be set to `true`
- `read_projects` requires `read_workspaces` to be set to `true`

## SSO/SCIM Integration

When using SSO with SCIM provisioning:

1. Set `sso_team_id` to the group ID from your identity provider (e.g., Azure AD group object ID)
2. Members will be automatically synced from the IdP
3. Do NOT use `organization_member_ids` when using SCIM, members are managed by the IdP
4. The team name in TFE should match the group name in your IdP for clarity

**Important**: If you're using SCIM, team membership is managed by your identity provider. Adding members via `organization_member_ids` may cause conflicts.
