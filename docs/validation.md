# Validation

The liquidation dataset was validated by comparing decoded instruction data against independently observable transaction and protocol outputs.

## Liquidation Transactions and Account Mapping

Transactions selected using the discriminator `dfb3e27d302e274a` were manually inspected on Solana explorers to confirm that they correspond to Jupiter Lend `liquidate` instructions.

Sample liquidation transactions were manually inspected to confirm the account mappings used by the decoder:

- `account_arguments[7]` -> collateral/supply mint
- `account_arguments[8]` -> debt/borrow mint
- `account_arguments[14]` -> position
- `tx_signer` -> liquidator

## Inner Operations and Amounts

Relevant Jupiter Lend Liquidity `operate` instructions were manually inspected within sample liquidation transactions. The observed ordering confirmed:

- the first relevant `operate` instruction corresponds to debt repayment
- the second relevant `operate` instruction corresponds to collateral withdrawal

Decoded values were also compared against observed token movements in the corresponding transactions.

The amount fields require little-endian decoding and are represented as signed negative liquidity movements.

Jupiter Lend emits liquidation events in `liquidate` outer-instruction event fields, containing values that can be used as independent checks against instruction decoding.

Observed `LogLiquidate` event fields include:

- `signer`
- `colAmount`
- `debtAmount`

These values can be compared against:

- the outer instruction's decoded `debt_amt`
- decoded inner `operate` debt movements
- decoded inner `operate` collateral movements

This provides an additional validation path independent of the SQL transformation.

## Token Decimals and Pricing

Token amounts were normalized using mint decimals. Sample outputs were checked against known token metadata to confirm that raw integer amounts were converted into the expected token units.

USD values use Dune's hourly Solana price data. Because prices can move materially within an hour, particularly during liquidation cascades, USD-denominated values are not treated as exact transaction-time valuations.

For this reason, the dataset does not attempt to label the difference between collateral value and debt repaid as realized liquidator profit.

## Flashloans

Sample transactions classified as Kamino and Jupiter flashloans were manually inspected to verify:

- instruction discriminator
- executing program
- flashloan mint account index
- decoded flashloan amount

The executing program is retained in the output alongside the human-readable lender classification to make the classification independently traceable.

## Known Failures and Exclusions

Smart vaults are currently excluded until their data can be reconstructed and independently validated.
