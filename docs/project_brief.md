# Project Brief — Rekova Sales & Distribution Analytics
> **Status: SIMULATED engagement for portfolio purposes.** Rekova Consumer Care Ltd., its
> brands and all figures are fictional. The domain, KPIs and workflow mirror real FMCG
> analytics engagements so the project reads like genuine client work.

## 1. Client background (fictional)
Rekova Consumer Care Ltd. is a global hygiene & health consumer goods company operating in
India through a distributor network (General Trade), modern-trade chains, pharmacies and
e-commerce. Portfolio spans antiseptics, surface disinfectants, toilet care, fabric care,
air care and cough & throat remedies.

## 2. Business problem
- Sell-out and sell-in data arrive as separate monthly Excel extracts → channel inventory
  (weeks of cover) is invisible; overstocking consumes distributor credit limits.
- Achievement vs target (ABS%) is a manual regional Excel exercise, ~3 weeks late.
- No standing view of market share vs key competitors ahead of promo planning.
- No SKU-level revenue concentration analysis → tail SKUs never rationalized.

## 3. Objectives (SMART)
1. Replace the 3-week manual ABS% cycle with a self-serve dashboard (target: same-day).
2. Give sales leadership distributor-level weeks-of-cover with an overstock alert list.
3. Establish a monthly market-share view by category vs GermX / Kleenova.
4. Quantify promo uplift per brand–channel to guide next-cycle promo selection.
5. Produce a SKU Pareto to focus field effort on the top ~80% revenue SKUs.

## 4. Scope
**In:** SQL data pipeline (cleaning + KPIs), Power BI semantic model & 4-page dashboard,
15-measure DAX library, 1-page insight summary for the business review.
**Out:** live ERP integration, row-level security by user, forecasting (phase 2).

## 5. Stakeholders (fictional)
| Role | Care-about |
|---|---|
| Sales Director (sponsor) | ABS% by region, promo ROI |
| Head of Distribution | distributor inventory, returns |
| Category Managers | brand & SKU mix, market share |
| FP&A | target definition integrity, net sales reconciliation |

## 6. Data sources (all synthetic)
- Distributor ERP extract → `fact_sellout_monthly`, `fact_shipments_monthly` (CSV)
- Syndicated retail audit (Nielsen-style) → `fact_retail_audit`
- FP&A target file → `fact_targets`
- Reference data → `dim_product`, `dim_distributor`, `dim_date`

## 7. Timeline (6 weeks, part-time)
W1 draft pipeline → W2 semantic model → W3 pages 1–2 → W4 pages 3–4 + measures QA →
W5 insight summary + review walkthrough → W6 (buffer) documentation & handover.

## 8. Success criteria
- All 6 known data-quality defects detected & resolved in staging, with a note for each.
- KPI values reconcile between SQL outputs and Power BI (±0.1%).
- Dashboard loads < 5s; every visual answers one named business question.

## 9. Output template — the 1-page insight summary
1. **Headline:** one sentence with the number that matters (e.g. "Net sales ran 96.4% of
   target in FY25; over-indexing in E-comm (+18% YoY) offsets GT misses in East (-9%).")
2. **What happened** — trend, ABS% by region/channel, the three biggest variances.
3. **Why it happened** — promo calendar effects, inventory build-ups (WoC), share moves
   vs competitors.
4. **So what / recommendation** — 3 actions a Sales Director would actually take.
5. **Caveats** — data-quality notes, what this does not capture.

*(Fill this in with YOUR numbers after running `sql/03_kpi_analysis.sql` — hiring managers
can instantly tell real analysis from template fluff.)*
