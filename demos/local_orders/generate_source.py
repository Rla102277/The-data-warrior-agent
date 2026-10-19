"""Generate synthetic source CSVs with controlled defects."""

from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "data" / "raw"


def generate() -> Path:
    RAW.mkdir(parents=True, exist_ok=True)
    customers = [
        {"customer_id": "C1", "name": "Ada"},
        {"customer_id": "C2", "name": "Ben"},
        {"customer_id": "C3", "name": "Cara"},
        {"customer_id": "C4", "name": "Drew"},
        {"customer_id": "C5", "name": "Eve"},
    ]
    # 12 logical orders; include one duplicate order_id and one missing customer.
    orders = [
        {"order_id": "O1", "customer_id": "C1", "amount": "100.00", "order_ts": "2026-01-01T10:00:00Z"},
        {"order_id": "O2", "customer_id": "C1", "amount": "50.25", "order_ts": "2026-01-02T10:00:00Z"},
        {"order_id": "O3", "customer_id": "C2", "amount": "200.00", "order_ts": "2026-01-03T10:00:00Z"},
        {"order_id": "O4", "customer_id": "C2", "amount": "75.00", "order_ts": "2026-01-04T10:00:00Z"},
        {"order_id": "O5", "customer_id": "C3", "amount": "125.00", "order_ts": "2026-01-05T10:00:00Z"},
        {"order_id": "O6", "customer_id": "C3", "amount": "80.00", "order_ts": "2026-01-06T10:00:00Z"},
        {"order_id": "O7", "customer_id": "C4", "amount": "220.00", "order_ts": "2026-01-07T10:00:00Z"},
        {"order_id": "O8", "customer_id": "C4", "amount": "40.00", "order_ts": "2026-01-08T10:00:00Z"},
        {"order_id": "O9", "customer_id": "C5", "amount": "90.00", "order_ts": "2026-01-09T10:00:00Z"},
        {"order_id": "O10", "customer_id": "C5", "amount": "110.00", "order_ts": "2026-01-10T10:00:00Z"},
        {"order_id": "O11", "customer_id": "C1", "amount": "60.25", "order_ts": "2026-01-11T10:00:00Z"},
        {"order_id": "O12", "customer_id": "C2", "amount": "100.00", "order_ts": "2026-01-12T10:00:00Z"},
        # Controlled defects (quarantined by transform):
        {"order_id": "O3", "customer_id": "C2", "amount": "200.00", "order_ts": "2026-01-03T10:00:00Z"},  # duplicate
        {"order_id": "O99", "customer_id": "", "amount": "999.00", "order_ts": "2026-01-13T10:00:00Z"},  # missing customer
    ]
    returns = [
        {"return_id": "R1", "order_id": "O1", "amount": "100.00"},
        {"return_id": "R2", "order_id": "O5", "amount": "50.25"},
    ]
    _write(RAW / "customers.csv", customers, ["customer_id", "name"])
    _write(RAW / "orders.csv", orders, ["order_id", "customer_id", "amount", "order_ts"])
    _write(RAW / "returns.csv", returns, ["return_id", "order_id", "amount"])
    return RAW


def _write(path: Path, rows: list[dict[str, str]], fieldnames: list[str]) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    print(generate())
