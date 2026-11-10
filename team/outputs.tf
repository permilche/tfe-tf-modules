output "id" {
  description = "The ID of the team"
  value       = tfe_team.non_scim_teams.id
}

output "name" {
  description = "The name of the team"
  value       = tfe_team.non_scim_teams.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_team.non_scim_teams.organization
}

output "visibility" {
  description = "The visibility of the team"
  value       = tfe_team.non_scim_teams.visibility
}

output "sso_team_id" {
  description = "The SSO Team ID"
  value       = tfe_team.non_scim_teams.sso_team_id
}
