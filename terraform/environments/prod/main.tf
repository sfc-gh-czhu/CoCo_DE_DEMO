# Production environment — AU_PROD + UK_PROD
# Warehouse size: LARGE | Auto-suspend: 300s

terraform {
  # Use a remote backend with state locking for production.
  # Example (S3):
  # backend "s3" {
  #   bucket = "my-tf-state"
  #   key    = "snowflake/coco-de-demo-prod/terraform.tfstate"
  #   region = "ap-southeast-2"
  # }
}

module "pipeline_warehouse" {
  source = "../../modules/snowflake_warehouses"

  name           = "COCO_DE_DEMO_PIPELINE_WH"
  warehouse_size = var.warehouse_size
  auto_suspend_seconds = 300
  comment        = "COCO_DE_DEMO prod pipeline compute — owned by Terraform"
}

module "account_roles" {
  source = "../../modules/snowflake_account_roles"

  roles = [
    { name = "PIPELINE_DEPLOYER", comment = "CI/CD deployment role for production" },
    { name = "COCO_DE_DEMO_WH_USER", comment = "Warehouse access role for prod — used by DCM access.sql grants" },
  ]

  service_users = [
    {
      name         = "COCO_PIPELINE_SVC"
      default_role = "PIPELINE_DEPLOYER"
      comment      = "CI/CD service account for production deployments"
    }
  ]
}
