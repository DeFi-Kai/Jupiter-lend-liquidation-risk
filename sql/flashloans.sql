-- Flashloans associated with Jupiter Lend liquidation transactions.
-- Dune query: https://dune.com/queries/8712603?sidebar=none
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

liq_txs AS (
    SELECT DISTINCT
        tx_id
    FROM liq_keys
),

flash_loans AS (
    SELECT
        sc.block_time,
        sc.tx_id,
        sc.outer_instruction_index AS flash_loan_outer_instruction_index,
        sc.executing_account AS flash_loan_program,

        CASE
            WHEN substr(sc."data", 1, 8) = from_hex('87e734a70734d4c1') THEN 'kamino'
            WHEN substr(sc."data", 1, 8) = from_hex('67134e18f009873f') THEN 'jupiter'
        END AS lender,

        CASE
            WHEN substr(sc."data", 1, 8) = from_hex('87e734a70734d4c1') THEN sc.account_arguments[5]
            WHEN substr(sc."data", 1, 8) = from_hex('67134e18f009873f') THEN sc.account_arguments[4]
            ELSE NULL
        END AS flash_loan_mint,

        CAST(
            from_big_endian_64(
                reverse(substr(sc."data", 9, 8))
            ) AS DECIMAL(38, 0)
        ) AS flash_loan_liquidity

    FROM solana.instruction_calls sc
    JOIN liq_txs lk
      ON sc.tx_id = lk.tx_id
    WHERE sc.inner_instruction_index IS NULL
      AND substr(sc."data", 1, 8) IN (
          from_hex('87e734a70734d4c1'),
          from_hex('67134e18f009873f')
      )
      AND sc.block_time >= '{{start_date}}'
      AND sc.block_time <  '{{end_date}}'
)

SELECT
    fl.block_time,
    fl.tx_id,
    fl.flash_loan_outer_instruction_index,
    fl.flash_loan_program,
    fl.lender,
    fl.flash_loan_mint,
    db.symbol AS flash_loan_symbol,

    ABS(CAST(fl.flash_loan_liquidity AS DOUBLE))
        / POWER(10, db.decimals) AS flash_loan_token,

    ABS(CAST(fl.flash_loan_liquidity AS DOUBLE))
        / POWER(10, db.decimals)
        * db.price AS flash_loan_usd

FROM flash_loans fl
LEFT JOIN prices.hour db
    ON db.contract_address = from_base58(fl.flash_loan_mint)
   AND db.timestamp         = DATE_TRUNC('hour', fl.block_time)
   AND db.blockchain        = 'solana'
;
