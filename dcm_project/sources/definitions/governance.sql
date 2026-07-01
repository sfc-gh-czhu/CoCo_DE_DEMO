-- Governance Tags

-- Pipeline Layer tag
DEFINE TAG COCO_DE_DEMO.DCM.PIPELINE_LAYER
    COMMENT = 'Identifies which medallion layer a table belongs to';

-- Data Classification tag
DEFINE TAG COCO_DE_DEMO.DCM.DATA_CLASSIFICATION
    COMMENT = 'Data sensitivity classification';

-- PII tag
DEFINE TAG COCO_DE_DEMO.DCM.PII
    COMMENT = 'Identifies columns containing personally identifiable information';

-- Data Domain tag
DEFINE TAG COCO_DE_DEMO.DCM.DATA_DOMAIN
    COMMENT = 'Business domain of the table';

-- Quality Tier tag
DEFINE TAG COCO_DE_DEMO.DCM.QUALITY_TIER
    COMMENT = 'Data quality tier based on pipeline layer';
