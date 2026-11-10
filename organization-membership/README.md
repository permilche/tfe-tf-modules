# TFE Organization Membership Module

This module manages a single user's membership in a Terraform Enterprise/HCP Terraform organization, including the invitation and optional team assignments.

## Features

- Invites a user to an organization
- Assigns the user to one or more teams
- Ignores email changes after initial invitation (email updates must be made by the user themselves)

## Usage

### Basic User Invitation

```hcl
module "org_member_alice" {
  source = "./organization-membership"

  organization = "my-org"

  member = {
    email = "alice@example.com"
  }
}
```

### User with Team Assignments

```hcl
module "org_member_alice" {
  source = "./organization-membership"

  organization = "my-org"

  member = {
    email    = "alice@example.com"
    team_ids = [
      module.team_developers.id,
      module.team_platform.id,
    ]
  }
}
```

### Multiple Members

Call the module once per member:

```hcl
locals {
  members = {
    alice = { email = "alice@example.com", team_ids = [module.team_developers.id] }
    bob   = { email = "bob@example.com",   team_ids = [module.team_ops.id] }
  }
}

module "org_members" {
  for_each = local.members
  source   = "./organization-membership"

  organization = "my-org"
  member       = each.value
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `organization` | Name of the TFE/HCPTF organization | `string` | n/a | yes |
| `member` | Organization member to invite and the team IDs they should be added to | `object({ email = string, team_ids = optional(list(string), []) })` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `membership_id` | Organization membership ID |
| `user_id` | User ID |
| `email` | Member email |
| `team_membership_ids` | Map of team ID to `tfe_team_organization_member` resource ID |

## Important Notes

### Email Changes

After a membership is created, email address changes are **ignored by Terraform**. Only the user themselves can update their email address in TFE/HCPTF. If a user changes their email, update the configuration manually and run `terraform state mv` or `terraform import` as needed.

### SSO/SCIM Considerations

⚠️ **Warning**: If using SSO with SCIM provisioning:
- Do NOT use this module for user management
- Users are automatically provisioned from your identity provider
- Team membership should be managed via SSO team mapping (`sso_team_id`)
- This module is for manual user management only

### Email Requirements

- Users must have a valid email address
- The email must not already belong to an existing member of the organization
- Users will receive an invitation email from TFE/HCPTF

## Requirements

| Name | Version |
|------|---------|
| terraform | `>= 1.0` |
| hashicorp/tfe | `>= 0.79.0` |

## Additional Resources

- [TFE Organization Membership](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/organizations)
- [Team Management](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/teams)
- [SSO Configuration](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/single-sign-on)
