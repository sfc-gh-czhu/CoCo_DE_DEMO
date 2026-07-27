# Terraform — Account-Level Infrastructure

## DCM vs Terraform: What Owns What

This project uses a **hybrid approach**: Terraform manages account-level Snowflake
resources, and DCM manages everything inside the database.

```
┌─────────────────────────────────────────────────────────────┐
│  TERRAFORM owns (account-level)                             │
│                                                             │
│  • Warehouses           (CREATE WAREHOUSE)                  │
│  • Service account roles (CREATE ROLE at account level)     │
│  • User provisioning    (CREATE USER)                       │
│  • Network policies     (CREATE NETWORK POLICY)             │
│  • SSO/SCIM integrations                                    │
│  • Resource monitors                                        │
└─────────────────────────┬───────────────────────────────────┘
                          │  Handoff: Terraform creates
                          │  COCO_DE_DEMO_PIPELINE_WH_DEV
                          │  before DCM runs.
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  DCM owns (database-level, inside COCO_DE_DEMO)             │
│                                                             │
│  • Schemas              (DEFINE SCHEMA)                     │
│  • Tables               (DEFINE TABLE)                      │
│  • Views / Dynamic Tables (DEFINE VIEW / DYNAMIC TABLE)     │
│  • Stored procedures    (DEFINE PROCEDURE)                  │
│  • Task DAGs            (DEFINE TASK)                       │
│  • Database roles       (DEFINE DATABASE ROLE)              │
│  • Grants within the DB (GRANT ... TO DATABASE ROLE)        │
│  • Data quality         (DEFINE DATA METRIC FUNCTION)       │
└─────────────────────────────────────────────────────────────┘
```

The split avoids the most common conflict: Terraform is well-suited to
account-level bootstrapping (users, warehouses, auth), while DCM excels at
declarative, version-controlled management of database objects with
dependency resolution and safe plan/deploy cycles.

## Module Structure

```
terraform/
├── provider.tf                        # Snowflake provider config
├── modules/
│   ├── snowflake_warehouses/          # Reusable warehouse module
│   │   ├── main.tf
│   │   └── variables.tf
│   └── snowflake_account_roles/       # Service account roles module
│       ├── main.tf
│       └── variables.tf
└── environments/
    ├── dev/                           # AU_DEV + UK_DEV settings
    │   ├── main.tf
    │   └── terraform.tfvars
    └── prod/                          # AU_PROD + UK_PROD settings
        ├── main.tf
        └── terraform.tfvars
```

## Applying

```bash
# Dev
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Prod
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Terraform >= 1.5
- Snowflake Terraform provider `Snowflake-Labs/snowflake` >= 0.98
- Snowflake credentials exported as environment variables:
  ```bash
  export SNOWFLAKE_ACCOUNT=SFSEAPAC-AU_DEMO70
  export SNOWFLAKE_USER=TERRAFORM_SVC
  export SNOWFLAKE_PRIVATE_KEY_PATH=~/.snowflake/terraform_key.pem
  ```
