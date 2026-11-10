# Terraform Enterprise/HCP Terraform (TFE/HCPTF) Modules

> **Disclaimer:** this is a personal project and not an official HashiCorp product. It is not officially supported or maintained by HashiCorp, and I share it to help out the community. It comes "as is", without any warranty. There may be errors, and the Terraform, provider or module versions used here may get deprecated or stop working. Please review and test everything outside production before using it, and use it at your own risk. The repository is public and issues and pull requests are welcome, but I review and validate each one myself, so there is no guaranteed response time, no promise to merge, and no support SLA (see [CONTRIBUTING](.github/CONTRIBUTING.md)). All names, IDs and values are examples or placeholders, so never commit credentials. Terraform, HCP Terraform and Terraform Enterprise are trademarks of HashiCorp.

A collection of reusable Terraform modules for managing Terraform Enterprise (TFE) and HCP Terraform (HCPTF) with infrastructure as code. Each module is self-contained, has a single focused responsibility, and ships with its own README documenting inputs, outputs and examples.

## Modules

| Module | Description |
|--------|-------------|
| [`organization-settings`](organization-settings/README.md) | Creates the organization, its defaults (execution mode, sessions, auth policy) and optional admin SMTP settings |
| [`project`](project/README.md) | Projects with team access (including custom project/workspace permissions) |
| [`workspace`](workspace/README.md) | Workspaces with VCS, settings, team access, variables, run triggers, notifications and run tasks |
| [`team`](team/README.md) | Non-SCIM teams with organization access and optional SSO mapping |
| [`team-token`](team-token/README.md) | API tokens for teams (CI/CD automation) |
| [`organization-membership`](organization-membership/README.md) | Invites a user to the organization and assigns teams |
| [`variable-set`](variable-set/README.md) | Variable sets applied globally or to projects/workspaces |
| [`policy-set`](policy-set/README.md) | Sentinel/OPA policy sets with attachments and exclusions |
| [`run-task`](run-task/README.md) | Organization run tasks and workspace associations |
| [`registry-module`](registry-module/README.md) | Private registry modules, tests and no-code provisioning |
| [`vcs-oauth`](vcs-oauth/README.md) | VCS OAuth clients (GitHub, GitLab, Bitbucket, Azure DevOps) |
| [`ssh-key`](ssh-key/README.md) | SSH keys for private Git module sources |
| [`agent-pool`](agent-pool/README.md) | Agent pools and agent tokens for self-hosted agents |
| [`saml-sso-and-scim`](saml-sso-and-scim/README.md) | SAML SSO, SCIM provisioning and SCIM-managed teams |
| [`dynamic-credentials/azure/configuration`](dynamic-credentials/azure/configuration/README.md) | Azure app registration and service principal used for TFE dynamic credentials |
| [`dynamic-credentials/azure/management`](dynamic-credentials/azure/management/README.md) | Federated identity credential for one workspace/run phase |
| ... |

## Repository Structure

```
.
├── agent-pool/
├── dynamic-credentials/
│   └── azure/
│       ├── configuration/
│       └── management/
├── organization-membership/
├── organization-settings/
├── policy-set/
├── project/
├── registry-module/
├── run-task/
├── saml-sso-and-scim/
├── ssh-key/
├── team/
├── team-token/
├── variable-set/
├── vcs-oauth/
└── workspace/
```

Every module follows the same layout:

```
module-name/
├── main.tf           # Resource definitions
├── variables.tf      # Input variables
├── outputs.tf        # Outputs
├── providers.tf      # Provider version constraints
└── README.md         # Module documentation
```

## Requirements

| Component | Version |
|-----------|---------|
| Terraform | `>= 1.0` (`ssh-key` and `organization-settings` use write-only attributes, which need Terraform `>= 1.11`) |
| `hashicorp/tfe` provider | `>= 0.79.0` (`policy-set`, `vcs-oauth` and `saml-sso-and-scim` require `>= 0.76.1`) |
| `hashicorp/azuread` / `hashicorp/azurerm` | `~> 3.9.0` / `~> 4.60.0` (`dynamic-credentials/azure/*` only) |

