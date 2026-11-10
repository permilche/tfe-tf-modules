# TFE SAML SSO and SCIM Module

Terraform module to configure SAML Single Sign-On (SSO) and SCIM (System for Cross-domain Identity Management) provisioning for Terraform Enterprise/HCP Terraform with support for multiple identity providers.

> **Note**: This module is for creating **SCIM-managed teams** that are automatically synchronized from your Identity Provider (IdP).
> 
> For **non-SCIM managed teams** (manually managed teams or teams with SSO mapping via `sso_team_id` only), use the [team](../team) module instead. Non-SCIM teams are created and managed manually through Terraform or the TFE UI.

Refer to the [SCIM Team Mapping](#scim-team-mapping) section to understand the implications of it (two `terraform applies` will be needed)

## Features

- **SAML SSO Configuration**: Complete SAML 2.0 SSO setup
- **SCIM Provisioning**: Automatic user and group synchronization from IdP
- **Multi-IdP Support**: Works with Azure Entra ID, Okta, and other SAML 2.0 providers
- **Automatic Team Management**: Maps IdP groups to TFE teams (SCIM-managed)
- **Flexible Permissions**: Configure organization-level access per team
- **Break-Glass Admin**: Instructions for emergency access
- **Debug Mode**: Troubleshooting support for SAML issues

## Prerequisites

Before using this module:

1. Administrative access to both your Identity Provider and Terraform Enterprise
2. Completed IdP application setup (see provider-specific guides below)
3. Certificates and URLs from your IdP

## Supported Identity Providers

- **Azure Entra ID** (formerly Azure Active Directory)
- **Okta**
- **Any SAML 2.0 compliant provider**

## Usage

### Basic SAML SSO Only

```hcl
module "saml_sso" {
  source = "./saml-sso-and-scim"

  organization     = "my-org"
  idp_cert         = file("path/to/idp-certificate.pem")
  sso_endpoint_url = "https://idp.example.com/sso"
  slo_endpoint_url = "https://idp.example.com/slo"

  provider_type = "entra"  # or "okta", "saml"
}
```

### SAML SSO with SCIM Provisioning

```hcl
module "saml_sso_scim" {
  source = "./saml-sso-and-scim"

  organization     = "my-org"
  idp_cert         = file("path/to/idp-certificate.pem")
  sso_endpoint_url = "https://login.microsoftonline.com/<tenant-id>/saml2"
  slo_endpoint_url = "https://login.microsoftonline.com/<tenant-id>/saml2"

  provider_type = "entra"

  # Enable SCIM provisioning
  enable_scim = true

  # Map IdP groups to TFE teams (groups are looked up dynamically by name)
  scim_teams = [
    {
      group_name = "Engineering"
      team_name  = "engineers"
      team_visibility = "organization"
      organization_access = {
        read_workspaces   = true
        read_projects     = true
        manage_workspaces = true
      }
    },
    {
      group_name = "Platform Team"
      team_name  = "platform"
      team_visibility = "organization"
      organization_access = {
        read_workspaces     = true
        read_projects       = true
        manage_workspaces   = true
        manage_projects     = true
        manage_vcs_settings = true
      }
    },
  ]
}

# Store SCIM token securely
output "scim_token" {
  value     = module.saml_sso_scim.scim_token
  sensitive = true
}
```

### Complete Configuration with All Features

```hcl
module "saml_sso_scim" {
  source = "./saml-sso-and-scim"

  organization     = "my-org"
  idp_cert         = file("path/to/certificate.pem")
  sso_endpoint_url = "https://idp.example.com/sso"
  slo_endpoint_url = "https://idp.example.com/slo"
  
  # SAML Configuration
  provider_type              = "entra"
  team_management_enabled    = true
  authn_requests_signed      = true
  want_assertions_signed     = true
  attr_username              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  attr_groups                = "MemberOf"
  site_admin_role            = "site-admins"
  sso_api_token_session_timeout = 1209600  # 14 days
  
  # SCIM Configuration
  enable_scim = true
  scim_token_description = "SCIM token for Azure Entra ID"
  
  scim_teams = [
    {
      group_name = "Developers"
      team_name  = "developers"
      organization_access = {
        read_workspaces = true
        read_projects   = true
      }
    },
    {
      group_name = "Admins"
      team_name  = "admins"
      organization_access = {
        manage_workspaces          = true
        manage_projects            = true
        manage_organization_access = true
      }
    },
  ]
  
  # Break-glass admin
  create_break_glass_admin   = true
  break_glass_admin_username = "emergency-admin"
  break_glass_admin_email    = "emergency@example.com"
}
```

## Identity Provider Configuration

### Azure Entra ID Setup

#### 1. Create Enterprise Application

1. Navigate to **Azure Active Directory** → **Enterprise Applications**
2. Click **New application** → **Create your own application**
3. Name: `Terraform Enterprise`
4. Select **Integrate any other application you don't find in the gallery**

#### 2. Configure SAML SSO

1. Go to **Single sign-on** → Select **SAML**
2. Configure **Basic SAML Configuration**:
   - **Identifier (Entity ID)**: `https://<TFE_HOSTNAME>/users/saml/metadata`
   - **Reply URL**: `https://<TFE_HOSTNAME>/users/saml/auth`
   - **Sign on URL**: `https://<TFE_HOSTNAME>/`

3. Configure **User Attributes & Claims**:
   - **Name identifier**: `user.mail` (Email address format)
   - Add claim **MemberOf**: `user.assignedroles`

4. Download **SAML Signing Certificate** (Base64)
5. Copy **Login URL** and **Logout URL**

#### 3. Configure SCIM Provisioning (Optional)

1. Go to **Provisioning** → **Get started**
2. Set **Provisioning Mode** to **Automatic**
3. Configure **Admin Credentials**:
   - **Tenant URL**: `https://<TFE_HOSTNAME>/scim/v2`
   - **Secret Token**: Use `scim_token` output from this module
4. Click **Test Connection** → **Save**
5. Under **Mappings**, configure:
   - **Provision Azure Active Directory Users**
   - **Provision Azure Active Directory Groups**

#### 4. Create App Roles for Team Mapping

Edit the application manifest to add roles:

```json
{
  "appRoles": [
    {
      "allowedMemberTypes": ["User"],
      "displayName": "Developers",
      "id": "unique-guid-1",
      "isEnabled": true,
      "description": "Developer Team",
      "value": "developers"
    },
    {
      "allowedMemberTypes": ["User"],
      "displayName": "Platform Team",
      "id": "unique-guid-2",
      "isEnabled": true,
      "description": "Platform Team",
      "value": "platform"
    },
  ]
}
```

### Okta Setup

#### 1. Create SAML Application

1. Navigate to **Applications** → **Create App Integration**
2. Select **SAML 2.0**
3. Configure **General Settings**:
   - **App name**: `Terraform Enterprise`

4. Configure **SAML Settings**:
   - **Single sign on URL**: `https://<TFE_HOSTNAME>/users/saml/auth`
   - **Audience URI**: `https://<TFE_HOSTNAME>/users/saml/metadata`
   - **Name ID format**: EmailAddress
   - **Application username**: Email

5. Add **Attribute Statements**:
   - **MemberOf**: `appuser.groups`

6. Download **X.509 Certificate**
7. Copy **Identity Provider Single Sign-On URL** and **Identity Provider Issuer**

#### 2. Configure SCIM Provisioning (Optional)

1. Go to **Provisioning** → **Configure API Integration**
2. Enable **API integration**
3. Configure:
   - **Base URL**: `https://<TFE_HOSTNAME>/scim/v2`
   - **API Token**: Use `scim_token` output from this module
4. Enable **Create Users**, **Update User Attributes**, **Deactivate Users**
5. Enable **Create Groups**, **Update Group Attributes**

## Inputs

### Required Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| idp_cert | Identity Provider Certificate (PEM encoded, sensitive) | `string` | yes |
| sso_endpoint_url | Single Sign-On URL from IdP | `string` | yes |
| slo_endpoint_url | Single Log Out URL from IdP | `string` | yes |
| organization | Name of the TFE organization | `string` | yes |

### SAML Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| provider_type | IdP type (okta, entra, saml, unknown) | `string` | `"entra"` |
| debug | Display SAMLResponse XML on failures | `bool` | `false` |
| authn_requests_signed | Sign AuthnRequest messages | `bool` | `false` |
| want_assertions_signed | Require signed assertions | `bool` | `false` |
| team_management_enabled | Enable automatic team management via SAML attributes | `bool` | `true` |
| attr_username | SAML attribute for username | `string` | `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"` |
| attr_groups | SAML attribute for team membership | `string` | `"MemberOf"` |
| attr_site_admin | SAML attribute for site admin (overrides site_admin_role) | `string` | `null` |
| site_admin_role | Role name for site admin from the team attribute | `string` | `null` |
| sso_api_token_session_timeout | Session timeout in seconds | `number` | `1209600` |
| signature_signing_method | Signing method (SHA1, SHA256) | `string` | `"SHA256"` |
| signature_digest_method | Digest method (SHA1, SHA256) | `string` | `"SHA256"` |
| acs_consumer_url | ACS Consumer (Recipient) URL, typically auto-generated by TFE | `string` | `null` |
| metadata_url | Metadata (Audience) URL, typically auto-generated by TFE | `string` | `null` |
| certificate | Certificate for request and assertion signing | `string` (sensitive) | `null` |
| private_key | Private key for request and assertion signing | `string` (sensitive) | `null` |

### SCIM Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_scim | Enable SCIM provisioning | `bool` | `false` |
| scim_token_description | Description for the SCIM token | `string` | `"SCIM provisioning token"` |
| scim_token_rotation_days | Days before SCIM token expires and is rotated (1, 365) | `number` | `90` |
| scim_teams | List of IdP groups to TFE team mappings | `list(object)` | `[]` |

### Break-Glass Admin

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_break_glass_admin | Output admin creation instructions | `bool` | `false` |
| break_glass_admin_username | Username for break-glass admin | `string` | `"break-glass-admin"` |
| break_glass_admin_email | Email for break-glass admin | `string` | `null` |

## Outputs

### SAML Outputs

| Name | Description |
|------|-------------|
| saml_enabled | Whether SAML SSO is enabled |
| sso_endpoint_url | SSO URL configured |
| slo_endpoint_url | SLO URL configured |
| acs_consumer_url | ACS Consumer (Recipient) URL for IdP configuration |
| metadata_url | Metadata (Audience) URL for IdP configuration |
| team_management_enabled | Whether automatic team management via SAML is enabled |
| attr_username | SAML attribute used for username mapping |
| attr_groups | SAML attribute used for team membership mapping |
| provider_type | IdP type configured |

### SCIM Outputs

| Name | Description |
|------|-------------|
| scim_enabled | Whether SCIM is enabled |
| scim_token | SCIM token (sensitive) |
| scim_token_expiration | Expiration date of the SCIM token, update in IdP before it expires |
| scim_token_id | SCIM token ID |
| scim_team_ids | Map of TFE team names to team IDs |
| scim_team_names | Map of TFE team names to SCIM group names |
| scim_group_ids | Map of SCIM group names to their IDs |
| scim_group_mappings | Map of configured SCIM group mappings (team_name → group details) |
| break_glass_admin_instructions | Instructions for creating a break-glass admin user (populated when `create_break_glass_admin = true`) |

## SCIM Team Mapping

The `scim_teams` variable maps IdP groups to TFE teams. Groups are looked up dynamically by name:

```hcl
scim_teams = [
  # Groups are looked up by name - no need to know IDs in advance
  {
    group_name      = "Engineering"        # Display name in IdP
    team_name       = "engineers"          # TFE team name
    team_visibility = "organization"       # or "secret", defaults to "organization"

    # Optional: Organization-level permissions
    organization_access = {
      read_workspaces   = true
      read_projects     = true
      manage_workspaces = true
      # ... other permissions
    }
  },
]
```

### How It Works

**Dynamic Group Lookup:**
- After SCIM is enabled and groups are synced from your IdP
- The module uses `data.tfe_scim_group` to look up groups by name

> **IMPORTANT**: Because we need the Enterprise Application to synchronize all selected groups first, the `scim_teams` variable should NOT be set first, otherwise you will end up with errors like: Error: SCIM group not found with module.saml_sso_scim.data.tfe_scim_group.this["Hashicorp"], n tfe/saml-sso-and-scim/main.tf line 39, in data "tfe_scim_group" "this": 39: data "tfe_scim_group" "this" { No SCIM group found with name "Hashicorp". So, you need to do two *terraform applies*, the first one without the variable, wait for SCIM to be synced and then once it is synced and SCIM groups from the IdP are available, do the mapping and reapply. It is not the most convenient thing but since it is not a configuration you usually need to apply I think it is not a problem 

**Okta:**
- Simply provide the group name from your IdP


## SCIM vs SAML Team Management

| Feature | SAML Team Management | SCIM Provisioning |
|---------|---------------------|-------------------|
| User Sync | On login only | Automatic, real-time |
| Group Sync | On login only | Automatic, real-time |
| User Deprovisioning | Manual | Automatic |
| Group Changes | On next login | Immediate |
| Best For | Simple setups | Enterprise scale |

**Recommendation**: Use SCIM for automatic provisioning and deprovisioning. Use SAML team management only if SCIM is not available.

## Break-Glass Admin User

**Important**: Always create a break-glass admin user before enabling SSO.

The break-glass admin user:
- Must NOT be mapped in SAML/SCIM
- Bypasses SSO for emergency access
- Should have credentials stored securely

Set `create_break_glass_admin = true` to display creation instructions.

## Security Best Practices

1. **Enable Signed Requests**: Set `authn_requests_signed = true` and `want_assertions_signed = true`
2. **Use SCIM**: Enable SCIM for automatic user deprovisioning
3. **Secure SCIM Token**: Store SCIM token in secrets manager
4. **Break-Glass Admin**: Create and test emergency admin account
5. **Regular Audits**: Monitor SSO/SCIM activity
6. **Rotate Credentials**: Regularly rotate SCIM tokens
7. **Test Regularly**: Periodically test break-glass access

## Troubleshooting

### Enable Debug Mode

Set `debug = true` to display SAMLResponse XML on login failures.

### Common Issues

**Users can't log in:**
- Verify IdP certificate is correct (PEM format)
- Check SSO/SLO URLs are correct
- Enable debug mode to see SAMLResponse

**Users not assigned to teams:**
- Verify `attr_groups` matches IdP claim name
- Check teams exist in TFE
- Ensure users are assigned to groups in IdP

**SCIM provisioning not working:**
- Verify SCIM token is correct
- Check SCIM URL: `https://<TFE_HOSTNAME>/scim/v2`
- Review IdP provisioning logs
- Ensure group names match exactly with IdP group names

**Site admin access not working:**
- Verify `site_admin_role` matches IdP role value
- Ensure users are assigned to admin role in IdP

## Integration with Team Module

This module creates **SCIM-managed teams** that are automatically synchronized from your Identity Provider. For **non-SCIM managed teams** (manually managed teams or teams that don't exist in your IdP), use the [team](../team) module.

### When to Use Each Module

**Use saml-sso-and-scim module (this module) for:**
- Teams that exist as groups in your Identity Provider (Azure AD, Okta, etc.)
- Teams that should be automatically synchronized with IdP group membership
- Teams where user provisioning/deprovisioning should be automatic

**Use [team](../team) module for:**
- Teams that don't exist in your Identity Provider
- Contractor or external user teams
- Service account teams
- Teams requiring manual membership management
- Teams with SSO mapping via `sso_team_id` but without SCIM synchronization

### Example: Mixed Team Management

```hcl
# SCIM-managed teams (synchronized from IdP)
module "saml_sso_scim" {
  source = "./saml-sso-and-scim"
  
  enable_scim = true
  
  scim_teams = [
    {
      group_name = "Developers"
      team_name  = "developers"
      organization_access = {
        read_workspaces = true
        read_projects   = true
      }
    },
    {
      group_name = "Platform Team"
      team_name  = "platform"
      organization_access = {
        manage_workspaces = true
        manage_projects   = true
      }
    },
  ]
  
  # ... other SAML/SCIM config
}

# Non-SCIM team for contractors (manual management)
module "team_contractors" {
  source = "./team"
  
  organization = "my-org"
  name         = "contractors"
  visibility   = "secret"
  
  # Manual member management
  organization_member_ids = [
    data.tfe_organization_membership.contractor1.id,
    data.tfe_organization_membership.contractor2.id
  ]
}

# Non-SCIM team for service accounts
module "team_automation" {
  source = "./team"
  
  organization = "my-org"
  name         = "automation"
  visibility   = "secret"
  
  organization_access = {
    read_workspaces   = true
    manage_workspaces = true
  }
}
```

> **Important**: Do not try to manage SCIM-synchronized teams with the team module. SCIM teams are managed by your Identity Provider and attempting to manage them manually will cause conflicts.

## References

- [TFE SAML Configuration](https://developer.hashicorp.com/terraform/enterprise/saml/configuration)
- [TFE SCIM Configuration](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/scim)
- [Azure Entra ID SAML](https://developer.hashicorp.com/terraform/enterprise/saml/idp-configuration/aad)
- [Okta SAML](https://developer.hashicorp.com/terraform/enterprise/saml/idp-configuration/okta)