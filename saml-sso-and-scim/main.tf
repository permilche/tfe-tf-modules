# SAML SSO Configuration
resource "tfe_saml_settings" "this" {
  idp_cert         = trimspace(var.idp_cert)
  slo_endpoint_url = var.slo_endpoint_url
  sso_endpoint_url = var.sso_endpoint_url

  debug                         = var.debug
  authn_requests_signed         = var.authn_requests_signed
  want_assertions_signed        = var.want_assertions_signed
  team_management_enabled       = var.team_management_enabled
  attr_username                 = var.attr_username
  attr_groups                   = var.attr_groups
  attr_site_admin               = var.attr_site_admin
  site_admin_role               = var.site_admin_role
  sso_api_token_session_timeout = var.sso_api_token_session_timeout
  certificate                   = var.certificate
  private_key                   = var.private_key
  signature_signing_method      = var.signature_signing_method
  signature_digest_method       = var.signature_digest_method
  provider_type                 = var.provider_type
}

# SCIM Configuration
resource "tfe_scim_settings" "this" {
  count = var.enable_scim ? 1 : 0

  depends_on = [tfe_saml_settings.this]
}

resource "time_rotating" "tfe_scim_token" {
  count = var.enable_scim ? 1 : 0

  rotation_days = var.scim_token_rotation_days
}

# IMPORTANT: Changing description or expired_at (including removing expired_at after it has been set) will force the resource to be replaced, which generates a new token value and invalidates the previous one.
resource "tfe_scim_token" "this" {
  count = var.enable_scim ? 1 : 0

  expired_at   = time_rotating.tfe_scim_token[0].rotation_rfc3339
  description  = var.scim_token_description

  depends_on = [tfe_scim_settings.this]
}

# Lookup SCIM groups by name
data "tfe_scim_group" "this" {
  for_each = var.enable_scim ? { for team in var.scim_teams : team.team_name => team } : {}

  name = each.value.group_name

  depends_on = [tfe_scim_settings.this]
}

# Create TFE teams for SCIM group mapping
resource "tfe_team" "scim_teams" {
  for_each = var.enable_scim ? { for team in var.scim_teams : team.team_name => team } : {}

  name         = each.value.team_name
  organization = var.organization
  visibility   = each.value.team_visibility
  sso_team_id  = data.tfe_scim_group.this[each.key].id

  dynamic "organization_access" {
    for_each = each.value.organization_access != null ? [each.value.organization_access] : []
    content {
      access_secret_teams         = organization_access.value.access_secret_teams
      read_workspaces             = organization_access.value.read_workspaces
      read_projects               = organization_access.value.read_projects
      manage_policies             = organization_access.value.manage_policies
      manage_policy_overrides     = organization_access.value.manage_policy_overrides
      delegate_policy_overrides   = organization_access.value.delegate_policy_overrides
      manage_workspaces           = organization_access.value.manage_workspaces
      manage_vcs_settings         = organization_access.value.manage_vcs_settings
      manage_providers            = organization_access.value.manage_providers
      manage_modules              = organization_access.value.manage_modules
      manage_run_tasks            = organization_access.value.manage_run_tasks
      manage_projects             = organization_access.value.manage_projects
      manage_membership           = organization_access.value.manage_membership
      manage_teams                = organization_access.value.manage_teams
      manage_organization_access  = organization_access.value.manage_organization_access
      manage_agent_pools          = organization_access.value.manage_agent_pools
    }
  }
}

# SCIM Group to TFE Team Mapping
resource "tfe_scim_group_mapping" "this" {
  for_each = var.enable_scim ? { for team in var.scim_teams : team.team_name => team } : {}

  scim_group_id = data.tfe_scim_group.this[each.key].id
  team_id       = tfe_team.scim_teams[each.key].id

  depends_on = [tfe_scim_settings.this]
}

# Note: TFE provider does not have a resource for creating admin users
# Break-glass admin users must be created via:
# 1. TFE Admin Console (https://<hostname>/admin/users)
# 2. TFE CLI: tfe-admin user create
# 3. TFE API: POST /api/v2/admin/users
# See README.md for detailed instructions