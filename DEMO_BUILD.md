# Demo Build Script: Prompts 1-7 (20 minutes)

Run these prompts sequentially in Cortex Code CLI after executing `teardown.sql`.
Each prompt is self-contained. Timing estimates assume the `agents.md` file is in your working directory.

---

## Pre-Demo Checklist

```bash
# 1. Run teardown (do this 5 min before going live)
snow sql -f teardown.sql -c sfseapac-au_demo70

# 2. Verify clean state
snow sql -q "SHOW DATABASES LIKE 'COCO_DE_DEMO'" -c sfseapac-au_demo70
# Should return 0 rows

# 3. Start Cortex Code in the repo directory
cd /Users/czhu/Documents/GitHub/CoCo_DE_DEMO
cortex
```

---

## Prompt 1: Foundation & DCM Project Setup (~3 min)

> **What the audience sees:** Database, schemas, file format created. DCM project initialized.

```
Create a Snowflake database called COCO_DE_DEMO with four schemas: BRONZE for raw data, SILVER for cleaned and validated data, GOLD for analytics-ready data, and DCM for the Database Change Management project. Also create a reusable CSV file format in the Bronze schema that handles headers, quoted fields, and common null representations.

Set up a DCM project registered as COCO_DE_DEMO.DCM.PIPELINE_PROJECT using the Snowflake CLI (snow dcm create). Create the local project structure with a manifest.yml and definition files under sources/definitions/. The DCM project will declaratively manage all infrastructure objects (schemas, tables, file formats, tags, tasks, procedures, DMFs, and data quality expectations). Objects not supported by DCM's DEFINE syntax — specifically the storage integration, external stage, CDC streams, and Snowpipe pipes — should be placed in companion scripts (pre_deploy.sql and post_deploy.sql) at the project root. The dbt project remains a separate deployment (hybrid approach).
```

**Talking point while it runs:** "DCM is Snowflake's native declarative infrastructure management — like Terraform but purpose-built for Snowflake objects. We're separating infrastructure (DCM) from transformations (dbt)."

---

## Prompt 2: S3 Integration (~1.5 min)

> **What the audience sees:** Storage integration and external stage created.

```
Create a storage integration for secure access to our S3 bucket at s3://coco-d4bdemo-de/assets/ using the IAM role arn:aws:iam::484577546576:role/coco-d4bdemo-role. Then create an external stage in the Bronze schema that points to this bucket and uses the CSV file format we created. After creating the integration, show me the Snowflake IAM user ARN and external ID so I can configure the AWS trust policy.
```

**Talking point:** "The storage integration is an account-level object — it establishes the trust relationship between Snowflake and AWS once, then all stages can reference it."

---

## Prompt 3: Bronze Landing Tables (~3 min)

> **What the audience sees:** 6 Bronze tables created via DCM definitions, deployed with `snow dcm deploy`.

```
Create 6 Bronze tables to receive the raw CSV data. The tables should match the CSV column structures: customers (with customer_id, first_name, last_name, email, phone, city, state, zip_code, segment, created_at), orders (order_id, customer_id, order_date, status, sales_channel, total_amount), order_items (order_item_id, order_id, product_id, quantity, unit_price, discount), products (product_id, product_name, category, subcategory, brand, list_price, cost_price, stock_quantity), payments (payment_id, order_id, payment_method, amount, payment_date, status), and shipments (shipment_id, order_id, carrier, tracking_number, ship_date, delivery_date, status). Enable CHANGE_TRACKING on all tables and set DATA_METRIC_SCHEDULE to 60 minutes. Define these tables in the DCM project's sources/definitions/bronze_tables.sql and deploy via snow dcm deploy.
```

**Talking point:** "Notice it's writing DEFINE TABLE statements, not CREATE TABLE. DCM is declarative — you describe the desired state, and `snow dcm deploy` figures out what needs to change. Version-controlled, auditable, repeatable."

---

## Prompt 4: Automated Ingestion with Snowpipe (~2 min)

> **What the audience sees:** 6 Snowpipe pipes created with pattern matching, then refreshed to load data.

```
Create Snowpipe auto-ingest pipes for all 6 Bronze tables. Use pattern matching instead of exact file paths so the pipes accept versioned files — for example, both customers.csv and customers_v2.csv should be picked up by the customers pipe. After creating the pipes, refresh them to load any files already in the stage.
```

**Talking point:** "Snowpipe auto-ingest means data flows in automatically when new files land in S3. The pattern matching means we don't need to update pipe definitions when file naming conventions evolve."

