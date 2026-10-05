import requests
import pandas as pd
from datetime import datetime, timezone
from pathlib import Path

# Binance public market-data endpoint
url = "https://data-api.binance.vision/api/v3/klines"

symbol = "SOLUSDT"
interval = "1m"

# Full UTC day: 2025-10-10
start = datetime(2025, 10, 10, 0, 0, 0, tzinfo=timezone.utc)
end = datetime(2025, 10, 11, 0, 0, 0, tzinfo=timezone.utc)

start_ms = int(start.timestamp() * 1000)
end_ms = int(end.timestamp() * 1000)

all_rows = []
current_start = start_ms

while current_start < end_ms:
    params = {
        "symbol": symbol,
        "interval": interval,
        "startTime": current_start,
        "endTime": end_ms - 1,
        "limit": 1000
    }

    response = requests.get(url, params=params)
    response.raise_for_status()

    rows = response.json()

    if not rows:
        break

    all_rows.extend(rows)

    # Start next request one millisecond after the last candle's close
    current_start = rows[-1][6] + 1


columns = [
    "open_time",
    "open",
    "high",
    "low",
    "close",
    "volume",
    "close_time",
    "quote_volume",
    "num_trades",
    "taker_buy_base_volume",
    "taker_buy_quote_volume",
    "ignore"
]

df = pd.DataFrame(all_rows, columns=columns)

# Convert timestamps
df["open_time"] = pd.to_datetime(df["open_time"], unit="ms", utc=True)
df["close_time"] = pd.to_datetime(df["close_time"], unit="ms", utc=True)

# Convert price/volume columns to numbers
numeric_cols = [
    "open",
    "high",
    "low",
    "close",
    "volume",
    "quote_volume",
    "taker_buy_base_volume",
    "taker_buy_quote_volume"
]

df[numeric_cols] = df[numeric_cols].apply(pd.to_numeric)

# Keep only fields useful for your analysis
sol_price = df[
    [
        "open_time",
        "open",
        "high",
        "low",
        "close",
        "volume"
    ]
]

# Save
output_path = Path(__file__).resolve().parents[1] / "data" / "sol_price_2025-10-10.csv"
sol_price.to_csv(output_path, index=False)

print(sol_price.head())
print(sol_price.tail())
print(f"\nRows: {len(sol_price)}")
