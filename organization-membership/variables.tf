variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "member" {
  description = "Organization member to invite and the team_ids they should be added to"
  type = object({
    email    = string
    team_ids = optional(list(string), [])
  })
}