---

## Prompt 5: Change Data Capture Streams (~1.5 min)

> **What the audience sees:** 6 CDC streams created on Bronze tables.

```
Create CDC streams on all 6 Bronze tables. Enable them to capture existing rows (not just future changes) so the pipeline can process the initial data load.
```

**Talking point:** "Streams are the event-driven trigger for our pipeline. When new data arrives in Bronze, the streams flag it, and our task DAG picks it up. SHOW_INITIAL_ROWS means we capture the data we just loaded via Snowpipe."

---

## Prompt 6: dbt Transformations (~5 min)

> **What the audience sees:** Complete dbt project generated — 6 Silver staging models, 7 Gold analytics models, schema.yml with tests.

```
Generate a complete dbt project with two layers of models:

Silver staging models for all 6 tables — clean nulls, standardize formats, and add useful derived columns. For example: customer tenure in days, full name, email domain; order day-of-week, days since order, high-value flags; line item discount percentage and margin analysis; product price tiers and margin percentages; payment method grouping and timing; shipment delivery days and shipping speed classification.

Gold analytics models:
- A customer dimension with loyalty tiers based on order count, lifetime spend, average order value, and cancellation rate
- A product dimension with sales performance tiers, stock analysis, and margin classification
- A date dimension covering the full date range in the data
- A sales fact table joining orders, line items, and products
- A daily revenue fact with breakdowns by sales channel and order status
- A payment summary fact with payment outcomes per order
- A shipment performance fact with delivery metrics

Include comprehensive tests in schema.yml — unique and not_null on all primary keys, relationship tests for all foreign keys, and accepted_values tests for status fields, tiers, and segments.
```

**Talking point:** "This is where dbt shines over DCM. Transformations need modular SQL with `ref()`, lineage tracking, and testable contracts. One prompt just generated 13 models with full test coverage. In a traditional workflow this is days of work."

---

## Prompt 7: Deploy dbt to Snowflake (~3 min)

> **What the audience sees:** dbt project deployed as native Snowflake object, executed, Silver+Gold tables materialized.

```
Deploy the dbt project to Snowflake as a native dbt project object and execute it to create all the Silver and Gold tables.
```

**Talking point:** "Native dbt projects in Snowflake mean your transformations run inside the platform — no external orchestrator needed. The Silver and Gold tables just materialized. We can query them right now."

---

## Post-Demo Verification (Optional, ~30 sec)

If you want to show proof the pipeline works, paste this after Prompt 7 completes:

```
Show me the row counts across all Bronze, Silver, and Gold tables to prove the pipeline ran end to end.
```

Expected output:
- Bronze: 285 customers, 570 orders, 1744 order_items, 115 products, 650 payments, 354 shipments
- Silver: Same counts (cleaned)
- Gold: 285 dim_customers, 115 dim_products, 259 dim_dates, 606 fact_sales, etc.

---

## Timing Budget

| Prompt | Est. Time | Cumulative |
|--------|-----------|------------|
| 1 - Foundation + DCM | 3 min | 3 min |
| 2 - S3 Integration | 1.5 min | 4.5 min |
| 3 - Bronze Tables (DCM) | 3 min | 7.5 min |
| 4 - Snowpipe | 2 min | 9.5 min |
| 5 - CDC Streams | 1.5 min | 11 min |
| 6 - dbt Generation | 5 min | 16 min |
| 7 - dbt Deploy + Execute | 3 min | 19 min |
| Verification query | 0.5 min | 19.5 min |
| **Buffer** | **0.5 min** | **20 min** |

---

## If Running Behind Schedule

**Cut Prompt 4 (Snowpipe):** Say "Snowpipe auto-ingest is straightforward — I'll skip it and load data directly with COPY INTO for the demo." Then in Prompt 5, the streams will still work on the tables.

**Combine Prompts 4+5:** Merge into a single prompt:
```
Create Snowpipe auto-ingest pipes and CDC streams for all 6 Bronze tables. Use pattern matching for pipes. Enable streams to capture existing rows. Refresh pipes to load data.
```

---

## If Something Fails

- **DCM deploy fails:** Fall back to direct SQL: `snow sql -f sql/01_foundation.sql -c sfseapac-au_demo70`
- **dbt deploy fails:** The `sql/` directory has equivalent imperative scripts as backup
- **Snowpipe refresh shows 0 rows:** Data might need time to load. Run `COPY INTO` directly from the stage as fallback.
