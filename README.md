# Rekova Consumer Care — Sales & Distribution Analytics
### An end-to-end SQL + Power BI case study simulating a real FMCG client engagement

[![GitHub](https://img.shields.io/badge/GitHub-vibhapotabatti%2Frekova--sales--analytics-181717?logo=github)](https://github.com/vibhapotabatti/rekova-sales-analytics)

> **What this is:** a portfolio project that simulates the kind of analytics engagement a
> global hygiene & health FMCG company (a "Reckitt-style" client) would run with its IT/data
> partner. Client name, brands and all numbers are **fictional**, generated locally by you.
> **What this is not:** real client work. Present it exactly like that (see
> `docs/resume_and_interview_guide.md`) — it reads STRONGER when framed honestly, and it is
> grounded in the genuine domain exposure you already have from your current Infosys account.
>
> **Companion project:** the [demand-forecasting & promo-analytics extension](https://github.com/vibhapotabatti/rekova-demand-forecasting)
> — same simulated client, same data, Python modelling on top.
> **Engineering flagship:** the [Airflow + dbt + DuckDB data platform](https://github.com/vibhapotabatti/rekova-data-platform)
> takes the same data through a scheduled, tested production pipeline.

---

## Business problem (the story you open with)

Rekova's Sales Director reviews performance monthly, but:
- sell-out (distributor retail sales) and sell-in (shipments to distributors) live in different files, so **channel inventory is invisible** — overstocked distributors silently eat credit limits;
- achievement vs target (ABS%) is compiled in Excel per region and is always 3 weeks late;
- the team has **no view of market share vs competitors** when planning promotions;
- nobody knows which SKUs actually drive 80% of revenue, and which are pure tail.

This project answers all four with a proper data pipeline + dashboard.

## Repository structure

```
rekova-sales-analytics/
├── README.md                          <- you are here
├── data/raw/                          <- generated CSVs (NEVER committed)
├── scripts/
│   └── generate_client_data.py        <- generates 24 months of realistic client data
├── sql/
│   ├── 01_create_schema.sql           <- tables + how to import the CSVs
│   ├── 02_data_quality_and_staging.sql<- DQ checks + cleaned staging views
│   └── 03_kpi_analysis.sql            <- the business questions, answered in SQL
├── powerbi/
│   ├── dashboard_plan.md              <- data model + page-by-page dashboard spec
│   └── dax_measures.dax               <- measure library (copy into Power BI)
└── docs/
    ├── project_brief.md               <- the "client project charter" (mimics real intake)
    └── resume_and_interview_guide.md  <- honest resume/LinkedIn framing + interview prep
```

## Quickstart (4 steps)

1. **Generate the data** (needs only Python 3.8+, no libraries):
   ```powershell
   python scripts\generate_client_data.py
   ```
   Writes 7 CSVs to `data/raw/` (24 months: Oct-2024 → Sep-2026).

2. **Create the database:** download **DB Browser for SQLite** (free) → New Database →
   open `sql/01_create_schema.sql` in its *Execute SQL* tab and run it (creates tables),
   then import each CSV in `data/raw/` via *File → Import → Table from CSV file*,
   choosing the matching existing table. Then run `02_data_quality_and_staging.sql`
   and `03_kpi_analysis.sql`.

3. **Build the dashboard in Power BI Desktop (free)** following `powerbi/dashboard_plan.md`
   (import the same CSVs directly, model them per the plan, paste measures from
   `dax_measures.dax`).

4. **Write your 1-page insight summary** from `docs/project_brief.md`'s output template —
   this is what you actually discuss in interviews, more than the dashboard itself.

## Data dictionary

| File | Grain | Key columns |
|---|---|---|
| `dim_product` | 1 row = SKU | sku_id, sku_name, brand, category, pack_size, mrp |
| `dim_distributor` | 1 row = distributor | distributor_id, channel_type (GT/MT/EC/PH), region, city_tier |
| `dim_date` | 1 row = month | month_start, year, month_num, month_name, quarter |
| `fact_sellout_monthly` | SKU × distributor × month | units, gross_sales, net_sales, promo_flag, promo_discount_pct |
| `fact_shipments_monthly` | SKU × distributor × month | units_shipped (sell-in) |
| `fact_retail_audit` | brand × category × month | value_share_pct, category_value_mn_inr (incl. competitors) |
| `fact_targets` | region × channel × month | target_net_sales |

Synthetic brands (categories): **Shieldon** (Antiseptics), **PureGerm** (Disinfectants),
**FloKleen** (Toilet Care), **Stainex** (Fabric Care), **AirPure** (Air Care),
**ThroatEase** (Cough & Throat). Competitors in the retail audit: *GermX* (global rival)
and *Kleenova* (local value brand).

## Deliberate data-quality issues (built into the generator)

Real client feeds are never clean — so yours isn't either. After generating, `02` will catch:

1. duplicate sell-out rows (~0.4%)
2. `net_sales` missing on some rows (~0.5%) → must be derived
3. negative `units` = product returns (~0.3%)
4. trailing-space region names (`"North "` vs `"North"`) breaking region joins
5. 2 rows referencing SKU `P99` that doesn't exist in `dim_product` (orphan keys)
6. one distributor-month with a missing file extract

Finding, explaining and fixing **these six specific issues** in an interview is worth more
than any chart — it is exactly what a support-to-data person does daily.

## 4-week build plan (≈2 evenings/week)

| Week | Deliverable |
|---|---|
| 1 | Generate data → run every DQ query → write staging views → run all KPI queries |
| 2 | Power BI data model + DAX measures + Page 1 (Executive overview) |
| 3 | Pages 2–4 (Brand deep-dive, Distribution health, Market share) + polish |
| 4 | Insight summary PDF, GitHub polish (screenshots, README badges), LinkedIn post |

## Do-Not list

- Do **not** use any real Infosys/Reckitt data, file, template or dashboard layout.
- Do **not** name the real client in public posts — say *"a leading global hygiene & health
  FMCG client I support at Infosys"* (check your employment/confidentiality policy first).
- Do **not** fork tutorial repos — everything here is generated and written by you.
