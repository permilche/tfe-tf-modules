# TFE Team Token Module

This module generates API tokens for teams in Terraform Enterprise/HCP Terraform, useful for CI/CD pipelines and automation that requires team-level access.

## Features

- Generates team API tokens
- Optional token expiration
- Force regeneration capability
- Secure token output

## Usage

### Basic Team Token

```hcl
module "team_token_ci" {
  source = "./team-token"

  team_id = module.team_developers.id
}
```

### Team Token with Expiration

```hcl
module "team_token_temp" {
  source = "./team-token"

  team_id    = module.team_contractors.id
  expired_at = "2024-12-31T23:59:59Z"
}
```

### Force Regenerate Token

```hcl
module "team_token_rotated" {
  source = "./team-token"

  team_id          = module.team_ops.id
  force_regenerate = true  # Invalidates existing token
}
```

### CI/CD Pipeline Token

```hcl
# Create team for CI/CD
module "team_cicd" {
  source = "./team"

  organization = "my-org"
  name         = "cicd-automation"

  organization_access = {
    read_workspaces   = true
    manage_workspaces = false
  }
}

# Generate token for CI/CD
module "team_token_cicd" {
  source = "./team-token"

  team_id = module.team_cicd.id
}

# Use token in CI/CD (e.g., GitHub Actions)
# Store module.team_token_cicd.token in secrets manager
```

### Multiple Tokens for Different Purposes

```hcl
# Development team token
module "team_token_dev" {
  source = "./team-token"

  team_id = module.team_developers.id
}

# Operations team token
module "team_token_ops" {
  source = "./team-token"

  team_id = module.team_operations.id
}

# Temporary contractor token (expires)
module "team_token_contractor" {
  source = "./team-token"

  team_id    = module.team_contractors.id
  expired_at = "2024-06-30T23:59:59Z"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| team_id | ID of the team | `string` | n/a | yes |
| force_regenerate | Force generation of new token | `bool` | `false` | no |
| expired_at | Token expiration date (RFC3339) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the team token |
| token | The generated team token (sensitive) |
| team_id | The ID of the team |

## Token Permissions

Team tokens inherit the permissions of the team:

- **Organization-level permissions** from team's `organization_access`
- **Project-level permissions** from team's project access
- **Workspace-level permissions** from team's workspace access

## Using Team Tokens

### Terraform CLI

```bash
# Set token as environment variable
export TFE_TOKEN="<team-token>"

# Or configure in CLI config
terraform login app.terraform.io
```

### CI/CD Pipelines

#### GitHub Actions

```yaml
name: Terraform
on: [push]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          cli_config_credentials_token: ${{ secrets.TFE_TEAM_TOKEN }}
      
      - name: Terraform Init
        run: terraform init
      
      - name: Terraform Plan
        run: terraform plan
```

#### GitLab CI

```yaml
terraform:
  image: hashicorp/terraform:latest
  before_script:
    - echo "credentials \"app.terraform.io\" { token = \"$TFE_TEAM_TOKEN\" }" > ~/.terraformrc
  script:
    - terraform init
    - terraform plan
```

#### Jenkins

```groovy
pipeline {
  agent any
  environment {
    TFE_TOKEN = credentials('tfe-team-token')
  }
  stages {
    stage('Terraform') {
      steps {
        sh 'terraform init'
        sh 'terraform plan'
      }
    }
  }
}
```

### API Access

```bash
# Using team token with TFE API
curl \
  --header "Authorization: Bearer <team-token>" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/my-org/workspaces
```

## Security Best Practices

1. **Store Securely**: Never commit tokens to version control
2. **Use Secrets Managers**: Store tokens in AWS Secrets Manager, HashiCorp Vault, etc.
3. **Rotate Regularly**: Use `force_regenerate` to rotate tokens periodically
4. **Set Expiration**: Use `expired_at` for temporary access
5. **Least Privilege**: Grant teams only necessary permissions
6. **Audit Usage**: Monitor token usage in TFE audit logs
7. **Separate Tokens**: Use different tokens for different purposes/environments

## Token Rotation

### Manual Rotation

```hcl
module "team_token" {
  source = "./team-token"

  team_id          = module.team_cicd.id
  force_regenerate = true  # Set to true to rotate
}

# After applying:
# 1. Retrieve new token from outputs
# 2. Update token in CI/CD secrets
# 3. Set force_regenerate back to false
```

### Automated Rotation

```hcl
# Use time-based rotation
resource "time_rotating" "token_rotation" {
  rotation_days = 90
}

module "team_token" {
  source = "./team-token"

  team_id          = module.team_cicd.id
  force_regenerate = time_rotating.token_rotation.id != ""
}
```

## Retrieving Token Value

The token is marked as sensitive and must be retrieved carefully:

```bash
# Using Terraform output
terraform output -raw team_token_cicd_token

# Store in environment variable
export TFE_TOKEN=$(terraform output -raw team_token_cicd_token)

# Store in secrets manager (AWS example)
aws secretsmanager create-secret \
  --name tfe-team-token \
  --secret-string "$(terraform output -raw team_token_cicd_token)"
```

## Troubleshooting

### Token Not Working

1. **Verify team permissions**: Check team's organization/project/workspace access
2. **Check expiration**: Ensure token hasn't expired
3. **Confirm token format**: Should be a long alphanumeric string
4. **Test with API**: Use curl to test token validity

### Permission Denied

1. **Review team access**: Team may lack required permissions
2. **Check resource scope**: Token may not have access to specific resources
3. **Verify organization**: Ensure using correct organization

## Integration with Team Module

```hcl
# Create team with specific permissions
module "team_automation" {
  source = "./team"

  organization = "my-org"
  name         = "automation"

  organization_access = {
    read_workspaces   = true
    manage_workspaces = true
    read_projects     = true
  }
}

# Generate token for the team
module "team_token_automation" {
  source = "./team-token"

  team_id = module.team_automation.id
}

# Output for use in CI/CD
output "automation_token" {
  value     = module.team_token_automation.token
  sensitive = true
}
```

## Comparison: Team Token vs User Token vs Organization Token

| Feature | Team Token | User Token | Organization Token |
|---------|------------|------------|-------------------|
| Scope | Team permissions | User permissions | Organization-wide |
| Expiration | Optional | No | No |
| Rotation | Via force_regenerate | Manual | Manual |
| CI/CD Use | ✅ Recommended | ⚠️ Not recommended | ✅ For admin tasks |
| Audit Trail | Team-based | User-based | Organization-based |

## Additional Resources

- [TFE API Tokens Documentation](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/api-tokens)
- [TFE API Authentication](https://developer.hashicorp.com/terraform/cloud-docs/api-docs#authentication)
- [Team Management](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/teams)
