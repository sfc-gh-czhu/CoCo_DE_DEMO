# Creates a Snowflake warehouse.
# This is an ACCOUNT-LEVEL resource — Terraform owns it.
# DCM's access.sql then grants USAGE on this warehouse to project roles.

resource "snowflake_warehouse" "this" {
  name           = var.name
  warehouse_size = var.warehouse_size
  auto_suspend   = var.auto_suspend_seconds
  auto_resume    = true
  comment        = var.comment != "" ? var.comment : "Managed by Terraform"
}

output "name" {
  value       = snowflake_warehouse.this.name
  description = "Warehouse name — pass to DCM access.sql grants"
}
