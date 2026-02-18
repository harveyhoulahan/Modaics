# Demand Model Training Playbook

This guide shows how to bootstrap predictive insights for brands by training a sell-through classifier that scores whether a listing will convert within a configurable time window. The baseline leans on the existing CLIP embeddings in `fashion_items` plus light metadata.

## What this baseline does
- Pulls **positives** from completed `transactions` and **negatives** from older listings without a completed sale.
- Uses the 768-dimension CLIP embedding from `fashion_items` and appends price, sustainability score, and hashed brand/category/platform signals.
- Trains a **balanced logistic regression** and reports ROC-AUC/accuracy, then saves a reusable pipeline.

## Prerequisites
- Postgres with the `fashion_items` + `transactions` tables populated (see `database/init.sql`).
- Embeddings stored in the `embedding` column for each item (created by the existing ingestion flow).
- Python dependencies installed:
  ```bash
  pip install -r backend/requirements.txt
  ```

## Run the training script
From the repo root:
```bash
python backend/train_demand_model.py --horizon_days 45 --max_unsold 5000
```
Arguments:
- `--horizon_days`: How far back to look for completed sales and how old an item must be to count as “unsold” (default 45 days).
- `--max_unsold`: Cap on negative samples to keep the dataset balanced (default 5,000).

Outputs:
- Metrics printed to stdout (ROC-AUC, accuracy, classification report).
- Serialized model at `backend/models/demand_model.joblib`.

## How to use the model
- Load the joblib pipeline in the backend and feed it the same feature stack: CLIP embedding + [price, sustainability_score, brand_hash, category_hash, platform_hash].
- Return the probability of sale within `horizon_days` as the **Projected Sell-Through** score in brand dashboards.
- Add guardrails (e.g., block production if score < 0.35) or upsell Enterprise with custom thresholds.

## Hardening ideas for better accuracy
1. **Richer negatives:** Mark listings as negative only after `horizon_days` have elapsed without a sale; include swap/rental outcomes separately.
2. **Temporal features:** Add seasonality (month, region) and recency (age in days) before training.
3. **Category-aware models:** Train per-category models when there’s enough volume to avoid cross-category leakage.
4. **Human-in-the-loop labels:** Let brand managers override projected demand and feed overrides back into retraining.
5. **Calibration:** Monitor predicted vs. actual sell-through weekly; add Platt scaling or isotonic regression if the probabilities are miscalibrated.
6. **Enrich embeddings:** Concatenate text embeddings from titles/descriptions to capture stylistic cues missing from images.
7. **Price sensitivity:** Log-transform price and add a “discount depth” feature when items sell below list.
8. **Sustainability lift:** Include `is_verified_sustainable` and certification tags to measure badge impact on conversion.

## Next steps to productize
- Expose an internal endpoint that loads `demand_model.joblib`, scores new designs before production, and stores forecasts per item.
- Surface the top comparable items (from `search.py`) alongside the score for explainability.
- Auto-trigger retraining monthly with fresh transactions and save the artifact with a date-stamped filename for rollbacks.
