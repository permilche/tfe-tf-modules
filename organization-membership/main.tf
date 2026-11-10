resource "tfe_organization_membership" "this" {
  organization = var.organization
  email        = var.member["email"]

  lifecycle {
    ignore_changes = [
      # because This resource cannot be used to update an existing user's email address since users themselves are the only ones permitted to update their email address
      # if a user updates their email address, configurations using the email address should be updated manually
      email,
    ]
  }
}

resource "tfe_team_organization_member" "this" {
  for_each = toset(var.member["team_ids"])

  team_id                     = each.value
  organization_membership_id  = tfe_organization_membership.this.id
}