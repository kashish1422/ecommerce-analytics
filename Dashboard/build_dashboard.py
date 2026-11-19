"""Build the Olist e-commerce web dashboard.

Reads the processed tables produced by Python/olist_analysis.ipynb, packs them
into a compact columnar JSON payload, and injects it into
dashboard_template.html to create a single self-contained index.html.

Usage (from the repository root, after running the notebook):
    python Dashboard/build_dashboard.py
"""

from pathlib import Path
import base64
import json

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
PROCESSED = ROOT / "Data" / "Processed"
HERE = Path(__file__).resolve().parent

REGIONS = {
    "North": ["AC", "AM", "AP", "PA", "RO", "RR", "TO"],
    "Northeast": ["AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"],
    "Center-West": ["DF", "GO", "MS", "MT"],
    "Southeast": ["ES", "MG", "RJ", "SP"],
    "South": ["PR", "RS", "SC"],
}
SEGMENTS = ["Loyal repeat", "Lapsed repeat", "New high-value", "New low-value",
            "Cooling", "At-risk high-value", "Hibernating"]


def codes(series: pd.Series, labels: list) -> list:
    lookup = {label: i for i, label in enumerate(labels)}
    return series.map(lookup).astype(int).tolist()


def main() -> None:
    orders = pd.read_csv(PROCESSED / "orders_clean.csv", parse_dates=["order_purchase_timestamp"])
    rfm = pd.read_csv(PROCESSED / "customers_rfm.csv", usecols=["customer_unique_id", "segment", "r_score", "m_score"])

    orders = orders.sort_values("order_purchase_timestamp").reset_index(drop=True)
    orders = orders.merge(rfm, on="customer_unique_id", how="left")
    if orders["segment"].isna().any():
        raise ValueError("Every order's customer must have an RFM segment.")

    # Customer sequence features (computed on the full dataset)
    grp = orders.groupby("customer_unique_id")
    orders["order_number"] = grp.cumcount() + 1
    prev = grp["order_purchase_timestamp"].shift()
    orders["gap_days"] = (orders["order_purchase_timestamp"].dt.normalize() - prev.dt.normalize()).dt.days.fillna(-1).astype(int)

    months = sorted(orders["purchase_month"].unique())
    first_month = grp["purchase_month"].transform("min")
    state_to_region = {s: r for r, states in REGIONS.items() for s in states}
    states = sorted(orders["customer_state"].unique())
    missing = set(states) - set(state_to_region)
    if missing:
        raise ValueError(f"States without a region: {missing}")

    cat_rank = orders.groupby("main_category")["order_value"].sum().sort_values(ascending=False).index.tolist()
    pay_types = orders["payment_type"].fillna("unknown").value_counts().index.tolist()
    customer_ids = {cid: i for i, cid in enumerate(orders["customer_unique_id"].unique())}

    payload = {
        "meta": {"orders": int(len(orders)), "start": months[0], "end": months[-1]},
        "dims": {
            "months": months, "states": states,
            "stateRegion": [state_to_region[s] for s in states],
            "regions": list(REGIONS), "categories": cat_rank,
            "payTypes": pay_types, "segments": SEGMENTS,
        },
        "cols": {
            "mo": codes(orders["purchase_month"], months),
            "fm": codes(first_month, months),
            "st": codes(orders["customer_state"], states),
            "cat": codes(orders["main_category"], cat_rank),
            "pt": codes(orders["payment_type"].fillna("unknown"), pay_types),
            "seg": codes(orders["segment"], SEGMENTS),
            "r": orders["r_score"].astype(int).tolist(),
            "m": orders["m_score"].astype(int).tolist(),
            "cu": orders["customer_unique_id"].map(customer_ids).tolist(),
            "val": (orders["order_value"] * 100).round().astype(int).tolist(),          # cents
            "dd": (orders["delivery_days"] * 10).round().astype(int).tolist(),          # tenths of a day
            "dl": orders["delay_days"].astype(int).tolist(),
            "late": orders["is_late"].astype(int).tolist(),
            "rs": orders["review_score"].fillna(0).astype(int).tolist(),                # 0 = no review
            "ins": orders["installments"].fillna(1).astype(int).tolist(),
            "on": orders["order_number"].clip(upper=3).tolist(),
            "gap": orders["gap_days"].tolist(),
        },
    }

    template = (HERE / "dashboard_template.html").read_text(encoding="utf-8")

    # Embed the subset web fonts (SIL Open Font License, see fonts/) so the page works offline.
    fonts = {"bitter": "bitter.woff", "fira400": "fira-Regular.woff", "fira500": "fira-Medium.woff", "fira600": "fira-SemiBold.woff"}
    for key, file in fonts.items():
        b64 = base64.b64encode((HERE / "fonts" / file).read_bytes()).decode()
        template = template.replace(f"__FONT_{key}__", f"data:font/woff;base64,{b64}")
    marker = "/*__DATA__*/null"
    if marker not in template:
        raise ValueError("Data marker not found in template.")
    out = HERE / "index.html"
    out.write_text(template.replace(marker, json.dumps(payload, separators=(",", ":"))), encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)} ({len(orders):,} orders, {out.stat().st_size / 1024:,.0f} KB)")


if __name__ == "__main__":
    main()
