-- ============================================================================
-- Rekova Consumer Care — 01_create_schema.sql  (SQLite)
-- ----------------------------------------------------------------------------
-- HOW TO IMPORT THE 7 CSV FILES (data/raw/)
--   Option A — DB Browser for SQLite (recommended, free):
--       1. Run this script once (Execute SQL tab → run all) to create empty tables.
--       2. File → Import → Table from CSV file → select e.g. fact_sellout_monthly.csv
--          → tick "First line contains column names"
--          → "Insert into existing table" → choose the matching table name below.
--       3. Repeat for all 7 files.
--   Option B — sqlite3 CLI:
--       .open rekova.db
--       -- .import --csv --skip 1 data/raw/dim_product.csv dim_product
--       -- .import --csv --skip 1 data/raw/dim_distributor.csv dim_distributor
--       -- .import --csv --skip 1 data/raw/dim_date.csv dim_date
--       -- .import --csv --skip 1 data/raw/fact_sellout_monthly.csv fact_sellout_monthly
--       -- .import --csv --skip 1 data/raw/fact_shipments_monthly.csv fact_shipments_monthly
--       -- .import --csv --skip 1 data/raw/fact_retail_audit.csv fact_retail_audit
--       -- .import --csv --skip 1 data/raw/fact_targets.csv fact_targets
-- ============================================================================

DROP VIEW IF EXISTS v_sellout_clean;
DROP VIEW IF EXISTS v_returns;
DROP VIEW IF EXISTS v_shipments;
DROP TABLE IF EXISTS fact_sellout_monthly;
DROP TABLE IF EXISTS fact_shipments_monthly;
DROP TABLE IF EXISTS fact_retail_audit;
DROP TABLE IF EXISTS fact_targets;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_distributor;
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_product (
    sku_id      TEXT PRIMARY KEY,
    sku_name    TEXT,
    brand       TEXT,
    category    TEXT,
    pack_size   TEXT,
    mrp         REAL
);

CREATE TABLE dim_distributor (
    distributor_id    TEXT PRIMARY KEY,
    distributor_name  TEXT,
    channel_type      TEXT,   -- General Trade / Modern Trade / E-commerce / Pharmacy
    region            TEXT,   -- North / South / East / West / National  (watch for whitespace!)
    city_tier         INTEGER
);

CREATE TABLE dim_date (
    month_start TEXT PRIMARY KEY,   -- 'YYYY-MM-01'
    year        INTEGER,
    month_num   INTEGER,
    month_name  TEXT,
    quarter     TEXT
);

CREATE TABLE fact_sellout_monthly (
    month_start        TEXT,
    sku_id             TEXT,
    distributor_id     TEXT,
    units              INTEGER,     -- may be NEGATIVE on returns rows
    gross_sales        REAL,
    net_sales          REAL,        -- may be NULL on some rows -> must be derived
    promo_flag         INTEGER,     -- 1 = month was part of a trade promotion
    promo_discount_pct REAL
);

CREATE INDEX idx_sellout_month      ON fact_sellout_monthly (month_start);
CREATE INDEX idx_sellout_sku        ON fact_sellout_monthly (sku_id);
CREATE INDEX idx_sellout_distributor ON fact_sellout_monthly (distributor_id);

CREATE TABLE fact_shipments_monthly (
    month_start     TEXT,
    sku_id          TEXT,
    distributor_id  TEXT,
    units_shipped   INTEGER
);
CREATE INDEX idx_ship_month ON fact_shipments_monthly (month_start);

CREATE TABLE fact_retail_audit (
    month_start          TEXT,
    category             TEXT,
    brand                TEXT,
    manufacturer         TEXT,   -- Rekova / Competitor A / Competitor B / Long tail
    value_share_pct      REAL,
    category_value_mn_inr REAL
);

CREATE TABLE fact_targets (
    month_start      TEXT,
    region           TEXT,
    channel_type     TEXT,
    target_net_sales REAL
);
