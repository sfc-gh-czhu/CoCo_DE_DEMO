import streamlit as st
import pandas as pd
import altair as alt

st.set_page_config(page_title="DE Pipeline Dashboard", layout="wide")

@st.cache_data(ttl=300)
def run_query(sql):
    conn = st.connection("snowflake")
    return conn.query(sql)

# --- TAB SETUP ---
tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "Revenue & Sales", "Customers", "Products & Inventory", "Operations", "Pipeline Health"
])

# ============================================================
# TAB 1: REVENUE & SALES
# ============================================================
with tab1:
    st.header("Revenue & Sales")

    metrics = run_query("""
        SELECT
            SUM(GROSS_REVENUE) AS TOTAL_REVENUE,
            SUM(TOTAL_ORDERS) AS TOTAL_ORDERS,
            SUM(UNIQUE_CUSTOMERS) AS UNIQUE_CUSTOMERS,
            ROUND(SUM(GROSS_REVENUE) / NULLIF(SUM(TOTAL_ORDERS), 0), 2) AS AVG_ORDER_VALUE
        FROM COCO_DE_DEMO.GOLD.FACT_DAILY_REVENUE
    """)

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Revenue", f"${metrics['TOTAL_REVENUE'].iloc[0]:,.0f}")
    c2.metric("Total Orders", f"{metrics['TOTAL_ORDERS'].iloc[0]:,.0f}")
    c3.metric("Unique Customers", f"{metrics['UNIQUE_CUSTOMERS'].iloc[0]:,.0f}")
    c4.metric("Avg Order Value", f"${metrics['AVG_ORDER_VALUE'].iloc[0]:,.2f}")

    st.subheader("Daily Gross Revenue")
    daily_rev = run_query("""
        SELECT REVENUE_DATE, GROSS_REVENUE
        FROM COCO_DE_DEMO.GOLD.FACT_DAILY_REVENUE
        ORDER BY REVENUE_DATE
    """)
    chart_area = alt.Chart(daily_rev).mark_area(opacity=0.6, color="#29B5E8").encode(
        x=alt.X("REVENUE_DATE:T", title="Date"),
        y=alt.Y("GROSS_REVENUE:Q", title="Gross Revenue ($)")
    ).properties(height=300)
    st.altair_chart(chart_area, use_container_width=True)

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Monthly Revenue by Order Status")
        monthly = run_query("""
            SELECT
                DATE_TRUNC('MONTH', o.ORDER_DATE)::DATE AS MONTH,
                o.STATUS,
                SUM(o.TOTAL_AMOUNT) AS REVENUE
            FROM COCO_DE_DEMO.SILVER.STG_ORDERS o
            GROUP BY 1, 2
            ORDER BY 1
        """)
        chart_bar = alt.Chart(monthly).mark_bar().encode(
            x=alt.X("MONTH:T", title="Month"),
            y=alt.Y("REVENUE:Q", title="Revenue ($)", stack="zero"),
            color=alt.Color("STATUS:N", title="Order Status")
        ).properties(height=300)
        st.altair_chart(chart_bar, use_container_width=True)

    with col_right:
        st.subheader("Orders by Sales Channel")
        channel = run_query("""
            SELECT CHANNEL, COUNT(*) AS ORDER_COUNT
            FROM COCO_DE_DEMO.SILVER.STG_ORDERS
            GROUP BY 1
        """)
        chart_donut = alt.Chart(channel).mark_arc(innerRadius=50).encode(
            theta=alt.Theta("ORDER_COUNT:Q"),
            color=alt.Color("CHANNEL:N", title="Channel"),
            tooltip=["CHANNEL", "ORDER_COUNT"]
        ).properties(height=300)
        st.altair_chart(chart_donut, use_container_width=True)

    st.subheader("Daily Orders vs Customers")
    daily_trend = run_query("""
        SELECT REVENUE_DATE, TOTAL_ORDERS, UNIQUE_CUSTOMERS
        FROM COCO_DE_DEMO.GOLD.FACT_DAILY_REVENUE
        ORDER BY REVENUE_DATE
    """)
    melted = daily_trend.melt("REVENUE_DATE", var_name="Metric", value_name="Count")
    chart_line = alt.Chart(melted).mark_line().encode(
        x=alt.X("REVENUE_DATE:T", title="Date"),
        y=alt.Y("Count:Q", title="Count"),
        color=alt.Color("Metric:N", title="Legend")
    ).properties(height=250)
    st.altair_chart(chart_line, use_container_width=True)

