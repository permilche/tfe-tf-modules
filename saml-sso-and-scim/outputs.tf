output "saml_enabled" {
  description = "Whether SAML SSO is enabled"
  value       = tfe_saml_settings.this.enabled
}

output "sso_endpoint_url" {
  description = "The Single Sign-On URL configured"
  value       = tfe_saml_settings.this.sso_endpoint_url
}

output "slo_endpoint_url" {
  description = "The Single Log Out URL configured"
  value       = tfe_saml_settings.this.slo_endpoint_url
}

output "acs_consumer_url" {
  description = "ACS Consumer (Recipient) URL for IdP configuration"
  value       = tfe_saml_settings.this.acs_consumer_url
}

output "metadata_url" {
  description = "Metadata (Audience) URL for IdP configuration"
  value       = tfe_saml_settings.this.metadata_url
}

output "team_management_enabled" {
  description = "Whether automatic team management via SAML is enabled"
  value       = tfe_saml_settings.this.team_management_enabled
}

output "attr_username" {
  description = "SAML attribute used for username mapping"
  value       = tfe_saml_settings.this.attr_username
}

output "attr_groups" {
  description = "SAML attribute used for team membership mapping"
  value       = tfe_saml_settings.this.attr_groups
}

output "provider_type" {
  description = "The identity provider type configured"
  value       = tfe_saml_settings.this.provider_type
}

# SCIM Outputs

output "scim_enabled" {
  description = "Whether SCIM provisioning is enabled"
  value       = var.enable_scim
}

output "scim_token" {
  description = "The SCIM token for configuring your identity provider (sensitive)"
  value       = var.enable_scim ? tfe_scim_token.this[0].token : null
  sensitive   = true
}

output "scim_token_expiration" {
  description = "CAUTION: The expiration date of the SCIM token. REMEMBER to update it in your identity provider before it expires to avoid service disruption"
  value       = var.enable_scim ? tfe_scim_token.this[0].expired_at : null
}

output "scim_token_id" {
  description = "The ID of the SCIM token"
  value       = var.enable_scim ? tfe_scim_token.this[0].id : null
}

output "scim_team_ids" {
  description = "Map of TFE team names to team IDs"
  value = var.enable_scim ? {
    for k, v in tfe_team.scim_teams : k => v.id
  } : {}
}

output "scim_team_names" {
  description = "Map of TFE team names to SCIM group names"
  value = var.enable_scim ? {
    for k, v in tfe_team.scim_teams : k => v.name
  } : {}
}

output "scim_group_mappings" {
  description = "Map of configured SCIM group mappings (team_name => group details)"
  value = var.enable_scim ? {
    for k, v in tfe_scim_group_mapping.this : k => {
      scim_group_id = v.scim_group_id
      team_id    = v.team_id
      team_name  = k
    }
  } : {}
}

output "scim_group_ids" {
  description = "Map of SCIM group names to their IDs"
  value = var.enable_scim ? {
    for k, v in data.tfe_scim_group.this : k => v.id
  } : {}
}

output "break_glass_admin_instructions" {
  description = "Instructions for creating a break-glass admin user"
  value = var.create_break_glass_admin ? join("\n", [
    "╔════════════════════════════════════════════════════════════════════════════╗",
    "║                    BREAK-GLASS ADMIN USER INSTRUCTIONS                     ║",
    "╚════════════════════════════════════════════════════════════════════════════╝",
    "",
    "The TFE Terraform provider does not support creating admin users.",
    "You must create a break-glass admin user manually using one of these methods:",
    "",
    "═══════════════════════════════════════════════════════════════════════════",
    "METHOD 1: TFE Admin Console (Web UI)",
    "═══════════════════════════════════════════════════════════════════════════",
    "",
    "1. Navigate to: https://<TFE_HOSTNAME>/admin/users",
    "2. Click \"Create a new user\"",
    "3. Fill in the form:",
    "   - Username: ${var.break_glass_admin_username}",
    "   - Email: ${var.break_glass_admin_email != null ? var.break_glass_admin_email : "${var.break_glass_admin_username}@example.com"}",
    "   - Password: <secure password>",
    "   - Site Admin: ✓ (checked)",
    "4. Click \"Create user\"",
    "5. Store credentials securely (password manager, vault, etc.)",
    "",
    "═══════════════════════════════════════════════════════════════════════════",
    "METHOD 2: TFE Admin CLI",
    "═══════════════════════════════════════════════════════════════════════════",
    "",
    "SSH into your TFE instance and run:",
    "",
    "$ tfe-admin user create \\",
    "    --username=\"${var.break_glass_admin_username}\" \\",
    "    --email=\"${var.break_glass_admin_email != null ? var.break_glass_admin_email : "${var.break_glass_admin_username}@example.com"}\" \\",
    "    --site-admin \\",
    "    --password=\"<secure-password>\"",
    "",
    "═══════════════════════════════════════════════════════════════════════════",
    "METHOD 3: TFE Admin API",
    "═══════════════════════════════════════════════════════════════════════════",
    "",
    "curl -X POST https://<TFE_HOSTNAME>/api/v2/admin/users \\",
    "  -H \"Authorization: Bearer <ADMIN_TOKEN>\" \\",
    "  -H \"Content-Type: application/vnd.api+json\" \\",
    "  -d '{",
    "    \"data\": {",
    "      \"type\": \"users\",",
    "      \"attributes\": {",
    "        \"username\": \"${var.break_glass_admin_username}\",",
    "        \"email\": \"${var.break_glass_admin_email != null ? var.break_glass_admin_email : "${var.break_glass_admin_username}@example.com"}\",",
    "        \"is-site-admin\": true,",
    "        \"password\": \"<secure-password>\"",
    "      }",
    "    }",
    "  }'",
    "",
    "═══════════════════════════════════════════════════════════════════════════",
    "SECURITY BEST PRACTICES",
    "═══════════════════════════════════════════════════════════════════════════",
    "",
    "✓ Use a strong, randomly generated password (min 16 characters)",
    "✓ Store credentials in a secure password manager or vault",
    "✓ Limit access to break-glass credentials to authorized personnel only",
    "✓ Document the break-glass procedure in your runbooks",
    "✓ Test the break-glass account periodically",
    "✓ Monitor and audit break-glass account usage",
    "✓ Consider using MFA for the break-glass account if supported",
    "✓ Rotate break-glass credentials regularly",
    "",
    "═══════════════════════════════════════════════════════════════════════════",
  ]) : ""
}
