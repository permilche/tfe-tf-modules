resource "tfe_organization" "this" {
  name                                                    = var.organization
  email                                                   = var.email
  session_timeout_minutes                                 = var.session_timeout_minutes
  session_remember_minutes                                = var.session_remember_minutes
  collaborator_auth_policy                                = var.collaborator_auth_policy
  cost_estimation_enabled                                 = var.cost_estimation_enabled
  owners_team_saml_role_id                                = var.owners_team_saml_role_id
  send_passing_statuses_for_untriggered_speculative_plans = var.send_passing_statuses_for_untriggered_speculative_plans
  aggregated_commit_status_enabled                        = var.aggregated_commit_status_enabled
  assessments_enforced                                    = var.assessments_enforced
  allow_force_delete_workspaces                           = var.allow_force_delete_workspaces
}

# locals {
#   agent_pool_id = var.default_execution_mode == "agent" ? var.default_agent_pool_id : null
# }

resource "tfe_organization_default_settings" "this" {
  # count = var.default_execution_mode == "agent" ? 0 : 1
  
  organization           = tfe_organization.this.name
  default_execution_mode = var.default_execution_mode
  # The TFE provider does not currently support setting the default agent pool ID when the default execution mode is not "agent". Even if it evaluates to null, as with the local variable. It only works if you either omit it or hardcode it to null, variable interpolation does not work. This is a known issue with the TFE provider, as you can see in the provider documentation: https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization_default_settings#argument-reference
  # "This value must not be provided if default_execution_mode is set to any other value."
  # Due to this limitation, the default_agent_pool_id argument is commented out. If you need to set the default agent pool ID, uncomment the argument, you will need to set the default execution mode to "agent" and provide a valid agent pool ID.
  # The approach underneath, where we set two different setting resources based on the default execution mode, is a workaround to this limitation that also failed. It is kept here for documentation purposes only.
  # default_agent_pool_id  = local.agent_pool_id
}

# resource "tfe_organization_default_settings" "this_with_agent" {
#   count = var.default_execution_mode == "agent" ? 1 : 0
  
#   organization           = tfe_organization.this.name
#   default_execution_mode = var.default_execution_mode
#   default_agent_pool_id  = var.default_agent_pool_id
# }

resource "tfe_admin_smtp_settings" "this" {
  count = var.tfe_admin_smtp_settings != null ? 1 : 0
  
  enabled             = var.tfe_admin_smtp_settings.enabled
  host                = var.tfe_admin_smtp_settings.host
  port                = var.tfe_admin_smtp_settings.port
  sender              = var.tfe_admin_smtp_settings.sender
  auth                = var.tfe_admin_smtp_settings.auth
  username            = var.tfe_admin_smtp_settings.username
  password_wo         = var.tfe_admin_smtp_settings.password_wo
  password_wo_version = var.tfe_admin_smtp_settings.password_wo_version
  test_email_address  = var.tfe_admin_smtp_settings.test_email_address
}
