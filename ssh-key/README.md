# TFE SSH Key Module

This module manages SSH keys in Terraform Enterprise/HCP Terraform for accessing private Git repositories as module sources.

## Features

- Creates organization-level SSH keys
- Supports private Git repositories as module sources
- Secure key storage in TFE

## Requirements

The `key` input is passed to the write-only attribute `key_wo` of `tfe_ssh_key`, so the private key is never stored in state. Write-only arguments require Terraform 1.11 or later, even though `providers.tf` only enforces `>= 1.0`.

## Usage

### Basic SSH Key

```hcl
module "ssh_key" {
  source = "./ssh-key"

  organization   = "my-org"
  name           = "github-private-repos"
  key            = file("~/.ssh/id_rsa")
  key_version    = 1
}
```

### SSH Key for Private Module Sources

```hcl
# Create SSH key
module "ssh_key_private" {
  source = "./ssh-key"

  organization   = "my-org"
  name           = "private-modules"
  key            = var.ssh_private_key
  key_version    = 1
}

# Use in workspace with private module sources
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "app-infrastructure"

  vcs_repo = {
    identifier     = "my-org/infrastructure"
    oauth_token_id = module.vcs_oauth.oauth_token_id
  }
}

# In the workspace's Terraform code, you can now use:
# module "private_module" {
#   source = "git::ssh://git@github.com/my-org/private-terraform-module.git"
# }
```

### Multiple SSH Keys for Different Repositories

```hcl
module "ssh_key_github" {
  source = "./ssh-key"

  organization   = "my-org"
  name           = "github-private"
  key            = var.github_ssh_key
  key_version    = 1
}

module "ssh_key_gitlab" {
  source = "./ssh-key"

  organization   = "my-org"
  name           = "gitlab-private"
  key            = var.gitlab_ssh_key
  key_version    = 1
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Name of the organization | `string` | n/a | yes |
| name | Name of the SSH key | `string` | n/a | yes |
| key | The SSH private key content (sensitive, stored write-only, not kept in state) | `string` | n/a | yes |
| key_version | Version of the SSH private key. Increment to push a changed key (the key is not stored in state) | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the SSH key |
| name | The name of the SSH key |
| organization | The organization name |

## SSH Key Generation

Generate an SSH key pair for use with TFE:

```bash
# Generate a new SSH key (without passphrase for automation)
ssh-keygen -t rsa -b 4096 -C "tfe@example.com" -f ~/.ssh/tfe_key -N ""

# Add the public key to your Git provider
cat ~/.ssh/tfe_key.pub
```

## Configuring Git Providers

### GitHub

1. Go to repository Settings → Deploy keys
2. Add the public key (`~/.ssh/tfe_key.pub`)
3. Grant read access (write access not needed for module sources)

### GitLab

1. Go to repository Settings → Repository → Deploy Keys
2. Add the public key
3. Grant read access

### Bitbucket

1. Go to repository Settings → Access keys
2. Add the public key
3. Label it appropriately

## Using SSH Keys with Module Sources

Once the SSH key is configured in TFE, workspaces can use private Git repositories as module sources:

```hcl
# In your Terraform configuration
module "private_vpc" {
  source = "git::ssh://git@github.com/my-org/terraform-aws-vpc.git?ref=v1.0.0"
  
  # module configuration...
}

module "private_security" {
  source = "git::ssh://git@gitlab.com/my-org/terraform-security.git//modules/iam?ref=main"
  
  # module configuration...
}
```

## Security Best Practices

1. **Dedicated Keys**: Use dedicated SSH keys for TFE, not personal keys
2. **Read-Only Access**: Grant only read access to repositories
3. **Key Rotation**: Rotate SSH keys periodically
4. **Least Privilege**: Only add keys to repositories that need them
5. **Audit Access**: Regularly review which repositories have deploy keys
6. **Secure Storage**: Store private keys securely (use secrets manager)

## Troubleshooting

### Module Source Errors

If you encounter errors accessing private repositories:

1. **Verify SSH key is added**: Check TFE organization settings
2. **Check public key**: Ensure public key is added to Git provider
3. **Test SSH access**: Verify SSH access from your local machine
4. **Check URL format**: Ensure using `git::ssh://` prefix
5. **Verify permissions**: Confirm deploy key has read access

### Common Issues

- **Permission denied**: Public key not added to repository or incorrect permissions
- **Host key verification failed**: First-time connection to Git host
- **Invalid key format**: Ensure using OpenSSH format, not PuTTY or other formats

## Integration with Workspace Module

```hcl
# Create SSH key
module "ssh_key" {
  source = "./ssh-key"

  organization   = "my-org"
  name           = "private-modules"
  key            = var.ssh_private_key
  key_version    = 1
}

# Create workspace that will use private modules
module "workspace" {
  source = "./workspace"

  organization = "my-org"
  name         = "infrastructure"
  ssh_key_id   = module.ssh_key.id
  
  vcs_repo = {
    identifier     = "my-org/infrastructure-repo"
    oauth_token_id = module.vcs_oauth.oauth_token_id
  }
}

# The workspace's Terraform code can now reference private modules:
# module "internal_module" {
#   source = "git::ssh://git@github.com/my-org/private-module.git"
# }
```

## Limitations

- SSH keys are organization-scoped (not workspace-specific)
- One SSH key per Git host is typically sufficient
- Cannot use SSH keys for VCS-backed workspaces (use OAuth instead)
- SSH keys are for module sources only, not for workspace VCS connections

## Additional Resources

- [TFE SSH Keys Documentation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/ssh-keys)
- [Private Module Registry](https://developer.hashicorp.com/terraform/cloud-docs/registry)
- [Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)