# ============================================================
# TAB 2: CUSTOMERS
# ============================================================
with tab2:
    st.header("Customers")

    cust_metrics = run_query("""
        SELECT
            COUNT(*) AS TOTAL_CUSTOMERS,
            ROUND(AVG(LIFETIME_SPEND), 2) AS AVG_LIFETIME_SPEND,
            ROUND(AVG(AVG_ORDER_VALUE), 2) AS AVG_ORDER_VALUE
        FROM COCO_DE_DEMO.GOLD.DIM_CUSTOMERS
    """)

    c1, c2, c3 = st.columns(3)
    c1.metric("Total Customers", f"{cust_metrics['TOTAL_CUSTOMERS'].iloc[0]:,}")
    c2.metric("Avg Lifetime Spend", f"${cust_metrics['AVG_LIFETIME_SPEND'].iloc[0]:,.2f}")
    c3.metric("Avg Order Value", f"${cust_metrics['AVG_ORDER_VALUE'].iloc[0]:,.2f}")

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Total Spend by Segment")
        seg_spend = run_query("""
            SELECT SEGMENT, SUM(LIFETIME_SPEND) AS TOTAL_SPEND
            FROM COCO_DE_DEMO.GOLD.DIM_CUSTOMERS
            GROUP BY 1 ORDER BY 2 DESC
        """)
        chart_seg = alt.Chart(seg_spend).mark_bar(color="#29B5E8").encode(
            x=alt.X("SEGMENT:N", title="Segment", sort="-y"),
            y=alt.Y("TOTAL_SPEND:Q", title="Total Spend ($)")
        ).properties(height=300)
        st.altair_chart(chart_seg, use_container_width=True)

    with col_right:
        st.subheader("Loyalty Tier Distribution")
        loyalty = run_query("""
            SELECT LOYALTY_TIER, COUNT(*) AS CUSTOMER_COUNT
            FROM COCO_DE_DEMO.GOLD.DIM_CUSTOMERS
            GROUP BY 1
        """)
        chart_loyalty = alt.Chart(loyalty).mark_arc(innerRadius=50).encode(
            theta=alt.Theta("CUSTOMER_COUNT:Q"),
            color=alt.Color("LOYALTY_TIER:N", title="Loyalty Tier"),
            tooltip=["LOYALTY_TIER", "CUSTOMER_COUNT"]
        ).properties(height=300)
        st.altair_chart(chart_loyalty, use_container_width=True)

    st.subheader("Segment Breakdown")
    seg_detail = run_query("""
        SELECT SEGMENT, LOYALTY_TIER, COUNT(*) AS CUSTOMERS,
               ROUND(AVG(LIFETIME_SPEND), 2) AS AVG_SPEND,
               ROUND(AVG(TOTAL_ORDERS), 1) AS AVG_ORDERS
        FROM COCO_DE_DEMO.GOLD.DIM_CUSTOMERS
        GROUP BY 1, 2 ORDER BY 1, 2
    """)
    st.dataframe(seg_detail, use_container_width=True)

