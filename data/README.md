## Files

- `liquidations_2025-10-10.csv`: Transaction-level liquidation records.
- `flashloans_2025-10-10.csv`: Flashloan records associated with liquidation transactions.
- `sol_price_2025-10-10.csv`: One-minute SOLUSDT market data from Binance.
- `liquidation_analysis_5m.csv`: Five-minute SOL price and liquidation activity series.
- `jupiter_lend_tvl_by_asset_2025-10-10.csv`: October 10 TVL snapshot by asset from DeFiLlama.

## Liquidation Columns

- `block_time`: Block timestamp for the liquidation instruction.
- `tx_id`: Solana transaction ID.
- `outer_instruction_index`: Index of the outer liquidation instruction.
- `debt_mint`, `debt_symbol`: Debt token mint and symbol.
- `collateral_mint`, `collateral_symbol`: Collateral token mint and symbol.
- `liquidator`: Transaction signer that executed the liquidation.
- `position`: Liquidated position account.
- `collateral_seized_token`, `collateral_seized_usd`: Decimal-adjusted collateral amount and hourly-price USD estimate.
- `debt_repaid_token`, `debt_repaid_usd`: Decimal-adjusted debt amount and hourly-price USD estimate.

## Flashloan Columns

- `block_time`: Block timestamp for the flashloan instruction.
- `tx_id`: Solana transaction ID.
- `flash_loan_outer_instruction_index`: Index of the outer flashloan instruction.
- `flash_loan_program`: Executing flashloan program.
- `lender`: Classified lender, currently `kamino` or `jupiter`.
- `flash_loan_mint`, `flash_loan_symbol`: Flashloan token mint and symbol.
- `flash_loan_token`, `flash_loan_usd`: Decimal-adjusted flashloan amount and hourly-price USD estimate.

## Event Analysis Columns

- `timestamp`: Start of the five-minute UTC interval.
- `sol_open`, `sol_close`: SOLUSDT opening and closing prices for the interval.
- `sol_return_pct`, `sol_drawdown_pct`: Interval return and drawdown from the running high watermark.
- `liquidation_count`, `debt_repaid_usd`: Liquidation count and estimated debt repaid in the interval.
