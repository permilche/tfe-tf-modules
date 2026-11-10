output "membership_id" {
  description = "Organization membership ID"
  value       = tfe_organization_membership.this.id
}

output "user_id" {
  description = "User ID"
  value       = tfe_organization_membership.this.user_id
}

output "email" {
  description = "Member email"
  value       = tfe_organization_membership.this.email
}

output "team_membership_ids" {
  description = "Map of team_id to tfe_team_organization_member resource ID"
  value = {
    for k, v in tfe_team_organization_member.this : k => v.id
  }
}