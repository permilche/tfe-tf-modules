resource "tfe_registry_module" "this" {
  organization = var.organization
  namespace    = var.namespace

  dynamic "vcs_repo" {
    for_each = var.vcs_repo != null ? [var.vcs_repo] : []
    content {
      display_identifier         = vcs_repo.value.display_identifier
      identifier                 = vcs_repo.value.identifier
      oauth_token_id             = vcs_repo.value.oauth_token_id
      github_app_installation_id = vcs_repo.value.github_app_installation_id
      branch                     = vcs_repo.value.branch
      tags                       = vcs_repo.value.tags
      source_directory           = vcs_repo.value.source_directory
      tag_prefix                 = vcs_repo.value.tag_prefix
    }
  }

  module_provider    = var.module_provider
  name               = var.name
  registry_name      = var.registry_name
  initial_version    = var.initial_version
  # test_config        = var.test_config
  
  dynamic "test_config" {
    for_each = var.test_config
    content {
      tests_enabled = test_config.value.tests_enabled
      agent_execution_mode = test_config.value.agent_execution_mode
      agent_pool_id = test_config.value.agent_pool_id
    }
  }
}

resource "tfe_no_code_module" "this" {
  count = var.no_code_enabled ? 1 : 0

  organization    = var.organization
  registry_module = tfe_registry_module.this.id
  enabled         = true
  version_pin     = var.no_code_version_pin

  dynamic "variable_options" {
    for_each = var.no_code_variable_options
    content {
      name    = variable_options.value.name
      type    = variable_options.value.type
      options = variable_options.value.options
    }
  }
}
