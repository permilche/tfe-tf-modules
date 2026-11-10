# TFE Organization Settings Module

This module creates and manages Terraform Enterprise/HCP Terraform organizations, including organization-level settings and default workspace configurations.

## Features

- Creates TFE/HCPTF organizations
- Configures organization-level settings (authentication, sessions, cost estimation)
- Sets default execution mode for new workspaces
- Configures default agent pool for agent execution mode (requires a manual change to `main.tf`, see [Agent Pool Requirement](#agent-pool-requirement))
- Manages organization-wide security and compliance settings
- Configures TFE instance-level admin SMTP settings

## Usage

### Create Basic Organization

```hcl
module "organization" {
  source = "./organization-settings"

  organization = "my-org"
  email        = "admin@example.com"
}
```

### Organization with Enhanced Security

```hcl
module "organization" {
  source = "./organization-settings"

  organization             = "my-org"
  email                    = "admin@example.com"
  collaborator_auth_policy = "two_factor_mandatory"
  assessments_enforced     = true
}
```

### Organization with Custom Session Settings

```hcl
module "organization" {
  source = "./organization-settings"

  organization             = "my-org"
  email                    = "admin@example.com"
  session_timeout_minutes  = 480   # 8 hours
  session_remember_minutes = 10080 # 7 days
}
```

### Organization with SMTP Settings

```hcl
module "organization" {
  source = "./organization-settings"

  organization = "my-org"
  email        = "admin@example.com"

  tfe_admin_smtp_settings = {
    host   = "smtp.example.com"
    port   = 587
    sender = "tfe@example.com"
    auth   = "login"

    username            = "smtp-user"
    password_wo         = var.smtp_password
    password_wo_version = 1

    test_email_address = "admin@example.com"
  }
}
```

### Organization with Default Agent Pool

> **Note**: `default_agent_pool_id` is currently commented out in `main.tf` (provider limitation), so it must be uncommented before this example takes effect. See [Agent Pool Requirement](#agent-pool-requirement).

```hcl
# Create default agent pool
module "agent_pool_default" {
  source = "./agent-pool"

  organization        = module.organization.organization_name
  name                = "default-agents"
  organization_scoped = true

  agent_tokens = {
    primary = {
      description = "Primary agent token"
    }
  }
}

# Create organization with agent execution by default
module "organization" {
  source = "./organization-settings"

  organization           = "my-org"
  email                  = "admin@example.com"
  default_execution_mode = "agent"
  default_agent_pool_id  = module.agent_pool_default.id
}
```

### Enterprise Organization with All Features

```hcl
module "organization" {
  source = "./organization-settings"

  organization                                           = "enterprise-org"
  email                                                  = "platform-team@example.com"
  collaborator_auth_policy                               = "two_factor_mandatory"
  cost_estimation_enabled                                = true
  assessments_enforced                                   = true
  aggregated_commit_status_enabled                       = true
  send_passing_statuses_for_untriggered_speculative_plans = true
  allow_force_delete_workspaces                          = false
  session_timeout_minutes                                = 480
  session_remember_minutes                               = 10080
  default_execution_mode                                 = "remote"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| email | Admin email address for the organization | `string` | n/a | yes |
| session_timeout_minutes | Session timeout after inactivity (minutes) | `number` | `20160` (14 days) | no |
| session_remember_minutes | Session expiration (minutes) | `number` | `20160` (14 days) | no |
| collaborator_auth_policy | Authentication policy (password, two_factor_mandatory) | `string` | `"password"` | no |
| cost_estimation_enabled | Enable cost estimation for all workspaces | `bool` | `true` | no |
| owners_team_saml_role_id | SAML role ID for the owners team | `string` | `null` | no |
| send_passing_statuses_for_untriggered_speculative_plans | Send VCS status for untriggered speculative plans | `bool` | `false` | no |
| aggregated_commit_status_enabled | Enable aggregated VCS commit status | `bool` | `true` | no |
| assessments_enforced | Enforce health assessments | `bool` | `false` | no |
| allow_force_delete_workspaces | Allow force deletion of workspaces | `bool` | `false` | no |
| default_execution_mode | Default execution mode (remote, local, agent) | `string` | `"remote"` | no |
| default_agent_pool_id | Default agent pool ID (required for agent mode). Currently not passed to the provider. See [Agent Pool Requirement](#agent-pool-requirement) | `string` | `null` | no |
| tfe_admin_smtp_settings | TFE instance admin SMTP configuration object. See [SMTP Settings](#smtp-settings) section for object schema. Marked sensitive. | `object` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| organization | The full organization object |
| organization_name | The organization name |
| organization_id | The organization ID |

## Organization Settings Explained

### Authentication & Security

**collaborator_auth_policy**
- `password`: Standard password authentication (default)
- `two_factor_mandatory`: Requires 2FA for all users (recommended for production)

**assessments_enforced**
- When enabled, enforces health assessments on workspaces
- Helps maintain infrastructure health and compliance

**allow_force_delete_workspaces**
- When disabled (default), prevents accidental workspace deletion
- Recommended to keep disabled for production organizations

### Session Management

**session_timeout_minutes**
- Inactivity timeout before automatic logout
- Default: 20160 minutes (14 days)
- Recommended: 480 minutes (8 hours) for enhanced security

**session_remember_minutes**
- Maximum session duration regardless of activity
- Default: 20160 minutes (14 days)
- Recommended: 10080 minutes (7 days) for enhanced security

### VCS Integration

**aggregated_commit_status_enabled**
- Combines multiple run statuses into single VCS status
- Recommended: `true` for cleaner VCS integration

**send_passing_statuses_for_untriggered_speculative_plans**
- Sends passing status for speculative plans not triggered by VCS
- Recommended: `false` to avoid confusion

### Cost Management

**cost_estimation_enabled**
- Enables cost estimation for all workspaces
- Provides visibility into infrastructure costs
- Recommended: `true` for cost awareness

## Execution Modes

### remote (Default)
- Terraform runs execute on TFE's infrastructure
- No local setup required
- Managed by HashiCorp
- Best for most use cases

### local
- Terraform runs execute on local machine or CI/CD runner
- State stored in TFE
- Useful for testing or specific workflows
- Requires local Terraform installation

### agent
- Terraform runs execute on self-hosted agents
- Required for private network access
- Custom tools and dependencies
- Requires agent pool configuration

## SMTP Settings

The `tfe_admin_smtp_settings` variable configures the `tfe_admin_smtp_settings` resource, which is a TFE instance-level setting available only on self-hosted Terraform Enterprise. It has no effect on HCP Terraform.

The resource is created only when `tfe_admin_smtp_settings` is not `null`.

### Object Schema

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| host | SMTP server hostname | `string` | n/a | yes |
| sender | Sender email address | `string` | n/a | yes |
| enabled | Whether SMTP is enabled | `bool` | `true` | no |
| port | SMTP server port | `number` | `587` | no |
| auth | Authentication method (`none`, `plain`, `login`, `cram-md5`) | `string` | `"none"` | no |
| username | SMTP username | `string` | `null` | no |
| password_wo | SMTP password (write-only) | `string` | `null` | no |
| password_wo_version | Increment to force password update | `number` | `null` | no |
| test_email_address | Address used to send a test email on apply | `string` | `null` | no |

The entire variable is marked `sensitive = true` to prevent credential exposure in plan output.

`password_wo` is a write-only attribute, which requires Terraform 1.11 or later.


## Important Notes

### Organization Creation

- This module **creates** the organization resource
- Organization name must be unique across TFE/HCPTF
- Email is required for organization creation
- Once created, organization name cannot be changed

### Default Settings Scope

- Default execution mode applies to **new workspaces only**
- Existing workspaces are not affected
- Individual workspaces can override these defaults

### Agent Pool Requirement

When using `agent` execution mode:
- `default_agent_pool_id` is **required**
- Agent pool must be organization-scoped
- Agents must be deployed and running

**⚠️ Known Limitation, Manual Configuration Required:**

The TFE provider has a strict validation requirement: `default_agent_pool_id` can ONLY be set when `default_execution_mode = "agent"`. The provider validation fails even when using conditional logic or setting the value to `null` through variable interpolation.

**Current Implementation:**
- The `default_agent_pool_id` argument is **commented out** in the module's `main.tf`
- The module works out-of-the-box for `remote` and `local` execution modes
- For `agent` execution mode, **manual modification is required**

**To Enable Agent Mode:**
1. Open `organization-settings/main.tf`
2. Locate the `tfe_organization_default_settings` resource
3. Uncomment the `default_agent_pool_id` line
4. Set `default_execution_mode = "agent"` when calling the module
5. Provide a valid `default_agent_pool_id`

**Example modification in main.tf:**
```hcl
resource "tfe_organization_default_settings" "this" {
  organization           = tfe_organization.this.name
  default_execution_mode = var.default_execution_mode
  default_agent_pool_id  = var.default_agent_pool_id  # Uncomment this line
}
```

This limitation is documented in the [TFE provider documentation](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization_default_settings#argument-reference): "This value must not be provided if default_execution_mode is set to any other value."

## Use Cases

### Startup Organization

```hcl
module "organization" {
  source = "./organization-settings"

  organization = "startup-co"
  email        = "devops@startup.com"
  
  # Keep defaults simple
  default_execution_mode = "remote"
  cost_estimation_enabled = true
}
```

### Enterprise Organization with Security

```hcl
module "organization" {
  source = "./organization-settings"

  organization             = "enterprise-corp"
  email                    = "platform@enterprise.com"
  collaborator_auth_policy = "two_factor_mandatory"
  assessments_enforced     = true
  session_timeout_minutes  = 480  # 8 hours
  allow_force_delete_workspaces = false
  
  default_execution_mode = "remote"
  cost_estimation_enabled = true
}
```

### Private Network Organization

```hcl
# Create agent pool first
module "agent_pool" {
  source = "./agent-pool"

  organization        = "private-org"
  name                = "datacenter-agents"
  organization_scoped = true

  agent_tokens = {
    primary = {
      description = "Primary datacenter agent"
    }
  }
}

# Create organization with agent default
module "organization" {
  source = "./organization-settings"

  organization           = "private-org"
  email                  = "ops@private.com"
  default_execution_mode = "agent"
  default_agent_pool_id  = module.agent_pool.id
}
```

### Development Organization

```hcl
module "organization" {
  source = "./organization-settings"

  organization           = "dev-org"
  email                  = "dev@example.com"
  default_execution_mode = "local"
  
  # Relaxed settings for development
  collaborator_auth_policy = "password"
  assessments_enforced     = false
}
```

## Best Practices

1. **Enable 2FA**: Use `two_factor_mandatory` for production organizations
2. **Shorter Sessions**: Use 8-hour timeout for enhanced security
3. **Cost Estimation**: Enable for visibility into infrastructure costs
4. **Health Assessments**: Enable for production organizations
5. **Prevent Force Delete**: Keep disabled to prevent accidental deletions
6. **Use Remote by Default**: Unless you have specific requirements
7. **Document Settings**: Clearly document why specific settings are chosen

## Workspace Override

Individual workspaces can override organization defaults:

```hcl
# Organization default is remote
module "organization" {
  source = "./organization-settings"

  organization           = "my-org"
  email                  = "admin@example.com"
  default_execution_mode = "remote"
}

# But this workspace uses agent mode
module "workspace_private" {
  source = "./workspace"

  organization   = module.organization.organization_name
  name           = "private-infrastructure"
  execution_mode = "agent"  # Overrides organization default
  agent_pool_id  = module.agent_pool_private.id
}
```

## Integration with Other Modules

```hcl
# Create organization
module "organization" {
  source = "./organization-settings"

  organization             = "my-org"
  email                    = "admin@example.com"
  collaborator_auth_policy = "two_factor_mandatory"
  cost_estimation_enabled  = true
}

# Use organization in other modules
module "project" {
  source = "./project"

  organization = module.organization.organization_name
  name         = "platform"
}

module "workspace" {
  source = "./workspace"

  organization = module.organization.organization_name
  name         = "production"
  project_id   = module.project.id
}

module "team" {
  source = "./team"

  organization = module.organization.organization_name
  name         = "developers"
}
```

## Accessing Full Organization Object

The module outputs the full organization object for advanced use cases:

```hcl
module "organization" {
  source = "./organization-settings"

  organization = "my-org"
  email        = "admin@example.com"
}

# Access full organization object
output "org_details" {
  value = module.organization.organization
}

# Access specific attributes
output "org_name" {
  value = module.organization.organization_name
}

output "org_id" {
  value = module.organization.organization_id
}
```

## Troubleshooting

### Organization Already Exists

If you get an error that the organization already exists:
- This module creates the organization
- If organization exists, import it: `terraform import module.organization.tfe_organization.this <org-name>`
- Or use data source instead of this module

### Agent Pool Not Found

If you get an error about agent pool not found:
1. Verify agent pool exists and is organization-scoped
2. Ensure agent pool ID is correct
3. Check that agents are deployed and running
4. Create agent pool before organization or use `depends_on`

### Permission Errors

Ensure you have:
- Organization owner or admin permissions
- Ability to create organizations (for TFE)
- Valid HCPTF/TFE token with appropriate permissions

### Email Validation

- Email must be valid format
- Email is used for organization admin contact
- Cannot be changed after organization creation

## Security Recommendations

### Production Organizations

```hcl
module "organization" {
  source = "./organization-settings"

  organization             = "production-org"
  email                    = "security@example.com"
  
  # Security settings
  collaborator_auth_policy = "two_factor_mandatory"
  assessments_enforced     = true
  allow_force_delete_workspaces = false
  
  # Session settings
  session_timeout_minutes  = 480   # 8 hours
  session_remember_minutes = 10080 # 7 days
  
  # Features
  cost_estimation_enabled = true
  aggregated_commit_status_enabled = true
}
```

### Development Organizations

```hcl
module "organization" {
  source = "./organization-settings"

  organization = "dev-org"
  email        = "dev@example.com"
  
  # Relaxed for development
  collaborator_auth_policy = "password"
  assessments_enforced     = false
  allow_force_delete_workspaces = true
  
  # Standard features
  cost_estimation_enabled = true
}
```

## Comparison: Authentication Policies

| Policy | Security Level | User Experience | Best For |
|--------|---------------|-----------------|----------|
| password | Basic | Simple | Development |
| two_factor_mandatory | High | Requires 2FA setup | Production |

## Additional Resources

- [TFE Organizations](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/organizations)
- [TFE Execution Modes](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings#execution-mode)
- [Agent Pools](https://developer.hashicorp.com/terraform/cloud-docs/agents)
- [Cost Estimation](https://developer.hashicorp.com/terraform/cloud-docs/cost-estimation)