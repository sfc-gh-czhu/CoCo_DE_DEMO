-- Pre-deployment script: Objects that must exist before DCM plan
-- Run with: snow sql -f pre_deploy.sql -c sfseapac-au_demo70

USE ROLE ACCOUNTADMIN;

-- Storage integration for S3 access
CREATE STORAGE INTEGRATION IF NOT EXISTS COCO_DE_DEMO_S3_INT
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::484577546576:role/coco-d4bdemo-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://coco-d4bdemo-de/assets/');
