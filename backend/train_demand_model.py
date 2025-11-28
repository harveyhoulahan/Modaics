"""
Training script for Modaics' brand-facing demand model.

This baseline uses CLIP embeddings + lightweight metadata to predict
whether a marketplace item will sell within a configurable time window.

Usage:
    python backend/train_demand_model.py --horizon_days 45 --max_unsold 5000

The script:
- pulls positives (completed transactions) and negatives (aged listings without sales)
- filters out rows without embeddings
- trains a class-balanced logistic regression on normalized features
- reports ROC-AUC/accuracy and saves the pipeline to backend/models/demand_model.joblib
"""
from __future__ import annotations

import argparse
import asyncio
import logging
from dataclasses import dataclass
from datetime import timedelta
from pathlib import Path
from typing import Iterable, List, Optional

import asyncpg
import joblib
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from config import DATABASE_URL, EMBEDDING_DIMENSION

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


@dataclass
class ListingRecord:
    embedding: np.ndarray
    price: float
    sustainability_score: float
    brand_hash: float
    category_hash: float
    platform_hash: float
    label: int
    item_id: int
    title: Optional[str]


def _hash_feature(value: Optional[str], modulus: int = 1000) -> float:
    if value is None:
        return 0.0
    return float(abs(hash(value)) % modulus) / float(modulus)


def _build_feature_vector(row: asyncpg.Record, label: int) -> Optional[ListingRecord]:
    embedding = row.get("embedding")
    if embedding is None:
        return None

    vector = np.asarray(embedding, dtype=np.float32)
    if vector.shape[0] != EMBEDDING_DIMENSION:
        logger.debug("Skipping row %s due to unexpected embedding dimension", row.get("id"))
        return None

    price = float(row.get("price") or 0.0)
    sustainability_score = float(row.get("sustainability_score") or 0.0)

    brand_hash = _hash_feature(row.get("brand"))
    category_hash = _hash_feature(row.get("category"))
    platform_hash = _hash_feature(row.get("platform"))

    return ListingRecord(
        embedding=vector,
        price=price,
        sustainability_score=sustainability_score,
        brand_hash=brand_hash,
        category_hash=category_hash,
        platform_hash=platform_hash,
        label=label,
        item_id=row.get("id"),
        title=row.get("title"),
    )


def _stack_features(records: Iterable[ListingRecord]) -> tuple[np.ndarray, np.ndarray]:
    feature_rows: List[np.ndarray] = []
    labels: List[int] = []

    for record in records:
        meta_features = np.array(
            [
                record.price,
                record.sustainability_score,
                record.brand_hash,
                record.category_hash,
                record.platform_hash,
            ],
            dtype=np.float32,
        )
        feature_rows.append(np.concatenate([record.embedding, meta_features]))
        labels.append(record.label)

    return np.vstack(feature_rows), np.asarray(labels, dtype=np.int64)


async def _fetch_records(pool: asyncpg.Pool, horizon_days: int, max_unsold: int) -> list[ListingRecord]:
    positives: list[ListingRecord] = []
    negatives: list[ListingRecord] = []

    async with pool.acquire() as conn:
        completed_rows = await conn.fetch(
            """
            SELECT fi.id, fi.title, fi.brand, fi.category, fi.platform, fi.price,
                   fi.sustainability_score, fi.embedding
            FROM fashion_items fi
            JOIN transactions t ON t.item_id = fi.id
            WHERE t.item_type = 'marketplace'
              AND t.status = 'completed'
              AND t.completed_at >= NOW() - $1::interval
            """,
            timedelta(days=horizon_days),
        )

        stale_rows = await conn.fetch(
            """
            SELECT fi.id, fi.title, fi.brand, fi.category, fi.platform, fi.price,
                   fi.sustainability_score, fi.embedding
            FROM fashion_items fi
            WHERE fi.created_at <= NOW() - $1::interval
              AND NOT EXISTS (
                    SELECT 1
                    FROM transactions t
                    WHERE t.item_id = fi.id
                      AND t.item_type = 'marketplace'
                      AND t.status = 'completed'
              )
            LIMIT $2
            """,
            timedelta(days=horizon_days),
            max_unsold,
        )

    for row in completed_rows:
        record = _build_feature_vector(row, label=1)
        if record:
            positives.append(record)

    for row in stale_rows:
        record = _build_feature_vector(row, label=0)
        if record:
            negatives.append(record)

    logger.info("Loaded %s positives and %s negatives", len(positives), len(negatives))
    return positives + negatives


def _train_pipeline(X: np.ndarray, y: np.ndarray) -> Pipeline:
    model = Pipeline(
        steps=[
            ("scaler", StandardScaler()),
            (
                "clf",
                LogisticRegression(
                    max_iter=500,
                    class_weight="balanced",
                    n_jobs=-1,
                ),
            ),
        ]
    )

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=42)
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    y_scores = model.predict_proba(X_test)[:, 1]

    roc_auc = roc_auc_score(y_test, y_scores)
    acc = accuracy_score(y_test, y_pred)

    logger.info("ROC-AUC: %.3f | Accuracy: %.3f", roc_auc, acc)
    logger.info("Classification report:\n%s", classification_report(y_test, y_pred))

    return model


def _save_model(model: Pipeline, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, path)
    logger.info("Saved demand model to %s", path)


async def main(args: argparse.Namespace) -> None:
    async with asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5) as pool:
        records = await _fetch_records(pool, horizon_days=args.horizon_days, max_unsold=args.max_unsold)

    if len(records) < 50:
        raise ValueError("Not enough samples to train the model. Collect more transactions and unsold listings.")

    X, y = _stack_features(records)
    logger.info("Training on feature matrix with shape %s", X.shape)

    model = _train_pipeline(X, y)
    _save_model(model, Path("backend/models/demand_model.joblib"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Modaics demand forecasting model")
    parser.add_argument("--horizon_days", type=int, default=45, help="Window to consider a sale successful")
    parser.add_argument("--max_unsold", type=int, default=5000, help="Cap on negative samples to prevent imbalance")

    asyncio.run(main(parser.parse_args()))
