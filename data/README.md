## Files

- `liquidations_2025-10-10.csv`: Transaction-level liquidation records.
- `flashloans_2025-10-10.csv`: Flashloan records associated with liquidation transactions.

The CSV files contain the October 10, 2025 exports: 484 liquidation records and 456 flashloan records, excluding headers.

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