Credentials for the `tfe` provider (for example `TFE_TOKEN`, `TFE_HOSTNAME`) must be configured by the caller.

## Getting Started

Reference a module from your configuration. The examples in each module README use a relative path (`./<module>`). You can equally use a Git or private registry source and pin a version.

```hcl
module "project" {
  source = "./project"

  organization = "my-org"
  name         = "platform"
  description  = "Platform infrastructure"
}
```

Then run `terraform init`, `terraform plan` and `terraform apply`.

### Example: VCS, project, team, workspace and variable set

```hcl
module "vcs_github" {
  source = "./vcs-oauth"

  organization     = "my-org"
  service_provider = "github"
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  name             = "github"
  oauth_token      = var.github_oauth_token
}

module "project_platform" {
  source = "./project"

  organization = "my-org"
  name         = "platform"
}

module "team_developers" {
  source = "./team"

  organization = "my-org"
  name         = "developers"
}

module "workspace_prod" {
  source = "./workspace"

  organization = "my-org"
  name         = "app-production"
  project_id   = module.project_platform.id

  vcs_repo = {
    vcs_organization = "my-org"
    repository       = "infrastructure"
    branch           = "main"
    oauth_token_id   = module.vcs_github.oauth_token_id
  }

  team_access = {
    developers = {
      team_id = module.team_developers.id
      access  = "write"
    }
  }
}

module "vars_aws" {
  source = "./variable-set"

  organization = "my-org"
  name         = "aws-credentials"
  priority     = true

  project_ids_map = {
    platform = module.project_platform.id
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
  }
}
```

## Architecture

### Why separate modules?

Each module has one clear responsibility. This keeps modules small (typically 1-6 related resources), easy to test, and lets different teams own different parts of the platform.

- **Different lifecycles**: organization settings rarely change, run tasks are added as tools are adopted, workspaces change often.
- **Optional features**: not every organization needs SSO, agent pools, a private registry, etc. Adopt modules incrementally.
- **Smaller blast radius and independent versioning**: a change to one feature does not touch the others.
- **Clear ownership**: for example a platform team owns `organization-settings`/`agent-pool`, an identity team owns `saml-sso-and-scim`, and application teams own `workspace`.

Avoid a monolithic "organization" module: it would mix unrelated resource types, accumulate hundreds of variables and force users to understand features they do not use.

### When to consolidate vs. separate

Put resources in the **same module** when they are tightly coupled (nearly always used together), share a lifecycle and serve the same purpose. The `workspace` module is an example: team access, variables, run triggers, notifications and run task associations all depend on the workspace.

Keep resources in **separate modules** when they are loosely coupled, change at different frequencies, are optional, or are managed by different teams (for example `run-task`, `agent-pool`, `vcs-oauth`, `registry-module`, `saml-sso-and-scim`).

### SCIM and non-SCIM teams

- [`team`](team/README.md) manages **non-SCIM** teams (manually managed, optionally mapped with `sso_team_id`).
- [`saml-sso-and-scim`](saml-sso-and-scim/README.md) manages **SCIM** teams synchronized from the identity provider.

### Module dependencies

```
organization-settings
        │
        ├── vcs-oauth ◄── ssh-key
        │       │
        │       ├── registry-module
        │       └── policy-set
        │
        ├── agent-pool
        ├── saml-sso-and-scim ──► (SCIM teams)
        ├── team ──► organization-membership, team-token
        ├── project ◄── team
        ├── run-task
        └── workspace ◄── project, team, vcs-oauth, agent-pool, ssh-key, run-task
                │
                └── variable-set (applied to projects/workspaces)
```

## Integration Patterns

### Project → workspaces → variable set

