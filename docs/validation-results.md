# Validation Results

These checks were run against the checked-in CSV exports. They validate the shape and completeness of the published snapshot; they are separate from the transaction-level checks in [`validation-transactions.md`](validation-transactions.md).

## Export integrity

| Check | Result |
| --- | ---: |
| Liquidation rows | 484 |
| Unique `(tx_id, outer_instruction_index)` keys | 484 |
| Duplicate liquidation keys | 0 |
| Liquidation rows with a missing field | 0 |
| Unique liquidation transactions | 484 |
| Flashloan rows | 456 |
| Unique `(tx_id, flash_loan_outer_instruction_index)` keys | 456 |
| Duplicate flashloan keys | 0 |
| Liquidation transactions with a flashloan record | 456 |
| Unique liquidator wallets | 9 |

## Flashloan classification

| Lender | Records |
| --- | ---: |
| Jupiter | 315 |
| Kamino | 141 |
| Total | 456 |

The statement that Kamino supplied fewer than half of flashloan-assisted liquidations is count-based: 141 of 456 records, or approximately 31%.

## Snapshot totals

| Measure | Estimated USD value |
| --- | ---: |
| Collateral seized | $1,334,561.85 |
| Debt repaid | $1,290,393.57 |

The `$1.29M` figure refers to estimated debt repaid. The estimated value of collateral seized is approximately `$1.335M`. Neither figure should be interpreted as realized liquidator profit because both use hourly price data and exclude transaction-level profit accounting.

## Largest collateral assets

| Asset | Estimated collateral seized |
| --- | ---: |
| SOL | $567,895.76 |
| cbBTC | $372,265.67 |
| JUPSOL | $264,255.32 |

## Remaining validation work

The checked-in CSVs cannot independently prove how every raw instruction was decoded. The Dune validation query should be run to inspect the number of relevant `Operate` instructions per liquidation and the relationship between the outer debt parameter and the inner debt leg. The hourly price limitation remains an analytical limitation, not a decoder failure.
