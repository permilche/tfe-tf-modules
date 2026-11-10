output "id" {
  description = "The ID of the agent pool"
  value       = tfe_agent_pool.this.id
}

output "name" {
  description = "The name of the agent pool"
  value       = tfe_agent_pool.this.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_agent_pool.this.organization
}

output "organization_scoped" {
  description = "Whether the agent pool is organization scoped"
  value       = tfe_agent_pool.this.organization_scoped
}

output "agent_tokens" {
  description = "Map of agent token IDs and their tokens (sensitive)"
  value = {
    for k, v in tfe_agent_token.this : k => {
      id          = v.id
      description = v.description
      token       = v.token
    }
  }
  sensitive = true
}
