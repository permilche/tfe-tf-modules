variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "name" {
  description = "Name of the SSH key"
  type        = string
}

variable "key" {
  description = "The SSH private key content"
  type        = string
  sensitive   = true
}

variable "key_version" {
  description = "The SSH private key version since it is not stored in the state"
  type        = number
  default     = 1
}
