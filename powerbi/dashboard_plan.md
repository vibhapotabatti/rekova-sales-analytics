# Power BI Dashboard Plan — "Rekova Sales Command Center"

## Step 1 — Power Query preparation (do this BEFORE modeling)
The raw CSVs still contain the six deliberate feed defects — mirror the SQL staging (02):

1. `fact_sellout_monthly` — "Sales" query:
   - Remove Rows → Remove Duplicates (all columns) — kills the duplicate rows
   - Keep rows where `units > 0` (returns are handled separately below)
   - Types: month_start → Date; units, promo_flag → Whole Number; rest → Decimal Number
2. Right-click the Sales query → Duplicate → rename `Returns` → keep rows where `units < 0`
3. `dim_distributor` — Transform → Format → Trim on `region` (fixes "North " etc.)
4. `dim_date` — month_start → Date
5. `fact_targets`, `fact_shipments_monthly`, `fact_retail_audit` — set types, trim text columns

**Derive the missing net_sales** — inside the Sales query, merge `dim_distributor` to bring in
`channel_type`, then Add Column → Conditional Column:
`if [net_sales] = null then [gross_sales] * (1 − trade_discount − [promo_discount_pct]/100) else [net_sales]`
with trade discounts GT 0.12 / MT 0.10 / PH 0.06 / EC 0.16. Remove the merge step afterwards.

## Step 2 — Star schema (Model view)

Facts: `fact_sellout_monthly` and `fact_shipments_monthly` (grain: SKU × distributor × month),
`fact_targets` (region × channel × month), `fact_retail_audit` (category × brand × month),
`Returns` (SKU × distributor × month).

Relationships (many-to-one, single filter direction):
- fact_sellout_monthly + fact_shipments_monthly → `dim_product[sku_id]`,
  `dim_distributor[distributor_id]`, `dim_date[month_start]`
- fact_targets → `dim_date[month_start]`
- fact_retail_audit → `dim_date[month_start]` (brand/category stay inside the audit fact — it
  compares our brands with competitor labels, so don't force it through the product star)

**Shared region/channel dimensions (so targets and sell-out filter together):** create two
tiny tables in Power Query — `dim_region` = distinct `region` values, `dim_channel` = distinct
`channel_type` values — and add matching `region` / `channel_type` columns to
`fact_sellout_monthly`, `fact_shipments_monthly` and `fact_targets` (merge them from
`dim_distributor` for the sales facts). Relate each fact's `region` → `dim_region[region]` and
`channel_type` → `dim_channel[channel_type]`. Then **hide `dim_distributor[region]` and
`dim_distributor[channel_type]`** in Report view, and slicer by `dim_region` / `dim_channel`
everywhere — otherwise sell-out and target measures disagree the moment you filter.

**Mark `dim_date` as the official date table** (Table view → Mark as date table). Done.

## Page 1 — Executive Overview (the sponsor's page)
- KPI cards: Net Sales (₹ Cr), Sales vs Target % (ABS%), Units, YoY Net Sales %, E-comm share %
- Line+column combo: monthly Net Sales vs Target (target as line)
- Stacked column: Net Sales by channel_type over months
- Bar: Net Sales & ABS% by region (five regions incl. "National")

> WARNING: ABS% is only valid at region × channel grain — the FP&A target feed has no
> brand/SKU columns. Keep target visuals filtered by region/channel; never slice them by brand.

## Page 2 — Brand & Category Deep-Dive (category managers)
- Matrix: brand × month of Net Sales (trend readable at a glance)
- Pareto bar: SKUs sorted by Net Sales with cumulative % line (from your SQL or DAX measure)
- Waterfall / decomposition tree: Net Sales mix by category → brand → SKU, largest first
  (this is a mix view — brand-level ABS% is invalid because targets don't exist per brand)
- Slicer panel: category, brand

## Page 3 — Distribution & Channel Health (Head of Distribution)
- Table: top 15 distributor–SKU pairs by Weeks of Cover (conditional formatting:
  >6 weeks red, 4–6 amber) — from the WoC measure
- Column: Returns units by SKU (negative-quantity fix story lives here)
- Combo: promo_flag months vs Units for selected brand (promo uplift view)
- Export-worthy artifact: the "overstock alert list" IS the deliverable

## Page 4 — Market Share & Competitors
- Clustered bar: our brand share % vs GermX / Kleenova by category (latest month)
- Line: our share % trend by category (drift visible)
- Optional hero visual: scatter (share % vs YoY growth) sized by category value

> Note: the retail audit is national-only — don't apply region/channel filters to this page.

## Design rules (deploy-day polish)
- One palette (teal/grey), 1 font, no 3D, no rainbow; column headers not "Sum of…"
- Every visual has a clear title phrased as the business question it answers
- Top bar slicer strip visible on all pages; a Reset bookmark
- Format units as ₹ Cr (custom format `#,0.00,," Cr"` on lakh-adjusted measures or
  pre-divide by 1e7 in SQL/Power Query — pick one convention and show it in the model)
- Publish: use Publish-to-web ONLY for public links; for GitHub use screenshots/gifs
