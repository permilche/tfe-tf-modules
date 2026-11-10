output "id" {
  description = "The ID of the team token"
  value       = tfe_team_token.this.id
}

output "token" {
  description = "The generated team token"
  value       = tfe_team_token.this.token
  sensitive   = true
}

output "team_id" {
  description = "The ID of the team"
  value       = tfe_team_token.this.team_id
}
