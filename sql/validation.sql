-- Validation query for the Jupiter Lend liquidation decoder.
-- Replace {{start_date}} and {{end_date}} with the desired half-open date range.
-- Returns one row per Jupiter Lend liquidation instruction.

WITH liq_keys AS (
    SELECT
        block_time,
        outer_instruction_index,
        tx_id,
        CAST(
            from_big_endian_64(
                reverse(substr("data", 9, 8))
            ) AS DECIMAL(38, 0)
        ) AS outer_debt_amt_raw
    FROM solana.instruction_calls
    WHERE executing_account = 'jupr81YtYssSyPt8jbnGuiWon5f6x9TcDEFxYe3Bdzi'
      AND substr("data", 1, 8) = from_hex('dfb3e27d302e274a')
      AND inner_instruction_index IS NULL
      AND tx_success = TRUE
      AND block_time >= '{{start_date}}'
      AND block_time <  '{{end_date}}'
),

inners_raw AS (
    SELECT
        a.tx_id,
        a.outer_instruction_index,
        a.inner_instruction_index,
        a."data" AS inner_data
    FROM solana.instruction_calls a
    JOIN liq_keys b
      ON a.tx_id = b.tx_id
     AND a.outer_instruction_index = b.outer_instruction_index
    WHERE a.inner_instruction_index IS NOT NULL
),

operate_ranked AS (
    SELECT
        tx_id,
        outer_instruction_index,
        inner_instruction_index,
        inner_data,
        ROW_NUMBER() OVER (
            PARTITION BY tx_id, outer_instruction_index
            ORDER BY inner_instruction_index ASC
        ) AS rn
    FROM inners_raw
    WHERE substr(inner_data, 1, 8) = from_hex('d96ad06374972a87')
),

operate_decoded AS (
    SELECT
        tx_id,
        outer_instruction_index,
        rn,
        CASE
            WHEN rn = 1 THEN
                CASE
                    WHEN CAST(from_big_endian_64(reverse(substr(inner_data, 9, 8))) AS DECIMAL(38, 0)) <> 0
                        THEN CAST(from_big_endian_64(reverse(substr(inner_data, 9, 8))) AS DECIMAL(38, 0))
                    ELSE CAST(from_big_endian_64(reverse(substr(inner_data, 25, 8))) AS DECIMAL(38, 0))
                END
        END AS debt_leg_raw,
        CASE
            WHEN rn = 2 THEN
                CASE
                    WHEN CAST(from_big_endian_64(reverse(substr(inner_data, 9, 8))) AS DECIMAL(38, 0)) <> 0
                        THEN CAST(from_big_endian_64(reverse(substr(inner_data, 9, 8))) AS DECIMAL(38, 0))
                    ELSE CAST(from_big_endian_64(reverse(substr(inner_data, 25, 8))) AS DECIMAL(38, 0))
                END
        END AS collateral_leg_raw
    FROM operate_ranked
),

operate_shape AS (
    SELECT
        tx_id,
        outer_instruction_index,
        COUNT(*) AS operate_count,
        MAX(debt_leg_raw) AS debt_leg_raw,
        MAX(collateral_leg_raw) AS collateral_leg_raw
    FROM operate_decoded
    GROUP BY 1, 2
)

SELECT
    lk.block_time,
    lk.tx_id,
    lk.outer_instruction_index,
    lk.outer_debt_amt_raw,
    COALESCE(os.operate_count, 0) AS operate_count,
    os.debt_leg_raw,
    os.collateral_leg_raw,
    CASE
        WHEN COALESCE(os.operate_count, 0) = 2
         AND os.debt_leg_raw IS NOT NULL
         AND os.collateral_leg_raw IS NOT NULL
            THEN TRUE
        ELSE FALSE
    END AS expected_two_leg_shape,
    CASE
        WHEN COALESCE(os.operate_count, 0) <> 2 THEN 'unexpected_operate_count'
        WHEN os.debt_leg_raw IS NULL THEN 'missing_debt_leg'
        WHEN os.collateral_leg_raw IS NULL THEN 'missing_collateral_leg'
        ELSE 'pass'
    END AS shape_check,
    CASE
        WHEN os.debt_leg_raw IS NULL THEN NULL
        ELSE lk.outer_debt_amt_raw - ABS(os.debt_leg_raw)
    END AS outer_vs_inner_debt_delta_raw
FROM liq_keys lk
LEFT JOIN operate_shape os
  ON lk.tx_id = os.tx_id
 AND lk.outer_instruction_index = os.outer_instruction_index
ORDER BY lk.block_time, lk.tx_id, lk.outer_instruction_index;