```hcl
module "project" {
  source       = "./project"
  organization = "my-org"
  name         = "my-project"
}

module "workspace_1" {
  source       = "./workspace"
  organization = "my-org"
  name         = "workspace-1"
  project_id   = module.project.id
}

module "workspace_2" {
  source       = "./workspace"
  organization = "my-org"
  name         = "workspace-2"
  project_id   = module.project.id
}

# Applies to every workspace in the project
module "vars" {
  source       = "./variable-set"
  organization = "my-org"
  name         = "project-vars"

  project_ids_map = {
    my_project = module.project.id
  }

  variables = {
    environment = {
      value    = "production"
      category = "terraform"
    }
  }
}
```

> `variable-set` uses maps (`project_ids_map`, `workspace_ids_map`) with static keys instead of sets so that Terraform can plan even when the IDs are only known at apply time.

### Teams → project → workspaces

```hcl
module "team_admins" {
  source       = "./team"
  organization = "my-org"
  name         = "admins"
}

module "team_developers" {
  source       = "./team"
  organization = "my-org"
  name         = "developers"
}

module "project" {
  source       = "./project"
  organization = "my-org"
  name         = "my-project"

  team_access = {
    admins = {
      team_id = module.team_admins.id
      access  = "admin"
    }
    developers = {
      team_id = module.team_developers.id
      access  = "write"
    }
  }
}

# Workspaces in the project inherit the project team access
module "workspace" {
  source       = "./workspace"
  organization = "my-org"
  name         = "my-workspace"
  project_id   = module.project.id
}
```

### Users and teams

```hcl
module "org_member" {
  source   = "./organization-membership"
  for_each = {
    dev1 = "dev1@example.com"
    dev2 = "dev2@example.com"
  }

  organization = "my-org"

  member = {
    email    = each.value
    team_ids = [module.team_developers.id]
  }
}
```

Do not use `organization-membership` when users are provisioned through SCIM.

### VCS → registry modules → workspaces

```hcl
module "registry_vpc" {
  source = "./registry-module"

  organization    = "my-org"
  name            = "vpc"
  module_provider = "aws"

  vcs_repo = {
    display_identifier = "my-org/terraform-aws-vpc"
    identifier         = "my-org/terraform-aws-vpc"
    oauth_token_id     = module.vcs_github.oauth_token_id
    tags               = true
  }
}

# Consumers can now use: app.terraform.io/my-org/vpc/aws
```

### Agent pools for private networks

```hcl
module "agent_pool" {
  source       = "./agent-pool"
  organization = "my-org"
  name         = "private-datacenter"

  agent_tokens = {
    primary = { description = "Primary agent token" }
  }
}

module "workspace_private" {
  source         = "./workspace"
  organization   = "my-org"
  name           = "private-infrastructure"
  execution_mode = "agent"
  agent_pool_id  = module.agent_pool.id
}
```

### Governance: policy sets and run tasks

```hcl
module "policy_security" {
  source = "./policy-set"

  organization = "my-org"
  name         = "security-policies"
  kind         = "sentinel"
  global       = true

  workspace_exclusion_ids = {
    sandbox = module.workspace_sandbox.id
  }

  vcs_repo = {
    identifier     = "my-org/sentinel-policies"
    branch         = "main"
    oauth_token_id = module.vcs_github.oauth_token_id
  }
}

module "run_task_snyk" {
  source = "./run-task"

  organization = "my-org"
  name         = "snyk-security"
  url          = "https://api.snyk.io/v1/terraform-cloud/run-task"
  hmac_key     = var.snyk_hmac_key

  workspace_run_tasks = {
    prod = {
      workspace_id      = module.workspace_prod.id
      enforcement_level = "mandatory"
      stage             = "post_plan"
    }
  }
}
```

### GitOps with run triggers

