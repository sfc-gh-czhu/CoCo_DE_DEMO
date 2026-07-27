# Creates account-level roles and service account users.
# This is an ACCOUNT-LEVEL resource — Terraform owns it.
#
# Note: database roles (ANALYST / DEVELOPER / ADMIN within COCO_DE_DEMO)
# are managed by DCM in sources/definitions/access.sql — not here.

resource "snowflake_role" "roles" {
  for_each = { for r in var.roles : r.name => r }

  name    = each.value.name
  comment = each.value.comment != "" ? each.value.comment : "Managed by Terraform"
}

resource "snowflake_user" "service_users" {
  for_each = { for u in var.service_users : u.name => u }

  name         = each.value.name
  default_role = each.value.default_role
  comment      = each.value.comment != "" ? each.value.comment : "Service account — managed by Terraform"
  email        = each.value.email

  # Key-pair auth: public key is set out-of-band via Snowflake ALTER USER
  # after Terraform creates the user. Do not store private keys here.
  must_change_password = false

  depends_on = [snowflake_role.roles]
}

resource "snowflake_role_grants" "service_user_roles" {
  for_each = { for u in var.service_users : u.name => u }

  role_name = each.value.default_role
  users     = [each.value.name]

  depends_on = [snowflake_user.service_users]
}

output "role_names" {
  value       = [for r in snowflake_role.roles : r.name]
  description = "Created account role names"
}
