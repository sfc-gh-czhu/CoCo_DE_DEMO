-- Validation Gate 1: Bronze to Silver
DEFINE PROCEDURE COCO_DE_DEMO.BRONZE.SP_VALIDATE_BRONZE()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Gate 1: Validates Bronze tables for null PKs, empty tables, duplicates'
AS
$$
DECLARE
    v_result VARCHAR DEFAULT 'PASS';
    v_details VARCHAR DEFAULT '';
    v_count NUMBER;
BEGIN
    -- Check for empty tables
    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.CUSTOMERS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'CUSTOMERS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.ORDERS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'ORDERS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.ORDER_ITEMS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'ORDER_ITEMS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.PRODUCTS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'PRODUCTS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.PAYMENTS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'PAYMENTS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.SHIPMENTS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'SHIPMENTS is empty. ';
    END IF;

    -- Check for null primary keys
    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.CUSTOMERS WHERE CUSTOMER_ID IS NULL;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'CUSTOMERS has ' || v_count || ' null PKs. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.BRONZE.ORDERS WHERE ORDER_ID IS NULL;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'ORDERS has ' || v_count || ' null PKs. ';
    END IF;

    -- Check for duplicate primary keys
    SELECT COUNT(*) - COUNT(DISTINCT CUSTOMER_ID) INTO :v_count FROM COCO_DE_DEMO.BRONZE.CUSTOMERS;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'CUSTOMERS has ' || v_count || ' duplicate PKs. ';
    END IF;

    SELECT COUNT(*) - COUNT(DISTINCT ORDER_ID) INTO :v_count FROM COCO_DE_DEMO.BRONZE.ORDERS;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'ORDERS has ' || v_count || ' duplicate PKs. ';
    END IF;

    IF (v_result = 'PASS') THEN
        RETURN 'GATE 1 PASSED: All Bronze tables valid';
    ELSE
        RETURN 'GATE 1 FAILED: ' || v_details;
    END IF;
END;
$$;

-- Validation Gate 2: Silver to Gold
DEFINE PROCEDURE COCO_DE_DEMO.SILVER.SP_VALIDATE_SILVER()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Gate 2: Validates referential integrity and data quality in Silver'
AS
$$
DECLARE
    v_result VARCHAR DEFAULT 'PASS';
    v_details VARCHAR DEFAULT '';
    v_count NUMBER;
BEGIN
    -- Check referential integrity: orders -> customers
    SELECT COUNT(*) INTO :v_count
    FROM COCO_DE_DEMO.SILVER.STG_ORDERS o
    LEFT JOIN COCO_DE_DEMO.SILVER.STG_CUSTOMERS c ON o.CUSTOMER_ID = c.CUSTOMER_ID
    WHERE c.CUSTOMER_ID IS NULL;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || v_count || ' orders with invalid customer_id. ';
    END IF;

    -- Check referential integrity: order_items -> orders
    SELECT COUNT(*) INTO :v_count
    FROM COCO_DE_DEMO.SILVER.STG_ORDER_ITEMS oi
    LEFT JOIN COCO_DE_DEMO.SILVER.STG_ORDERS o ON oi.ORDER_ID = o.ORDER_ID
    WHERE o.ORDER_ID IS NULL;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || v_count || ' order_items with invalid order_id. ';
    END IF;

    -- Check referential integrity: order_items -> products
    SELECT COUNT(*) INTO :v_count
    FROM COCO_DE_DEMO.SILVER.STG_ORDER_ITEMS oi
    LEFT JOIN COCO_DE_DEMO.SILVER.STG_PRODUCTS p ON oi.PRODUCT_ID = p.PRODUCT_ID
    WHERE p.PRODUCT_ID IS NULL;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || v_count || ' order_items with invalid product_id. ';
    END IF;

    -- Check for negative amounts
    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.SILVER.STG_ORDERS WHERE TOTAL_AMOUNT < 0;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || v_count || ' orders with negative amounts. ';
    END IF;

    IF (v_result = 'PASS') THEN
        RETURN 'GATE 2 PASSED: Silver data integrity verified';
    ELSE
        RETURN 'GATE 2 FAILED: ' || v_details;
    END IF;
END;
$$;

-- Validation Gate 3: Gold certification
DEFINE PROCEDURE COCO_DE_DEMO.GOLD.SP_CERTIFY_GOLD()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Gate 3: Certifies Gold tables are populated and consistent'
AS
$$
DECLARE
    v_result VARCHAR DEFAULT 'PASS';
    v_details VARCHAR DEFAULT '';
    v_count NUMBER;
BEGIN
    -- Check Gold tables are populated
    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.GOLD.DIM_CUSTOMERS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'DIM_CUSTOMERS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.GOLD.DIM_PRODUCTS;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'DIM_PRODUCTS is empty. ';
    END IF;

    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.GOLD.FACT_SALES;
    IF (v_count = 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'FACT_SALES is empty. ';
    END IF;

    -- Check no null keys in Gold
    SELECT COUNT(*) INTO :v_count FROM COCO_DE_DEMO.GOLD.DIM_CUSTOMERS WHERE CUSTOMER_ID IS NULL;
    IF (v_count > 0) THEN
        v_result := 'FAIL';
        v_details := v_details || 'DIM_CUSTOMERS has null keys. ';
    END IF;

    IF (v_result = 'PASS') THEN
        RETURN 'GATE 3 PASSED: Gold data certified';
    ELSE
        RETURN 'GATE 3 FAILED: ' || v_details;
    END IF;
END;
$$;

-- Placeholder procedures for dbt execution (will call native dbt project)
DEFINE PROCEDURE COCO_DE_DEMO.SILVER.SP_RUN_DBT_SILVER()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Executes dbt Silver models via native dbt project'
AS
$$
BEGIN
    EXECUTE IMMEDIATE 'ALTER DBT PROJECT COCO_DE_DEMO.SILVER.DBT_PROJECT EXECUTE SELECTOR silver_models';
    RETURN 'dbt Silver models executed successfully';
END;
$$;

DEFINE PROCEDURE COCO_DE_DEMO.GOLD.SP_RUN_DBT_GOLD()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Executes dbt Gold models via native dbt project'
AS
$$
BEGIN
    EXECUTE IMMEDIATE 'ALTER DBT PROJECT COCO_DE_DEMO.GOLD.DBT_PROJECT EXECUTE SELECTOR gold_models';
    RETURN 'dbt Gold models executed successfully';
END;
$$;
