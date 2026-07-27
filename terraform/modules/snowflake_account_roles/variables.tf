variable "roles" {
  type = list(object({
    name    = string
    comment = optional(string, "")
  }))
  description = "List of account-level roles to create"
  default     = []
}

variable "service_users" {
  type = list(object({
    name         = string
    default_role = string
    email        = optional(string, "")
    comment      = optional(string, "")
  }))
  description = "Service account users to provision"
  default     = []
}
