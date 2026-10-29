# Resume, LinkedIn & Interview Guide (the honesty playbook)

This project only works for you if it is framed truthfully. The truthful framing is plenty
strong — you ARE supporting a leading global hygiene & health FMCG account at Infosys, so
your domain understanding is real. The build is real. Only the client identity/data is
fictional, and you will say so up front.

## What to write on the resume

**Resume bullet (project section — not under Infosys employment history):**

> **Sales & Distribution Analytics — FMCG Case Study (SQL, Power BI)**
> Designed an end-to-end analytics solution for a simulated hygiene-FMCG client, modeled on
> the domain I support at Infosys. Pipeline ingests monthly sell-out, sell-in, retail-audit
> and target feeds (SQLite + SQL: deduplication, orphan keys, derive missing measures),
> serves 15 DAX measures and a 4-page dashboard covering achievement-vs-target (ABS%),
> distributor weeks-of-cover, promo uplift and competitor market share.

**What NOT to write / do:**
- Never list it under your Infosys experience or imply Infosys delivered it.
- Never claim the client is real. Interviewers WILL probe ("what was the stakeholder's
  feedback?") — a truthful "it's a simulation I designed" + confident walk-through survives
  every panel; a lie does not survive question 2.
- Never mention the real client's name in public artifacts, screenshots or posts. If your
  policy allows at all, cap it at "a leading global hygiene & health FMCG client I support
  at Infosys" — and verify with your manager/HR first.
- Never reference real file names, layout or data from your actual account — global design
  similarity is fine, replication is not.

## LinkedIn post template (edit honestly)

> 🔎 New portfolio project: I built an end-to-end SQL + Power BI analytics solution for a
> SIMULATED hygiene & health FMCG client.
> Why this domain? Because I spend my days supporting a leading FMCG account — so I built the
> sales review I wish that business had: sell-out vs sell-in (weeks of cover), ABS% vs
> target, promo uplift, competitor share…
> 24 months of synthetic-but-realistic data (incl. the messy bits real feeds have),
> 15 DAX measures, 4 dashboard pages, all documented on GitHub: <link>
> #analytics #powerbi #sql #fmcg #dataanalyst

## Interview prep — learn to answer these cold

1. "Define ABS%. Why is net sales (not gross) compared to target?"
2. "Sell-out vs sell-in — what does weeks of cover > 6 on a distributor tell you,
   and what action follows?" (retry / stop replenishing / promo? honestly: pull back
   shipments, not push new promo into the channel)
3. "Walk me through your data-quality fixes" — name all six defects and the exact fix.
4. "How did you compute promo uplift credibly?" (compare normalized units promo vs
   non-promo months per brand-channel; call out that it is indicative, not causal — no
   counterfactual/holdout in this design)
5. "Which visual disappointed you, and what did you change?" (shows design judgment)
6. "If the client asked for daily sell-out tomorrow, what changes?" (grain, refresh,
   incremental load — bridge toward data-engineering talk)

## Positioning for your switch

- Title yourself by the skill you're proving: "Data Analyst (transitioning from 4 yrs
  IT support @ Infosys)" on LinkedIn headline, with keywords SQL / Power BI / Excel / Python.
- This is Project 1 of a 3-project ladder; next ones: Python analytics/forecast project,
  then an end-to-end pipeline (dbt/Airflow) — that ladder covers analyst AND
  entry data-engineer screening.
