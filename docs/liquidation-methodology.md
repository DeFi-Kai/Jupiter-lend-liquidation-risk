# Liquidation Methodology

Solana programs (smart contracts) are written in Anchor, a framework for the Rust programming language. Each program has a set of instructions that define actions. When a transaction occurs, instructions are recorded as data payloads. Each instruction prepends an 8-byte discriminator  


Each row represents one decoded Jupiter Lend liquidation instruction, uniquely identified by `tx_id + outer_instruction_index`.


## Protocol and Instruction Identification

Jupiter Lend borrow program: `jupr81YtYssSyPt8jbnGuiWon5f6x9TcDEFxYe3Bdzi`

The `liquidate` instruction is identified using the 8-byte Anchor discriminator: `dfb3e27d302e274a`

The outer instruction contains the accounts required to identify the position and assets involved in the liquidation:

- `account_arguments[7]` -> collateral/supply mint
- `account_arguments[8]` -> debt/borrow mint
- `account_arguments[14]` -> position
- `tx_signer` -> liquidator

The outer `liquidate` instruction also contains liquidation parameters within its instruction data. After the 8-byte discriminator, the payload includes:

- `debt_amt` -> `u64`, little-endian
- `col_per_unit_debt` -> `u128`, little-endian
- `absorb` -> boolean
- `transfer_type`
- `remaining_accounts_indices`

The `debt_amt` field represents the raw debt amount used by the liquidation instruction.

For example, the payload:

`dfb3e27d302e274af86a890100000000f45c2a4c07df230000000000000000000101010400000001010001`

contains:

- `debt_amt = 25,783,032`
- `col_per_unit_debt = 10,096,846,620,482,804`
- `absorb = true`

The final amount of collateral withdrawn is not directly represented by `col_per_unit_debt`. The realized collateral movement is reconstructed from the inner liquidity instructions.

## Inner Liquidity Instructions

Liquidations invoke the Jupiter Lend Liquidity program through `operate` instructions within the outer `liquidate` instruction.

The `operate` discriminator is:

`d96ad06374972a87`

The first `operate` inner instruction contains the debt/borrow amount at bytes 25-32, and the preceding `operate` inner instruction contains the collateral/supply amount at bytes 9-16. The liquidity movements are recorded as signed negative integers, so absolute values are used when converting them into positive debt-repaid and collateral-seized amounts.

## Amount Normalization and Pricing

Raw token amounts are converted into token units using the token's decimals:

`token_amount = abs(raw_amount) / 10^decimals`

This produces:

- `debt_repaid_token`
- `collateral_seized_token`

Token amounts are joined against Dune's `prices.hour` table using the token mint and the hour in which the liquidation occurred.

USD values are calculated as:

`token_amount x hourly_token_price`

This produces estimated:

- `debt_repaid_usd`
- `collateral_seized_usd`

Because historical Solana prices in this analysis have hourly resolution, USD values should be treated as estimates rather than exact transaction-time valuations.

## Flashloan Identification

Liquidation transactions are also inspected for outer flashloan instructions.

Observed discriminators:

- `87e734a70734d4c1` -> Kamino flashloan instruction
- `67134e18f009873f` -> Jupiter flashloan instruction

For identified flashloans, the query extracts:

- executing program
- lender
- flashloan mint
- raw flashloan amount

The raw amount is decimal-adjusted and joined against hourly price data using the same normalization methodology described above.

## Scope Exclusion

Smart vaults are currently excluded until their data can be reconstructed and independently validated.
