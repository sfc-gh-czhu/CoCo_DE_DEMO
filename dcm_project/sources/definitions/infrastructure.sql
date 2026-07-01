-- Schemas for medallion architecture
DEFINE SCHEMA COCO_DE_DEMO.BRONZE
    COMMENT = 'Raw data landing zone';

DEFINE SCHEMA COCO_DE_DEMO.SILVER
    COMMENT = 'Cleaned and validated data';

DEFINE SCHEMA COCO_DE_DEMO.GOLD
    COMMENT = 'Analytics-ready data';

-- CSV file format for ingestion
DEFINE FILE FORMAT COCO_DE_DEMO.BRONZE.CSV_FORMAT
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a')
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    COMMENT = 'Reusable CSV format for S3 ingestion';
