variable "team_id" {
  description = "ID of the team"
  type        = string
}

variable "force_regenerate" {
  description = "If set to true, a new token will be generated even if a token already exists. This will invalidate the existing token. Defaults to false"
  type        = bool
  default     = false
}

variable "expired_at" {
  description = "The token's expiration date in RFC3339 format (e.g., '2024-12-31T23:59:59Z'). If omitted, the token will never expire. Defaults to null"
  type        = string
  default     = null
}
