-- Silver: Cleaned and standardized products with pricing tiers and margin analysis
-- Source: COCO_DE_DEMO.BRONZE.PRODUCTS

SELECT
    PRODUCT_ID,
    TRIM(PRODUCT_NAME)                                        AS PRODUCT_NAME,
    UPPER(TRIM(CATEGORY))                                     AS CATEGORY,
    UPPER(TRIM(SUBCATEGORY))                                  AS SUBCATEGORY,
    TRIM(BRAND)                                               AS BRAND,
    LIST_PRICE                                                 AS UNIT_PRICE,
    COST_PRICE,
    STOCK_QUANTITY,
    LIST_PRICE - COST_PRICE                                   AS PROFIT_MARGIN,
    ROUND((LIST_PRICE - COST_PRICE) / NULLIF(LIST_PRICE, 0) * 100, 2) AS MARGIN_PCT,
    CASE
        WHEN LIST_PRICE < 200 THEN 'BUDGET'
        WHEN LIST_PRICE < 500 THEN 'MID_RANGE'
        WHEN LIST_PRICE < 800 THEN 'PREMIUM'
        ELSE 'LUXURY'
    END                                                       AS PRICE_TIER,
    CASE
        WHEN STOCK_QUANTITY < 100 THEN TRUE
        ELSE FALSE
    END                                                       AS IS_LOW_STOCK,
    CURRENT_TIMESTAMP()                                       AS _LOADED_AT
FROM COCO_DE_DEMO.BRONZE.PRODUCTS
WHERE PRODUCT_ID IS NOT NULL
  AND LIST_PRICE > 0
  AND COST_PRICE >= 0
