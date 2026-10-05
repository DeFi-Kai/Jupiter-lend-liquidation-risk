-- Report-facing October 10, 2025 liquidation metrics.
-- Run from the repository root with DuckDB.

-- Headline totals and average/median liquidation size.
SELECT
    count(*) AS liquidation_count,
    sum(CAST(debt_repaid_usd AS DOUBLE)) AS debt_repaid_usd,
    sum(CAST(collateral_seized_usd AS DOUBLE)) AS collateral_seized_usd,
    avg(CAST(debt_repaid_usd AS DOUBLE)) AS average_debt_repaid_usd,
    median(CAST(debt_repaid_usd AS DOUBLE)) AS median_debt_repaid_usd
FROM read_csv_auto('data/liquidations_2025-10-10.csv', header = true);

-- Collateral seized by asset.
SELECT
    collateral_symbol,
    count(*) AS liquidation_count,
    sum(CAST(collateral_seized_usd AS DOUBLE)) AS collateral_seized_usd
FROM read_csv_auto('data/liquidations_2025-10-10.csv', header = true)
GROUP BY collateral_symbol
ORDER BY collateral_seized_usd DESC;

-- Debt repaid during report windows (UTC); end times are exclusive.
WITH windows AS (
    SELECT * FROM (VALUES
        ('15:15–20:55', TIMESTAMP '2025-10-10 15:15:00', TIMESTAMP '2025-10-10 20:55:00'),
        ('20:55–21:10', TIMESTAMP '2025-10-10 20:55:00', TIMESTAMP '2025-10-10 21:10:00'),
        ('21:10–21:30', TIMESTAMP '2025-10-10 21:10:00', TIMESTAMP '2025-10-10 21:30:00'),
        ('21:30–22:35', TIMESTAMP '2025-10-10 21:30:00', TIMESTAMP '2025-10-10 22:35:00'),
        ('22:35–00:00', TIMESTAMP '2025-10-10 22:35:00', TIMESTAMP '2025-10-11 00:00:00')
    ) AS t(period_label, start_time, end_time)
),
liquidations AS (
    SELECT
        block_time AS block_time_utc,
        CAST(debt_repaid_usd AS DOUBLE) AS debt_repaid_usd
    FROM read_csv_auto('data/liquidations_2025-10-10.csv', header = true)
),
total AS (
    SELECT sum(debt_repaid_usd) AS total_debt_repaid_usd FROM liquidations
)
SELECT
    w.period_label,
    coalesce(sum(l.debt_repaid_usd), 0) AS debt_repaid_usd,
    100 * coalesce(sum(l.debt_repaid_usd), 0) / total.total_debt_repaid_usd
        AS pct_of_total_debt_repaid
FROM windows AS w
CROSS JOIN total
LEFT JOIN liquidations AS l
    ON l.block_time_utc >= w.start_time
    AND l.block_time_utc < w.end_time
GROUP BY w.period_label, w.start_time, total.total_debt_repaid_usd
ORDER BY w.start_time;