```hcl
module "workspace_dev" {
  source = "./workspace"

  organization = "my-org"
  name         = "app-dev"
  auto_apply   = true

  vcs_repo = {
    vcs_organization = "my-org"
    repository       = "infrastructure"
    branch           = "develop"
    oauth_token_id   = module.vcs_github.oauth_token_id
  }
}

module "workspace_prod" {
  source = "./workspace"

  organization = "my-org"
  name         = "app-prod"
  auto_apply   = false

  vcs_repo = {
    vcs_organization = "my-org"
    repository       = "infrastructure"
    branch           = "main"
    oauth_token_id   = module.vcs_github.oauth_token_id
  }

  # dev → prod
  run_trigger_source_workspace_ids = [module.workspace_dev.id]
}
```

### Azure dynamic credentials

See the [configuration](dynamic-credentials/azure/configuration/README.md) module (bootstrap of the Azure application and service principal) and the [management](dynamic-credentials/azure/management/README.md) module (one federated identity credential per workspace/run phase, typically invoked with `for_each`).

## Best Practices

### Module usage
- **Version pinning**: pin module sources and provider versions in production.
- **Validation**: rely on the variable validations provided by the modules to catch errors early.
- **Outputs**: use module outputs to pass IDs between modules instead of hard-coding them.
- **Documentation**: review the module README before use.

### Projects and teams
- Use projects to group related workspaces and apply team access at the project level.
- Grant organization-level permissions sparingly. Use custom permissions for fine-grained access.
- When using SCIM, manage those teams with `saml-sso-and-scim`, not `team`/`organization-membership`.

### Variables
- Use global variable sets only for truly universal values. Prefer project-scoped sets, then workspace-scoped sets for specific credentials.
- Set `priority = true` for credential variable sets.
- Always mark secrets as `sensitive = true`.

### Security
- Never commit secrets or `.tfvars` files. Pass secrets via sensitive variables or a secrets manager.
- Rotate agent tokens, team tokens and the SCIM token regularly.
- Prefer explicit `remote_state_consumer_ids` over `global_remote_state`.
- Use workspace-scoped agent pools for sensitive workloads and policy sets for compliance enforcement.

### VCS and workspaces
- Use tag-based versioning for registry modules and branch protection in your VCS.
- Use separate branches (or workspaces) per environment. Enable auto-apply only for non-production workspaces.
- Configure notifications for critical events and run triggers to orchestrate dependencies.

## Troubleshooting

1. **VCS connection failures**: verify the OAuth token permissions, repository access and webhook delivery.
2. **Agent pool issues**: verify the agent token, connectivity from the agent to TFE and the agent logs.
3. **Permission errors**: review team access, organization-level permissions and custom permission settings.
4. **Variable conflicts**: check variable set `priority`, scope (workspace vs project vs global) and category (`terraform` vs `env`).
5. **`for_each` errors with unknown values**: use the map-based inputs (`project_ids_map`, `workspace_ids_map`) with static keys.

## Contributing

When adding or changing a module:

1. Follow the module layout above (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `README.md`).
2. Add validation to input variables where appropriate and describe every variable and output.
3. Specify provider version constraints.
4. Keep the module README in sync with the code: usage examples, an Inputs table, an Outputs table and any limitations. Use `./<module>` for `source` in examples.
5. Add the module to the [Modules](#modules) table in this README.
6. Test thoroughly before committing.

## Additional Resources

- [Terraform Enterprise Documentation](https://developer.hashicorp.com/terraform/enterprise)
- [TFE Provider Documentation](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs)
- [Sentinel Documentation](https://docs.hashicorp.com/sentinel)
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)

## Support

This project is offered as is and **no support is provided** (see the disclaimer at the top of this README and [SUPPORT](.github/SUPPORT.md)). For issues or questions, these resources are the best place to start:

- The README of each module in this repository (see the [Modules](#modules) table)
- [TFE documentation](https://developer.hashicorp.com/terraform/enterprise)
- [TFE provider documentation](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs)

## License

Licensed under the [Mozilla Public License 2.0](LICENSE). See also [CONTRIBUTING](.github/CONTRIBUTING.md), [SUPPORT](.github/SUPPORT.md) and [SECURITY](.github/SECURITY.md).