# ============================================================
# TAB 3: PRODUCTS & INVENTORY
# ============================================================
with tab3:
    st.header("Products & Inventory")

    prod_metrics = run_query("""
        SELECT
            COUNT(*) AS TOTAL_PRODUCTS,
            ROUND(AVG(UNIT_PRICE), 2) AS AVG_PRICE,
            SUM(CASE WHEN IS_LOW_STOCK THEN 1 ELSE 0 END) AS LOW_STOCK_COUNT
        FROM COCO_DE_DEMO.GOLD.DIM_PRODUCTS
    """)

    c1, c2, c3 = st.columns(3)
    c1.metric("Total Products", f"{prod_metrics['TOTAL_PRODUCTS'].iloc[0]}")
    c2.metric("Avg Price", f"${prod_metrics['AVG_PRICE'].iloc[0]:,.2f}")
    c3.metric("Low Stock Count", f"{prod_metrics['LOW_STOCK_COUNT'].iloc[0]}")

    st.subheader("Top 15 Products by Revenue")
    top_prods = run_query("""
        SELECT PRODUCT_NAME, CATEGORY, TOTAL_REVENUE, TOTAL_UNITS_SOLD, SALES_TIER
        FROM COCO_DE_DEMO.GOLD.DIM_PRODUCTS
        ORDER BY TOTAL_REVENUE DESC
        LIMIT 15
    """)
    st.dataframe(top_prods, use_container_width=True)

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Revenue by Category")
        cat_rev = run_query("""
            SELECT CATEGORY, SUM(TOTAL_REVENUE) AS REVENUE
            FROM COCO_DE_DEMO.GOLD.DIM_PRODUCTS
            GROUP BY 1 ORDER BY 2 DESC
        """)
        chart_cat = alt.Chart(cat_rev).mark_bar(color="#29B5E8").encode(
            x=alt.X("REVENUE:Q", title="Revenue ($)"),
            y=alt.Y("CATEGORY:N", title="Category", sort="-x")
        ).properties(height=300)
        st.altair_chart(chart_cat, use_container_width=True)

    with col_right:
        st.subheader("Low Stock Alerts (< 10 units)")
        low_stock = run_query("""
            SELECT PRODUCT_NAME, CATEGORY, BRAND, STOCK_QUANTITY, TOTAL_UNITS_SOLD
            FROM COCO_DE_DEMO.GOLD.DIM_PRODUCTS
            WHERE STOCK_QUANTITY < 10
            ORDER BY STOCK_QUANTITY ASC
        """)
        if low_stock.empty:
            st.info("No products below 10 units in stock.")
        else:
            st.dataframe(low_stock, use_container_width=True)

# ============================================================
# TAB 4: OPERATIONS
# ============================================================
with tab4:
    st.header("Operations")

    ops_metrics = run_query("""
        SELECT
            COUNT(*) AS TOTAL_SHIPMENTS,
            ROUND(AVG(CASE WHEN IS_DELIVERED AND NOT IS_DELAYED THEN 1.0 ELSE 0.0 END) * 100, 1) AS ON_TIME_RATE,
            ROUND(AVG(DELIVERY_DAYS), 1) AS AVG_DELIVERY_DAYS
        FROM COCO_DE_DEMO.SILVER.STG_SHIPMENTS
        WHERE DELIVERY_DATE IS NOT NULL
    """)
    pay_metrics = run_query("""
        SELECT ROUND(AVG(PAYMENT_SUCCESS_RATE), 1) AS SUCCESS_RATE
        FROM COCO_DE_DEMO.GOLD.FACT_PAYMENT_SUMMARY
    """)

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Shipments", f"{ops_metrics['TOTAL_SHIPMENTS'].iloc[0]:,}")
    c2.metric("On-Time Delivery", f"{ops_metrics['ON_TIME_RATE'].iloc[0]}%")
    c3.metric("Avg Delivery Days", f"{ops_metrics['AVG_DELIVERY_DAYS'].iloc[0]}")
    c4.metric("Payment Success Rate", f"{pay_metrics['SUCCESS_RATE'].iloc[0]}%")

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Shipments by Carrier")
        carrier = run_query("""
            SELECT CARRIER, COUNT(*) AS SHIPMENT_COUNT
            FROM COCO_DE_DEMO.SILVER.STG_SHIPMENTS
            GROUP BY 1 ORDER BY 2 DESC
        """)
        chart_carrier = alt.Chart(carrier).mark_bar(color="#29B5E8").encode(
            x=alt.X("CARRIER:N", title="Carrier", sort="-y"),
            y=alt.Y("SHIPMENT_COUNT:Q", title="Shipments")
        ).properties(height=300)
        st.altair_chart(chart_carrier, use_container_width=True)

    with col_right:
        st.subheader("Shipping Speed Distribution")
        speed = run_query("""
            SELECT SHIPPING_SPEED, COUNT(*) AS CNT
            FROM COCO_DE_DEMO.SILVER.STG_SHIPMENTS
            GROUP BY 1
        """)
        chart_speed = alt.Chart(speed).mark_arc(innerRadius=50).encode(
            theta=alt.Theta("CNT:Q"),
            color=alt.Color("SHIPPING_SPEED:N", title="Speed"),
            tooltip=["SHIPPING_SPEED", "CNT"]
        ).properties(height=300)
        st.altair_chart(chart_speed, use_container_width=True)

    st.subheader("Payment Health")
    pay_health = run_query("""
        SELECT PAYMENT_OUTCOME, COUNT(*) AS ORDER_COUNT,
               ROUND(AVG(TOTAL_AMOUNT_COMPLETED), 2) AS AVG_AMOUNT
        FROM COCO_DE_DEMO.GOLD.FACT_PAYMENT_SUMMARY
        GROUP BY 1 ORDER BY 2 DESC
    """)

    col_left2, col_right2 = st.columns(2)
    with col_left2:
        st.dataframe(pay_health, use_container_width=True)
    with col_right2:
        chart_pay = alt.Chart(pay_health).mark_bar().encode(
            x=alt.X("PAYMENT_OUTCOME:N", title="Outcome", sort="-y"),
            y=alt.Y("ORDER_COUNT:Q", title="Orders"),
            color=alt.Color("PAYMENT_OUTCOME:N", legend=None)
        ).properties(height=250)
        st.altair_chart(chart_pay, use_container_width=True)

