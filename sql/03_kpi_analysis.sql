-- ============================================================================
-- Rekova Consumer Care — 03_kpi_analysis.sql
-- The business questions from the project brief, answered in SQL.
-- Feed: the staging views created in 02. Every query below is what powers one
-- dashboard page or one bullet of the 1-page insight summary.
-- ============================================================================

-- ============================================================================
-- B1. Monthly net sales trend + YoY %  (Executive overview headline)
-- ============================================================================
WITH m AS (
    SELECT dd.year, dd.month_num, SUM(s.net_sales) AS net
    FROM v_sellout_clean s
    JOIN dim_date dd USING (month_start)
    GROUP BY dd.year, dd.month_num
)
SELECT c.year, c.month_num,
       ROUND(c.net / 10000000.0, 2)                              AS net_sales_cr,
       ROUND(100.0 * (c.net - p.net) / NULLIF(p.net, 0), 1)      AS yoy_pct
FROM m c
LEFT JOIN m p
       ON p.year = c.year - 1 AND p.month_num = c.month_num
ORDER BY c.year, c.month_num;

-- ============================================================================
-- B2. Latest month: achievement vs target (ABS%) by region x channel
--     -> THE recurring sales-review KPI this project replaces Excel with
-- ============================================================================
WITH s AS (
    SELECT month_start, region, channel_type, SUM(net_sales) AS net
    FROM v_sellout_clean
    WHERE month_start = (SELECT MAX(month_start) FROM v_sellout_clean)
    GROUP BY month_start, region, channel_type
),
t AS (
    SELECT month_start, region, channel_type, target_net_sales AS tgt
    FROM fact_targets
    WHERE month_start = (SELECT MAX(month_start) FROM v_sellout_clean)
)
SELECT s.region, s.channel_type,
       ROUND(s.net / 10000000.0, 2)                          AS net_sales_cr,
       ROUND(t.tgt / 10000000.0, 2)                          AS target_cr,
       ROUND(100.0 * (s.net - t.tgt) / NULLIF(t.tgt, 0), 1)   AS abs_pct
FROM s
JOIN t USING (month_start, region, channel_type)
ORDER BY s.region, s.channel_type;

-- ============================================================================
-- B3. SKU Pareto — which SKUs carry the business (running share of revenue, LTM)
-- ============================================================================
WITH ltm_start AS (
    SELECT date(MAX(month_start), '-11 months') AS d
    FROM v_sellout_clean
),
sku_rev AS (
    SELECT s.sku_id, d.sku_name, d.brand, SUM(s.net_sales) AS rev
    FROM v_sellout_clean s
    JOIN dim_product d USING (sku_id)
    WHERE s.month_start >= (SELECT d FROM ltm_start)
    GROUP BY s.sku_id, d.sku_name, d.brand
),
r AS (
    SELECT sku_id, sku_name, brand, rev,
           SUM(rev) OVER (ORDER BY rev DESC)                                   AS cum_rev,
           SUM(rev) OVER (ORDER BY rev DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)       AS total_rev
    FROM sku_rev
)
SELECT sku_id, sku_name, brand,
       ROUND(rev / 100000.0, 1)                                    AS rev_lakh,
       ROUND(100.0 * cum_rev / total_rev, 1)                       AS cum_share_pct,
       CASE WHEN 100.0 * cum_rev / total_rev <= 80.5
            THEN 'Top-80% SKU' ELSE 'Tail SKU' END                 AS pareto_bucket
FROM r
ORDER BY rev DESC;

-- ============================================================================
-- B4. Channel mix last 12 months (E-comm growth story lives here)
-- ============================================================================
WITH ltm_start AS (
    SELECT date(MAX(month_start), '-11 months') AS d FROM v_sellout_clean
)
SELECT channel_type,
       ROUND(SUM(net_sales) / 10000000.0, 2)                          AS net_sales_cr,
       ROUND(100.0 * SUM(net_sales) /
             (SELECT SUM(net_sales) FROM v_sellout_clean
              WHERE month_start >= (SELECT d FROM ltm_start)), 1)     AS share_pct
FROM v_sellout_clean
WHERE month_start >= (SELECT d FROM ltm_start)
GROUP BY channel_type
ORDER BY net_sales_cr DESC;

-- E-commerce share of net sales, month by month (spot the shift)
WITH ec AS (
    SELECT month_start, SUM(net_sales) AS ec_net
    FROM v_sellout_clean s JOIN dim_distributor dd USING (distributor_id)
    WHERE dd.channel_type = 'E-commerce'
    GROUP BY month_start
),
tot AS (
    SELECT month_start, SUM(net_sales) AS total_net
    FROM v_sellout_clean
    GROUP BY month_start
)
SELECT e.month_start,
       ROUND(100.0 * e.ec_net / t.total_net, 2) AS ecomm_share_pct
FROM ec e
JOIN tot t USING (month_start)
ORDER BY e.month_start;

-- ============================================================================
-- B5. Promo uplift per brand (normalised units, promo vs non-promo months)
--     Interrogation-ready caveat: indicative, NOT causal (no holdout design).
-- ============================================================================
WITH brand_month AS (
    SELECT s.month_start, d.brand, s.channel_type,
           AVG(s.units)      AS avg_units_per_row,
           MAX(s.promo_flag) AS promo_flag
    FROM v_sellout_clean s
    JOIN dim_product d USING (sku_id)
    GROUP BY s.month_start, d.brand, s.channel_type
)
SELECT brand,
       ROUND(AVG(CASE WHEN promo_flag = 1 THEN avg_units_per_row END), 0) AS avg_units_promo_month,
       ROUND(AVG(CASE WHEN promo_flag = 0 THEN avg_units_per_row END), 0) AS avg_units_base_month,
       ROUND(100.0 * (AVG(CASE WHEN promo_flag = 1 THEN avg_units_per_row END)
                    - AVG(CASE WHEN promo_flag = 0 THEN avg_units_per_row END))
                    / NULLIF(AVG(CASE WHEN promo_flag = 0 THEN avg_units_per_row END), 0), 1)
                                                                          AS promo_uplift_pct
