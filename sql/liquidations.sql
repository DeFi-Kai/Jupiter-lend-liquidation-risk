-- Jupiter Lend liquidations (base table)
-- Dune query: https://dune.com/queries/8711844/12736083?sidebar=none
-- Replace {{start_date}} and {{end_date}} with the desired half-open date range.

WITH liq_keys AS (
    SELECT
        block_time,
        outer_instruction_index,
        tx_id
    FROM solana.instruction_calls
    WHERE executing_account = 'jupr81YtYssSyPt8jbnGuiWon5f6x9TcDEFxYe3Bdzi'
      AND substr("data", 1, 8) = from_hex('dfb3e27d302e274a')
      AND inner_instruction_index IS NULL
      AND tx_success = TRUE
      AND block_time >= '{{start_date}}'
      AND block_time <  '{{end_date}}'
),

-- Using the transaction IDs, select all inner instructions.
inners_raw AS (
    SELECT
        a.block_time,
        a.tx_id,
        a.account_arguments,
        a.outer_instruction_index,
        a.inner_instruction_index,
        a."data" AS inner_data
    FROM solana.instruction_calls a
    JOIN liq_keys b
      ON a.tx_id = b.tx_id
     AND a.outer_instruction_index = b.outer_instruction_index
    WHERE a.inner_instruction_index IS NOT NULL
      AND a.block_time >= '{{start_date}}'
      AND a.block_time <  '{{end_date}}'
),

-- Only select Jupiter Lend Liquidity operate instructions.
-- Operate discriminator: d96ad06374972a87.
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

op_decoded AS (
    SELECT
        tx_id,
        outer_instruction_index,
        rn,
        -- arg1_i128: first i128 argument (bytes 9..16, little-endian).
        CAST(
          from_big_endian_64(
            reverse(substr(inner_data, 9, 8))
          ) AS DECIMAL(38, 0)
        ) AS arg1_i128,
        -- arg2_i128: second i128 argument (bytes 25..32, little-endian).
        CAST(
          from_big_endian_64(
            reverse(substr(inner_data, 25, 8))
          ) AS DECIMAL(38, 0)
        ) AS arg2_i128
    FROM operate_ranked
),

op_ui_per_rn AS (
    SELECT
        tx_id,
        outer_instruction_index,
        rn,
        -- Raw i128 for borrowed (liquidated) amount; only rn = 1 has a value.
        CASE
            WHEN rn = 1 THEN
                CASE WHEN arg1_i128 <> 0 THEN arg1_i128 ELSE arg2_i128 END
        END AS borrow_raw_i128,
        -- Raw i128 for collateral out; only rn = 2 has a value.
        CASE
            WHEN rn = 2 THEN
                CASE WHEN arg1_i128 <> 0 THEN arg1_i128 ELSE arg2_i128 END
        END AS supply_raw_i128
    FROM op_decoded
),

op_ui AS (
    SELECT
        tx_id,
        outer_instruction_index,
        MAX(borrow_raw_i128) AS borrow_raw_i128,
        MAX(supply_raw_i128) AS supply_raw_i128
    FROM op_ui_per_rn
    GROUP BY 1, 2
),

liq_meta AS (
    SELECT
        sc.block_time,
        sc.tx_id,
        sc.outer_instruction_index,
        sc.tx_signer            AS liquidator,
        sc.account_arguments,
        sc.account_arguments[7]  AS supply_mint,
        sc.account_arguments[8]  AS borrow_mint,
        sc.account_arguments[14] AS position,
        sc.executing_account,
        to_hex(substr(sc."data", 1, 8)) AS discr_hex
    FROM solana.instruction_calls sc
    JOIN liq_keys lk
      ON sc.tx_id = lk.tx_id
     AND sc.outer_instruction_index = lk.outer_instruction_index
    WHERE sc.inner_instruction_index IS NULL
      AND substr(sc."data", 1, 8) = from_hex('dfb3e27d302e274a')
      AND sc.block_time >= '{{start_date}}'
      AND sc.block_time <  '{{end_date}}'
)

SELECT
    lm.block_time AS block_time,
    lm.tx_id,
    lm.outer_instruction_index,
    lm.borrow_mint AS debt_mint,
    pb.symbol AS debt_symbol,
    lm.supply_mint AS collateral_mint,
    ps.symbol AS collateral_symbol,
    lm.liquidator,
    lm.position,

    -- Collateral seized.
    ABS(CAST(ou.supply_raw_i128 AS DOUBLE))
        / POWER(10, ps.decimals) AS collateral_seized_token,

    ABS(CAST(ou.supply_raw_i128 AS DOUBLE))
        / POWER(10, ps.decimals)
        * ps.price AS collateral_seized_usd,

    -- Debt repaid.
    ABS(CAST(ou.borrow_raw_i128 AS DOUBLE))
        / POWER(10, pb.decimals) AS debt_repaid_token,

    ABS(CAST(ou.borrow_raw_i128 AS DOUBLE))
        / POWER(10, pb.decimals)
        * pb.price AS debt_repaid_usd
FROM liq_meta lm
LEFT JOIN op_ui ou
    ON lm.tx_id = ou.tx_id
   AND lm.outer_instruction_index = ou.outer_instruction_index

-- Price and decimals for the borrow leg (usually USDC/USDT).
LEFT JOIN prices.hour pb
  ON pb.contract_address = from_base58(lm.borrow_mint)
 AND pb.timestamp         = DATE_TRUNC('hour', lm.block_time)
 AND pb.blockchain        = 'solana'

-- Price and decimals for the collateral leg (SOL, jitoSOL, etc.).
LEFT JOIN prices.hour ps
  ON ps.contract_address = from_base58(lm.supply_mint)
 AND ps.timestamp         = DATE_TRUNC('hour', lm.block_time)
 AND ps.blockchain        = 'solana'
;