# ============================================================
# TAB 5: PIPELINE HEALTH
# ============================================================
with tab5:
    st.header("Pipeline Health")

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("RFM Segment Distribution")
        rfm = run_query("""
            SELECT RFM_SEGMENT, COUNT(*) AS CUSTOMER_COUNT
            FROM COCO_DE_DEMO.GOLD.CUSTOMER_RFM_SCORES
            GROUP BY 1 ORDER BY 2 DESC
        """)
        chart_rfm = alt.Chart(rfm).mark_bar(color="#29B5E8").encode(
            x=alt.X("RFM_SEGMENT:N", title="Segment", sort="-y"),
            y=alt.Y("CUSTOMER_COUNT:Q", title="Customers")
        ).properties(height=300)
        st.altair_chart(chart_rfm, use_container_width=True)

    with col_right:
        st.subheader("Anomaly Detection Summary")
        anomalies = run_query("""
            SELECT ANOMALY_TYPE, COUNT(*) AS ANOMALY_COUNT
            FROM COCO_DE_DEMO.SILVER.ANOMALY_FLAGS
            GROUP BY 1 ORDER BY 2 DESC
        """)
        if anomalies.empty:
            st.info("No anomalies detected.")
        else:
            st.dataframe(anomalies, use_container_width=True)

    st.subheader("Pipeline Row Counts by Layer")
    pipeline = run_query("""
        SELECT LAYER, TABLE_NAME, ROW_COUNT
        FROM COCO_DE_DEMO.GOLD.PIPELINE_RUN_SUMMARY
        ORDER BY LAYER, TABLE_NAME
    """)
    color_map = {"BRONZE": "#CD7F32", "SILVER": "#C0C0C0", "GOLD": "#FFD700"}
    chart_pipeline = alt.Chart(pipeline).mark_bar().encode(
        x=alt.X("TABLE_NAME:N", title="Table", sort=None),
        y=alt.Y("ROW_COUNT:Q", title="Row Count"),
        color=alt.Color("LAYER:N", scale=alt.Scale(
            domain=list(color_map.keys()), range=list(color_map.values())
        ), title="Layer"),
        tooltip=["LAYER", "TABLE_NAME", "ROW_COUNT"]
    ).properties(height=350)
    st.altair_chart(chart_pipeline, use_container_width=True)

    st.subheader("Bronze Data Profile")
    profile = run_query("""
        SELECT TABLE_NAME, COLUMN_NAME, ROW_COUNT, NULL_COUNT, NULL_PERCENT, DISTINCT_COUNT
        FROM COCO_DE_DEMO.BRONZE.DATA_PROFILE_LOG
        ORDER BY TABLE_NAME, COLUMN_NAME
    """)
    st.dataframe(profile, use_container_width=True, height=400)
