variable "name" {
  type        = string
  description = "Warehouse name (fully uppercase, no spaces)"
}

variable "warehouse_size" {
  type        = string
  description = "Snowflake warehouse size: XSMALL, SMALL, MEDIUM, LARGE, XLARGE"
  default     = "XSMALL"

  validation {
    condition     = contains(["XSMALL", "SMALL", "MEDIUM", "LARGE", "XLARGE", "2XLARGE"], var.warehouse_size)
    error_message = "warehouse_size must be one of: XSMALL, SMALL, MEDIUM, LARGE, XLARGE, 2XLARGE"
  }
}

variable "auto_suspend_seconds" {
  type        = number
  description = "Seconds of inactivity before auto-suspend"
  default     = 60
}

variable "comment" {
  type        = string
  description = "Optional description"
  default     = ""
}
