-- ============================================================================
-- Rekova Consumer Care — 02_data_quality_and_staging.sql
-- Run AFTER the CSVs are imported.
-- Part A verifies the 6 known feed defects. Part B builds the staging views
-- that every downstream KPI uses. In an interview: THIS file is your credibility.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PART A — DATA QUALITY CHECKS (each corresponds to a defect the generator injects)
-- ----------------------------------------------------------------------------

-- F0. File completeness: expected 12 / 27 / 24 rows and no NULL keys
SELECT 'dim_product'     AS tbl, COUNT(*) AS rows   FROM dim_product
UNION ALL SELECT 'dim_distributor', COUNT(*) FROM dim_distributor
UNION ALL SELECT 'dim_date',        COUNT(*) FROM dim_date
UNION ALL SELECT 'fact_sellout_monthly',  COUNT(*) FROM fact_sellout_monthly
UNION ALL SELECT 'fact_shipments_monthly',COUNT(*) FROM fact_shipments_monthly
UNION ALL SELECT 'fact_retail_audit',     COUNT(*) FROM fact_retail_audit
UNION ALL SELECT 'fact_targets',          COUNT(*) FROM fact_targets;

-- DQ1. Duplicate sell-out rows (defect 1)
SELECT month_start, sku_id, distributor_id, units, gross_sales,
       COALESCE(net_sales, -1) AS net_sales, promo_flag, COUNT(*) AS copies
FROM fact_sellout_monthly
GROUP BY month_start, sku_id, distributor_id, units, gross_sales,
         COALESCE(net_sales, -1), promo_flag, promo_discount_pct
HAVING COUNT(*) > 1;

-- DQ2. Missing net_sales (defect 2) — count + the product categories hit
SELECT sku_id, COUNT(*) AS missing_net_rows
FROM fact_sellout_monthly
WHERE net_sales IS NULL
GROUP BY sku_id;

-- DQ3. Returns booked as negative units (defect 3)
SELECT COUNT(*) AS return_rows, SUM(units) AS returned_units
FROM fact_sellout_monthly
WHERE units < 0;

-- DQ4. Orphan SKUs (defect 5) — facts pointing to no product master row
SELECT s.month_start, s.sku_id, s.distributor_id, s.units
FROM fact_sellout_monthly s
LEFT JOIN dim_product p USING (sku_id)
WHERE p.sku_id IS NULL;

-- DQ5. Whitespace-damaged region names (defect 4) — breaks region joins
SELECT distributor_id, distributor_name, '[' || region || ']' AS raw_region
FROM dim_distributor
WHERE region <> TRIM(region);

-- DQ6. Missing monthly extract (defect 6): any distributor below 24 months
SELECT d.distributor_id, d.distributor_name, COUNT(DISTINCT s.month_start) AS months_present
FROM dim_distributor d
LEFT JOIN fact_sellout_monthly s USING (distributor_id)
GROUP BY d.distributor_id, d.distributor_name
HAVING COUNT(DISTINCT s.month_start) < 24;

-- DQ7. Fact months not present in dim_date (calendar join sanity)
SELECT COUNT(*) AS bad_month_keys
FROM fact_sellout_monthly f
LEFT JOIN dim_date d USING (month_start)
WHERE d.month_start IS NULL;

-- ----------------------------------------------------------------------------
-- PART B — STAGING VIEWS (dedupe, clean, derive, standardize)
-- ----------------------------------------------------------------------------

-- Main cleaned view: deduplicated, positive units only, net_sales derived when
-- the feed dropped it (channel trade discount + promo depth), regions trimmed.
CREATE VIEW IF NOT EXISTS v_sellout_clean AS
WITH dedup AS (
    SELECT f.*,
           ROW_NUMBER() OVER (
               PARTITION BY month_start, sku_id, distributor_id, units,
                            gross_sales, COALESCE(net_sales, -1),
                            promo_flag, promo_discount_pct
               ORDER BY rowid
           ) AS rn
    FROM fact_sellout_monthly f
)
SELECT
    g.month_start,
    g.sku_id,
    g.distributor_id,
    g.units,
    g.gross_sales,
    ROUND(
        CASE
            WHEN g.net_sales IS NOT NULL THEN g.net_sales
            ELSE g.gross_sales
                 * (1 - (CASE dd.channel_type
                             WHEN 'Modern Trade' THEN 0.10
                             WHEN 'Pharmacy'     THEN 0.06
                             WHEN 'E-commerce'   THEN 0.16
                             ELSE 0.12 END)
                 - COALESCE(g.promo_discount_pct, 0) / 100.0)
        END, 2) AS net_sales,
    g.promo_flag,
    g.promo_discount_pct,
    dp.brand,
    dp.category,
    dd.channel_type,
    TRIM(dd.region) AS region,
    dp.mrp
FROM dedup g
JOIN dim_product    dp USING (sku_id)
JOIN dim_distributor dd USING (distributor_id)
WHERE g.rn = 1
  AND g.units > 0;

-- Returns view (negative units), excluded from revenue views on purpose.
CREATE VIEW IF NOT EXISTS v_returns AS
WITH dedup AS (
    SELECT f.*,
           ROW_NUMBER() OVER (
               PARTITION BY month_start, sku_id, distributor_id, units,
                            gross_sales, COALESCE(net_sales, -1)
               ORDER BY rowid
           ) AS rn
    FROM fact_sellout_monthly f
)
SELECT g.month_start, g.sku_id, g.distributor_id, g.units, g.gross_sales,
       TRIM(dd.region) AS region, dd.channel_type
FROM dedup g
JOIN dim_distributor dd USING (distributor_id)
WHERE g.rn = 1
  AND g.units < 0;

-- Shipments (sell-in) flattened view.
CREATE VIEW IF NOT EXISTS v_shipments AS
SELECT s.month_start, s.sku_id, s.distributor_id, s.units_shipped,
       dd.channel_type, TRIM(dd.region) AS region
FROM fact_shipments_monthly s
JOIN dim_distributor dd USING (distributor_id);

-- Post-check: cleaned view volume & the reconciliation of DQ fixes
SELECT 'v_sellout_clean' AS view_name, COUNT(*) AS rows FROM v_sellout_clean
UNION ALL SELECT 'v_returns', COUNT(*) FROM v_returns
UNION ALL SELECT 'v_shipments', COUNT(*) FROM v_shipments;
