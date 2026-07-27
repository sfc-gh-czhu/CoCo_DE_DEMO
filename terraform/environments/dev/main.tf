# Dev environment — AU_DEV + UK_DEV
# Warehouse size: XSMALL | Auto-suspend: 60s

terraform {
  # Remote state: use Terraform Cloud or an S3/GCS backend in production.
  # For demo purposes, local state is fine.
}

module "pipeline_warehouse" {
  source = "../../modules/snowflake_warehouses"

  name           = "COCO_DE_DEMO_PIPELINE_WH_DEV"
  warehouse_size = var.warehouse_size
  auto_suspend_seconds = 60
  comment        = "COCO_DE_DEMO dev pipeline compute — owned by Terraform"
}

module "account_roles" {
  source = "../../modules/snowflake_account_roles"

  roles = [
    { name = "PIPELINE_DEPLOYER_DEV", comment = "CI/CD deployment role for dev" },
    { name = "COCO_DE_DEMO_WH_USER_DEV", comment = "Warehouse access role for dev — used by DCM access.sql grants" },
  ]

  service_users = [
    {
      name         = "COCO_PIPELINE_SVC_DEV"
      default_role = "PIPELINE_DEPLOYER_DEV"
      comment      = "CI/CD service account for dev deployments"
    }
  ]
}
