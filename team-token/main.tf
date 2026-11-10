resource "tfe_team_token" "this" {
  team_id           = var.team_id
  force_regenerate  = var.force_regenerate
  expired_at        = var.expired_at
}
