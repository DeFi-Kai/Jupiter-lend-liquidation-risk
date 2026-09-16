# Jupiter Lend Liquidations on Solana

Jupiter Lend is a Solana lending market built on Fluid's lending architecture.

For this project, I decoded raw Solana instructions in Dune using SQL to produce a transaction-level dataset of Jupiter Lend's liquidations. I built this project to understand what happened during the October 10, 2025 liquidation event, including which positions were liquidated, what collateral was seized, how much debt was repaid, who executed the liquidations, and how flashloans were used.


## Dashboard

The analysis is available in the [Jupiter Lend Liquidations and Flash Loans dashboard on Dune](https://dune.com/defi_kai/jupiter-lend-liquidations-and-flash-loans-10102025).

![Jupiter Lend liquidation dashboard](docs/jupiter-lend-liquidation-dashboard.png)

## Major Findings

The October 10 liquidation cascade produced:

- 484 liquidation records
- 456 associated flashloan records
- ~$1.29M in estimated debt repaid and ~$1.33M in estimated collateral seized through Jupiter Lend
- Nine wallets taking part in liquidations
- The largest liquidated collateral assets SOL ( ~$567k), cbBTC ( ~$372k), and JUPSOL ( ~$264k)

### Snapshot totals

| Measure | Estimated USD value |
| --- | ---: |
| Collateral seized | $1,334,561.85 |
| Debt repaid | $1,290,393.57 |

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