FROM brand_month
GROUP BY brand
ORDER BY promo_uplift_pct DESC;

-- ============================================================================
-- B6. Distribution health — weeks of cover per distributor x SKU (latest month)
--     > 6 weeks = overstock alert list for the Head of Distribution.
-- ============================================================================
WITH sold AS (
    SELECT month_start, sku_id, distributor_id, SUM(units) AS u
    FROM v_sellout_clean
    WHERE month_start = (SELECT MAX(month_start) FROM v_sellout_clean)
    GROUP BY month_start, sku_id, distributor_id
),
shipped AS (
    SELECT month_start, sku_id, distributor_id, SUM(units_shipped) AS us
    FROM v_shipments
    WHERE month_start = (SELECT MAX(month_start) FROM v_shipments)
    GROUP BY month_start, sku_id, distributor_id
),
woc AS (
    SELECT so.month_start, so.sku_id, so.distributor_id,
           ROUND(4.33 * sh.us / NULLIF(so.u, 0), 1) AS weeks_of_cover
    FROM sold so
    JOIN shipped sh USING (month_start, sku_id, distributor_id)
)
SELECT w.month_start, w.sku_id, dd.distributor_name, dd.channel_type,
       TRIM(dd.region) AS region, w.weeks_of_cover
FROM woc w
JOIN dim_distributor dd USING (distributor_id)
ORDER BY w.weeks_of_cover DESC
LIMIT 25;

-- ============================================================================
-- B7. Market share — latest month by category: Rekova vs GermX vs Kleenova
-- ============================================================================
SELECT category, manufacturer, brand,
       value_share_pct,
       category_value_mn_inr
FROM fact_retail_audit
WHERE month_start = (SELECT MAX(month_start) FROM fact_retail_audit)
ORDER BY category,
         CASE manufacturer WHEN 'Rekova' THEN 0
                           WHEN 'Competitor A' THEN 1
                           WHEN 'Competitor B' THEN 2
                           ELSE 3 END;

-- Our share trend, last 6 months, by category
SELECT month_start, category, value_share_pct AS rekova_share_pct
FROM fact_retail_audit
WHERE manufacturer = 'Rekova'
  AND month_start >= (SELECT date(MAX(month_start), '-5 months') FROM fact_retail_audit)
ORDER BY category, month_start;

-- ============================================================================
-- B8. Returns view — top offending SKU x month (quality/complaints follow-up)
-- ============================================================================
WITH r AS (
    SELECT month_start, sku_id, -units AS returned_units, -gross_sales AS value_lost
    FROM v_returns
)
SELECT r.month_start, r.sku_id, d.brand,
       r.returned_units, ROUND(r.value_lost / 100000.0, 2) AS value_lost_lakh
FROM r
JOIN dim_product d USING (sku_id)
ORDER BY r.month_start, r.returned_units DESC;

-- ============================================================================
-- B9. Distributor concentration — top distributors' cumulative share (LTM)
-- ============================================================================
WITH ltm AS (
    SELECT date(MAX(month_start), '-11 months') AS d FROM v_sellout_clean
),
per_dist AS (
    SELECT distributor_id, SUM(net_sales) AS net
    FROM v_sellout_clean
    WHERE month_start >= (SELECT d FROM ltm)
    GROUP BY distributor_id
),
ranked AS (
    SELECT distributor_id, net,
           SUM(net) OVER (ORDER BY net DESC) AS cum
    FROM per_dist
)
SELECT dd.distributor_name, dd.channel_type, TRIM(dd.region) AS region,
       ROUND(net / 100000.0, 1)                 AS net_sales_lakh,
       ROUND(100.0 * cum /
             (SELECT SUM(net) FROM per_dist), 1) AS cum_share_pct
FROM ranked
JOIN dim_distributor dd USING (distributor_id)
ORDER BY net DESC;

-- ============================================================================
-- B10. Region x channel revenue grid (latest month) — the "heat" behind B2
-- ============================================================================
WITH s AS (
    SELECT region, channel_type, SUM(net_sales) AS net
    FROM v_sellout_clean
    WHERE month_start = (SELECT MAX(month_start) FROM v_sellout_clean)
    GROUP BY region, channel_type
)
SELECT region,
       ROUND(SUM(CASE WHEN channel_type = 'General Trade' THEN net ELSE 0 END) / 10000000.0, 2) AS gt_cr,
       ROUND(SUM(CASE WHEN channel_type = 'Modern Trade'  THEN net ELSE 0 END) / 10000000.0, 2) AS mt_cr,
       ROUND(SUM(CASE WHEN channel_type = 'E-commerce'    THEN net ELSE 0 END) / 10000000.0, 2) AS ecomm_cr,
       ROUND(SUM(CASE WHEN channel_type = 'Pharmacy'      THEN net ELSE 0 END) / 10000000.0, 2) AS pharma_cr,
       ROUND(SUM(net) / 10000000.0, 2)                                                          AS total_cr
FROM s
GROUP BY region
ORDER BY total_cr DESC;
