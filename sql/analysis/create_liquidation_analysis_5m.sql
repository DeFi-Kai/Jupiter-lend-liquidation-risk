-- Build the five-minute October 10 analysis table from the published CSVs.
-- Run from the repository root with DuckDB.

CREATE OR REPLACE TABLE liquidation_analysis_5m AS
WITH price_minutes AS (
    SELECT
        open_time,
        date_trunc('minute', open_time AT TIME ZONE 'UTC') AS minute,
        open,
        high,
        close
    FROM read_csv_auto('data/sol_price_2025-10-10.csv', header = true)
),
price_5m AS (
    SELECT
        time_bucket(INTERVAL '5 minutes', minute) AS timestamp,
        arg_min(open, minute) AS sol_open,
        arg_max(close, minute) AS sol_close,
        max(high) AS sol_high
    FROM price_minutes
    GROUP BY 1
),
liquidations_5m AS (
    SELECT
        time_bucket(
            INTERVAL '5 minutes',
            block_time
        ) AS timestamp,
        count(*) AS liquidation_count,
        sum(CAST(debt_repaid_usd AS DOUBLE)) AS debt_repaid_usd
    FROM read_csv_auto('data/liquidations_2025-10-10.csv', header = true)
    GROUP BY 1
),
joined AS (
    SELECT
        p.timestamp,
        p.sol_open,
        p.sol_close,
        p.sol_high,
        coalesce(l.liquidation_count, 0) AS liquidation_count,
        coalesce(l.debt_repaid_usd, 0) AS debt_repaid_usd
    FROM price_5m AS p
    LEFT JOIN liquidations_5m AS l USING (timestamp)
),
with_high_watermark AS (
    SELECT
        *,
        max(sol_high) OVER (
            ORDER BY timestamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS sol_high_watermark
    FROM joined
)
SELECT
    timestamp,
    sol_open,
    sol_close,
    (sol_close / sol_open - 1) * 100 AS sol_return_pct,
    (sol_close / sol_high_watermark - 1) * 100 AS sol_drawdown_pct,
    liquidation_count,
    debt_repaid_usd
FROM with_high_watermark
ORDER BY timestamp;
