-- =============================================================================
-- access.sql — Roles, warehouse, and grants for COCO_DE_DEMO
--
-- Pattern: three-tier database roles + one account role for warehouse access.
-- Warehouse size is driven by the manifest templating block ({{ wh_size }}),
-- so DEV deploys XSMALL, STAGING deploys SMALL, and PROD deploys LARGE.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Warehouse
-- Warehouse names are account-level; env_suffix differentiates DEV/STG/PROD
-- when multiple environments share the same account.
-- ---------------------------------------------------------------------------
DEFINE WAREHOUSE COCO_DE_DEMO_PIPELINE_WH{{ env_suffix }}
WITH
    WAREHOUSE_SIZE = '{{ wh_size }}'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'COCO_DE_DEMO pipeline compute — size controlled per environment via manifest templating';

-- ---------------------------------------------------------------------------
-- Account role for warehouse access
-- Database roles CANNOT hold warehouse grants (Snowflake constraint).
-- This account role bridges that gap.
-- ---------------------------------------------------------------------------
DEFINE ROLE COCO_DE_DEMO_WH_USER{{ env_suffix }}
    COMMENT = 'Grants USAGE on COCO_DE_DEMO_PIPELINE_WH{{ env_suffix }} to project users';

GRANT USAGE ON WAREHOUSE COCO_DE_DEMO_PIPELINE_WH{{ env_suffix }} TO ROLE COCO_DE_DEMO_WH_USER{{ env_suffix }};
GRANT ROLE COCO_DE_DEMO_WH_USER{{ env_suffix }} TO ROLE SYSADMIN;

-- ---------------------------------------------------------------------------
-- Three-tier database roles
-- ANALYST → DEVELOPER → ADMIN (each inherits from the tier below it)
-- ---------------------------------------------------------------------------
DEFINE DATABASE ROLE COCO_DE_DEMO.ANALYST
    COMMENT = 'Read-only access to Silver and Gold layers';

DEFINE DATABASE ROLE COCO_DE_DEMO.DEVELOPER
    COMMENT = 'Read/write access to Bronze; inherits ANALYST privileges';

DEFINE DATABASE ROLE COCO_DE_DEMO.ADMIN
    COMMENT = 'Full DDL access to all schemas; inherits DEVELOPER privileges';

-- Role hierarchy
GRANT DATABASE ROLE COCO_DE_DEMO.ANALYST   TO DATABASE ROLE COCO_DE_DEMO.DEVELOPER;
GRANT DATABASE ROLE COCO_DE_DEMO.DEVELOPER TO DATABASE ROLE COCO_DE_DEMO.ADMIN;
GRANT DATABASE ROLE COCO_DE_DEMO.ADMIN     TO ROLE SYSADMIN;

-- ---------------------------------------------------------------------------
-- Database-level grants
-- ---------------------------------------------------------------------------

-- Database usage (required before any schema or object access)
GRANT USAGE ON DATABASE COCO_DE_DEMO TO DATABASE ROLE COCO_DE_DEMO.ANALYST;

-- Schema usage
GRANT USAGE ON SCHEMA COCO_DE_DEMO.SILVER TO DATABASE ROLE COCO_DE_DEMO.ANALYST;
GRANT USAGE ON SCHEMA COCO_DE_DEMO.GOLD   TO DATABASE ROLE COCO_DE_DEMO.ANALYST;
GRANT USAGE ON SCHEMA COCO_DE_DEMO.BRONZE TO DATABASE ROLE COCO_DE_DEMO.DEVELOPER;
GRANT USAGE ON SCHEMA COCO_DE_DEMO.DCM    TO DATABASE ROLE COCO_DE_DEMO.DEVELOPER;

-- Object grants: ANALYST (read-only on Silver + Gold)
GRANT SELECT ON ALL TABLES IN SCHEMA COCO_DE_DEMO.SILVER TO DATABASE ROLE COCO_DE_DEMO.ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA COCO_DE_DEMO.GOLD   TO DATABASE ROLE COCO_DE_DEMO.ANALYST;

-- Object grants: DEVELOPER (read/write on Bronze; inherits SELECT from ANALYST)
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA COCO_DE_DEMO.BRONZE TO DATABASE ROLE COCO_DE_DEMO.DEVELOPER;

-- Schema-level DDL: ADMIN only
GRANT CREATE TABLE, CREATE VIEW, CREATE DYNAMIC TABLE ON SCHEMA COCO_DE_DEMO.BRONZE TO DATABASE ROLE COCO_DE_DEMO.ADMIN;
GRANT CREATE TABLE, CREATE VIEW, CREATE DYNAMIC TABLE ON SCHEMA COCO_DE_DEMO.SILVER TO DATABASE ROLE COCO_DE_DEMO.ADMIN;
GRANT CREATE TABLE, CREATE VIEW, CREATE DYNAMIC TABLE ON SCHEMA COCO_DE_DEMO.GOLD   TO DATABASE ROLE COCO_DE_DEMO.ADMIN;
