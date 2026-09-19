# Jupiter Lend Liquidations Dataset

Jupiter Lend is a credit-market on the Solana blockchain, built on Fluid's lending architecture. Blockchain-based lending venues are increasingly being used by Fintech apps like Robinhood and Coinbase to offer users products to leverage their holdings, and for other users to provide loans to those users. 

Users can submit collateral, and take out loans up to a specific loan-to-value (LTV) ratio. If a positions collateral value falls below the loan the position is submitted for liquidation. The platform performs programmatic liquidations to avoid defaulted loans and bad-debt incurred to the system. 

I built this project to understand what happened during the October 10, 2025 liquidation event, including which positions were liquidated, what collateral was seized, how much debt was repaid, who executed the liquidations, and how flashloans were used.

Solana apps are built using Anchor, a framework for the Rust programming language. Blockchain data is recorded as unstructured events and data payloads so for this project, I decoded raw Solana instructions in Dune using SQL to produce a transaction-level dataset of Jupiter Lend's liquidations.

## Dashboard

The analysis is available in the [Jupiter Lend Liquidations and Flash Loans dashboard on Dune](https://dune.com/defi_kai/jupiter-lend-liquidations-and-flash-loans-10102025).

![Jupiter Lend liquidation dashboard](docs/jupiter-lend-liquidation-dashboard.png)

## Major Findings

The October 10 liquidation cascade produced:

- 484 liquidation records
- 456 associated flashloan records
- ~$1.29M in estimated debt repaid
- ~$1.33M in estimated collateral seized
- Nine wallets taking part in liquidations
- The largest liquidated collateral assets SOL ( ~$567k), cbBTC ( ~$372k), and JUPSOL ( ~$264k)

### Flashloans

| Lender | Records |
| --- | ---: |
| Jupiter | 315 |
| Kamino | 141 |
| Total | 456 |

## How the dataset is built

The SQL query:

1. Identifies Jupiter Lend `liquidate` instructions using the protocol's instruction discriminator.
2. Extracts the position, collateral mint, debt mint, and liquidator from the instruction accounts.
3. Traces inner liquidity instructions to reconstruct debt repaid and collateral withdrawn.
4. Identifies flashloans and classify the lender.
5. Normalizes raw token amounts using token decimals.
6. Joins the events to Dune's hourly price data to estimate USD values.

The detailed decoding logic is documented in [`docs/liquidation-methodology.md`](docs/liquidation-methodology.md), with validation notes in [`docs/validation.md`](docs/validation.md).

The dataset started as raw Solana transaction data. This example shows what one transaction looked like before and after decoding.

#### Before: raw transaction data

This is what one raw outer liquidation entry looked like before decoding:

| Raw field | Value |
| --- | --- |
| `block_time` | `2025-10-10 21:09:26` |
| `tx_id` | `M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u` |
| `outer_instruction_index` | `3` |
| `inner_instruction_index` | `NULL` |
| `executing_account` | `jupr81YtYssSyPt8jbnGuiWon5f6x9TcDEFxYe3Bdzi` |
| `tx_signer` | `ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9` |
| `account_arguments` | `ariZPxRj..., 63adf...` |
| `payload_hex` | `DFB3E27D302E274A00E1F50500000000000000000000000000000000000000000001010400000001060201` |
| `tx_success` | `true` |

The full raw query is available on [Dune](https://dune.com/queries/8768594).

#### After: decoded liquidation record

| Transaction | Debt repaid | Debt token | Collateral seized | Collateral token | Debt value | Collateral value |
| --- | ---: | --- | ---: | --- | ---: | ---: |
| `M1zoo3...` | `99.999999` | `USDC` | `0.512291352` | `SOL` | `$100.76` | `$96.84` |

The outer row identifies the liquidation. The nested `operate` calls in the same instruction group supplied the debt and collateral movements. The decoder extracted the raw integer amounts (`99,999,999` and `512,291,352`), converted them using token decimals, and joined hourly prices to estimate USD values.

## Repo structure

- `data/` contains the October 10, 2025 liquidation and flashloan exports, along with their schemas.
- `sql/` contains the DuneSQL queries used to produce the datasets.
- `docs/` contains the methodology, validation notes, and dashboard image.

## Scope and limitations

USD values are estimates. Dune's [`prices.hour`](https://dune.com/data/prices.hour) table has hourly resolution and cannot capture minute-by-minute price movements during a liquidation event. The analysis therefore does not treat the difference between collateral seized and debt repaid as realized liquidator profit.

More precise price data would allow better estimation of the value captured during individual liquidations.

## Data sources

- [`solana.instruction_calls`](https://dune.com/data/solana.instruction_calls)
- [`prices.hour`](https://dune.com/data/prices.hour)


## Next steps

- Position-level risk modeling
- Distance-to-Liquidation (DTL)
- Stress testing
- Liquidation-at-Risk analysis
