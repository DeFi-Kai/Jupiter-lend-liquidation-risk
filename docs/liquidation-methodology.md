# Liquidation Methodology

Jupiter Lend uses Anchor, a framework for creating Solana programs (smart contracts) using the Rust programming language. Each program contains a set of instructions that define actions like `supply`, when assets are supplied to a market, or `liquidate`, when a position is liquidated. The first 8 bytes of the instruction data contain a discriminator, which identifies the instruction type. The bytes that follow contain the instruction's serialized arguments.

For example, the Jupiter Lend `liquidate` instruction begins with the discriminator:

`dfb3e27d302e274a`

A transaction can contain multiple top-level, or outer, instructions. During execution, an outer instruction can also invoke other programs through cross-program invocations (CPIs). These calls are recorded as inner instructions associated with the outer instruction that invoked them.

In Dune's Solana instruction data, `outer_instruction_index` identifies the position of a top-level instruction within a transaction, while `inner_instruction_index` identifies instructions executed within that outer instruction.

This analysis treats each Jupiter Lend `liquidate` instruction as a liquidation event. Each row in the resulting dataset is uniquely identified by:

`tx_id + outer_instruction_index`

The associated inner instructions are then used to reconstruct the debt repaid and collateral seized during that liquidation.

## Protocol and Instruction Identification

Results are initially filtered using the Jupiter Lend borrow program, `jupr81YtYssSyPt8jbnGuiWon5f6x9TcDEFxYe3Bdzi`, and the `liquidate` instruction identified using the 8-byte Anchor discriminator: `dfb3e27d302e274a`.

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

Liquidations invoke the Jupiter Lend Liquidity program through `operate` inner-instructions within the outer `liquidate` instruction.

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
