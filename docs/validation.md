# Validation

The validation checks below focus on whether the decoder is selecting the right instruction and reconstructing the two settlement legs. The byte layout, account mappings, discriminators, and pricing methodology are documented in [`liquidation-methodology.md`](liquidation-methodology.md).

## Representative transactions

These transactions were checked against Solana mainnet transaction metadata and log messages. Raw leg values are absolute amounts from the relevant inner `Operate` instructions, before decimal normalization.

| Example | Transaction | Inner debt leg | Inner collateral leg | Flashloan | What it proves |
| --- | --- | ---: | ---: | --- | --- |
| Liquidation without flashloan | [M1zoo3...](https://solscan.io/tx/M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u) | 99,999,999 | 512,291,352 | None | A valid liquidation with both settlement legs |
| Liquidation with Kamino flashloan | [VDLjZR...](https://solscan.io/tx/VDLjZRzwQpgAQw7eik13DV72rHL9Hm52F6DoMZrsj9nJuYs69XhciKk2mmzG3cjGxatrMtDWopUW6mhZS4jhutj) | 390,503,501 | 2,600,301,748 | Kamino | A valid flashloan-assisted liquidation with both settlement legs |
| WSOL deposit negative control | [3swJCr...](https://solscan.io/tx/3swJCrumaEULJ2jUaAmZhLUYTJsFBUcUq5mJLncJ2stc8w5TxBMWRF9PYfebqLzvKNPygzm3teFPqyCbTwGdHg9S) | N/A | N/A | None | `Operate` activity without an outer `Liquidate` is rejected |
| JLP flashloan negative control | [49Xf2y...](https://solscan.io/tx/49Xf2yQF9Ta1UaTwQkEAGtifp3aC2iAkNrjJAKwjVDXqjrsG6QAcLqPZuTbbYdw8DqX18XFWSWUgKEmrJGAC4B7v) | N/A | N/A | JLP flashloan | Flashloan activity without an outer `Liquidate` is rejected |
| Liquidation with unrelated operations | [DrehALK...](https://solscan.io/tx/DrehALKD1sizxr3sCS2z117vZ9eai28kQ97iF8wQB1xegQVvkmm8sThtQ6ZruPeRaSsCVAquNNwjKXYWqFxpnWR) | 190,410 | 1,025,432 | Jupiter | Inner operations must be scoped to the liquidation instruction, not the whole transaction |

The outer `liquidate` instruction's `debt_amt` is retained as a debt cross-check. It is not used to infer collateral: the collateral amount comes from the collateral-side inner `Operate` leg.

## Snapshot checks

The checked-in liquidation export contains 484 rows with no duplicate `(tx_id, outer_instruction_index)` keys and no missing fields. The flashloan export contains 456 rows with no duplicate `(tx_id, flash_loan_outer_instruction_index)` keys. The snapshot contains nine unique liquidator wallets.

The checked-in snapshot checks cover row counts, duplicate keys, missing fields, and liquidator coverage. A full-run Dune reconciliation is intentionally outside the current repository scope.

## Limits

The representative transactions validate the decoder's design, but they do not replace running the full Dune check across all 484 liquidation rows. Smart vaults are outside the current dataset until their activity can be reconstructed and independently validated.
