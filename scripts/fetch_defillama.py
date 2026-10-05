import requests
import pandas as pd
from datetime import datetime, timezone
from pathlib import Path

URL = "https://api.llama.fi/protocol/jupiter-lend"
TARGET_DATE = "2025-10-10"

# -----------------------------
# Fetch protocol data
# -----------------------------

response = requests.get(URL, timeout=30)
response.raise_for_status()

data = response.json()

# Useful for checking exactly what DefiLlama returned
print("Available chainTvls keys:")
for key in data["chainTvls"].keys():
    print(" -", key)


# -----------------------------
# Helpers
# -----------------------------

def to_date(unix_ts):
    return datetime.fromtimestamp(unix_ts, tz=timezone.utc).strftime("%Y-%m-%d")


def get_token_snapshot(series, target_date):
    """
    Find the tokensInUsd row matching target_date.
    Expected shape:
    [
        {
            "date": 1234567890,
            "tokens": {
                "SOL": 123456,
                "USDC": 78910
            }
        }
    ]
    """
    for row in series:
        if to_date(row["date"]) == target_date:
            return row

    return None


def get_tvl_snapshot(series, target_date):
    """
    Find total TVL for the requested date.
    """
    for row in series:
        if to_date(row["date"]) == target_date:
            return row["totalLiquidityUSD"]

    return None


# -----------------------------
# Find main Solana TVL series
# -----------------------------

chain_tvls = data["chainTvls"]

# Jupiter Lend is on Solana.
# Prefer the plain Solana entry, excluding borrowed/staking/etc.
solana_key = next(
    key for key in chain_tvls
    if key.lower() == "solana"
)

solana_data = chain_tvls[solana_key]

tvl_asset_snapshot = get_token_snapshot(
    solana_data["tokensInUsd"],
    TARGET_DATE
)

total_tvl = get_tvl_snapshot(
    solana_data["tvl"],
    TARGET_DATE
)

if tvl_asset_snapshot is None:
    raise ValueError(f"No TVL token snapshot found for {TARGET_DATE}")


# -----------------------------
# Find borrowed / active-loan series
# -----------------------------

borrowed_keys = [
    key
    for key in chain_tvls
    if "borrowed" in key.lower()
]

if not borrowed_keys:
    raise ValueError(
        "No borrowed series found. "
        f"Available keys: {list(chain_tvls.keys())}"
    )

print("\nBorrowed series found:")
for key in borrowed_keys:
    print(" -", key)

# Jupiter Lend should normally have one relevant borrowed series.
borrowed_key = borrowed_keys[0]
borrowed_data = chain_tvls[borrowed_key]

borrowed_asset_snapshot = get_token_snapshot(
    borrowed_data["tokensInUsd"],
    TARGET_DATE
)

total_borrowed = get_tvl_snapshot(
    borrowed_data["tvl"],
    TARGET_DATE
)


# -----------------------------
# TVL by asset
# -----------------------------

tvl_df = pd.DataFrame(
    tvl_asset_snapshot["tokens"].items(),
    columns=["asset", "tvl_usd"]
)

tvl_df["pct_of_tvl"] = (
    tvl_df["tvl_usd"] / total_tvl * 100
)

tvl_df = tvl_df.sort_values(
    "tvl_usd",
    ascending=False
).reset_index(drop=True)


# -----------------------------
# Borrowed by asset
# -----------------------------

if borrowed_asset_snapshot is not None:

    borrowed_df = pd.DataFrame(
        borrowed_asset_snapshot["tokens"].items(),
        columns=["asset", "borrowed_usd"]
    )

    borrowed_df["pct_of_borrowed"] = (
        borrowed_df["borrowed_usd"]
        / total_borrowed
        * 100
    )

    borrowed_df = borrowed_df.sort_values(
        "borrowed_usd",
        ascending=False
    ).reset_index(drop=True)

else:
    borrowed_df = None


# -----------------------------
# SOL-linked exposure
# -----------------------------

# Normalize asset names for matching
tvl_df["asset_upper"] = tvl_df["asset"].str.upper()

# Assets treated as directly SOL-linked
sol_linked_assets = [
    "SOL",
    "JUPSOL",
    "JITOSOL",
    "INF",
]

direct_sol_linked_tvl = tvl_df.loc[
    tvl_df["asset_upper"].isin(sol_linked_assets),
    "tvl_usd"
].sum()

direct_sol_linked_pct = (
    direct_sol_linked_tvl / total_tvl * 100
)


# -----------------------------
# Optional: estimated SOL exposure from JLP
# -----------------------------

JLP_SOL_WEIGHT = 0.47

jlp_tvl = tvl_df.loc[
    tvl_df["asset_upper"] == "JLP",
    "tvl_usd"
].sum()

jlp_sol_exposure = jlp_tvl * JLP_SOL_WEIGHT

total_sol_linked_exposure = (
    direct_sol_linked_tvl + jlp_sol_exposure
)

total_sol_linked_exposure_pct = (
    total_sol_linked_exposure / total_tvl * 100
)


# -----------------------------
# Print results
# -----------------------------

print("\nSOL-linked TVL (excluding JLP basket exposure):")
print(f"${direct_sol_linked_tvl:,.2f}")
print(f"{direct_sol_linked_pct:.2f}% of total TVL")

print("\nJLP TVL:")
print(f"${jlp_tvl:,.2f}")

print(f"\nEstimated SOL exposure inside JLP ({JLP_SOL_WEIGHT:.0%}):")
print(f"${jlp_sol_exposure:,.2f}")

print("\nEstimated total SOL-linked exposure including JLP:")
print(f"${total_sol_linked_exposure:,.2f}")
print(f"{total_sol_linked_exposure_pct:.2f}% of total TVL")


# -----------------------------
# Output
# -----------------------------

print(f"\nJupiter Lend — {TARGET_DATE}")
print(f"Total TVL: ${total_tvl:,.2f}")

print("\nTVL by asset:")
print(
    tvl_df.to_string(
        index=False,
        formatters={
            "tvl_usd": "${:,.2f}".format,
            "pct_of_tvl": "{:.2f}%".format
        }
    )
)

print(f"\nTotal borrowed / active loans: ${total_borrowed:,.2f}")

if borrowed_df is not None:
    print("\nBorrowed by asset:")
    print(
        borrowed_df.to_string(
            index=False,
            formatters={
                "borrowed_usd": "${:,.2f}".format,
                "pct_of_borrowed": "{:.2f}%".format
            }
        )
    )


# Optional: save outputs
data_dir = Path(__file__).resolve().parents[1] / "data"
tvl_df.to_csv(
    data_dir / f"jupiter_lend_tvl_by_asset_{TARGET_DATE}.csv",
    index=False
)

if borrowed_df is not None:
    borrowed_df.to_csv(
        data_dir / f"jupiter_lend_borrowed_by_asset_{TARGET_DATE}.csv",
        index=False
    )
