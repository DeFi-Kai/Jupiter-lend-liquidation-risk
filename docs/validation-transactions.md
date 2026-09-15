# Validation Transactions

This is a small transaction-level validation set for the decoder. Each transaction was checked against Solana mainnet transaction metadata and log messages. The labels below describe what the transaction actually contains, rather than relying only on the original notes.

The decoder looks for:

- Jupiter Lend's outer `Liquidate` instruction.
- Jupiter Lend Liquidity `Operate` instructions inside that liquidation instruction.
- Known flashloan instructions when present.

## Transaction review

| Example | Transaction | What appears on mainnet | Result |
| --- | --- | --- | --- |
| Clean reference liquidation | [VDLjZR...](https://solscan.io/tx/VDLjZRzwQpgAQw7eik13DV72rHL9Hm52F6DoMZrsj9nJuYs69XhciKk2mmzG3cjGxatrMtDWopUW6mhZS4jhutj) | Jupiter Lend `Liquidate`, two relevant inner `Operate` instructions, and Kamino flash borrow/repay logs | Valid reference |
| WSOL deposit negative control | [3swJCr...](https://solscan.io/tx/3swJCrumaEULJ2jUaAmZhLUYTJsFBUcUq5mJLncJ2stc8w5TxBMWRF9PYfebqLzvKNPygzm3teFPqyCbTwGdHg9S) | `SyncNative`, `InitPosition`, and `Operate` logs, but no Jupiter Lend `Liquidate` instruction | Correctly rejected |
| JLP flashloan negative control | [49Xf2y...](https://solscan.io/tx/49Xf2yQF9Ta1UaTwQkEAGtifp3aC2iAkNrjJAKwjVDXqjrsG6QAcLqPZuTbbYdw8DqX18XFWSWUgKEmrJGAC4B7v) | `FlashloanBorrow` and `FlashloanPayback` logs, but no Jupiter Lend `Liquidate` instruction | Correctly rejected |
| Liquidation without flashloan | [M1zoo3...](https://solscan.io/tx/M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u) | Jupiter Lend `Liquidate` with two relevant inner `Operate` instructions and no flashloan logs | Valid liquidation |
| Liquidation with other operations in the same transaction | [DrehALK...](https://solscan.io/tx/DrehALKD1sizxr3sCS2z117vZ9eai28kQ97iF8wQB1xegQVvkmm8sThtQ6ZruPeRaSsCVAquNNwjKXYWqFxpnWR) | Jupiter Lend `Liquidate`; two relevant `Operate` instructions inside its instruction group, with additional operations elsewhere in the transaction | Valid scope test |
| Liquidation with other operations in the same transaction | [26rixw3...](https://solscan.io/tx/26rixw3HRkZM8iG1MHmEvpYt7mdugqYmZAp4x7TBt6aXCVvV3egG1Aiy3yXkiWkQuSbo3NkJXiWWtZChy4Up5gs8) | Jupiter Lend `Liquidate`; two relevant `Operate` instructions inside its instruction group, with additional operations elsewhere in the transaction | Valid scope test |
| Two-leg liquidation reference | [2V8SGr...](https://solscan.io/tx/2V8SGrSsanFC4ijyAM1Q6fTc6NaH6y9m8WqoncWYTYoyLZcgtFA7KtZZAHU18WrPBsLxjBrnbEXnEbXammu8wXG7) | Jupiter Lend `Liquidate` with two relevant inner `Operate` instructions and Jupiter flashloan borrow/repay logs | Valid two-leg example |
| Pattern confirmation | [5guPqg...](https://solscan.io/tx/5guPqgEj9FadRp4A2xJrn2rnBhRpRk4etLxjfYG75z16cZiFiQaqsH91q3XJvvqj3mDCWUEqHck2WG2kmCZ3xrau) | Jupiter Lend `Liquidate`, two relevant inner `Operate` instructions, and Kamino flash borrow/repay logs | Valid pattern confirmation |
| Pattern confirmation | [3LrpND...](https://solscan.io/tx/3LrpNDZVxsMAwceue1QRuGAUxa7yajryChcrSUgD7X2g8NVrzQzoZNWbBvTowfP2vJCmnZXJq2bCXN8Vg31sdBNe) | Jupiter Lend `Liquidate`, two relevant inner `Operate` instructions, and Kamino flash borrow/repay logs | Valid pattern confirmation |
| Pattern confirmation | [3169fy...](https://solscan.io/tx/3169fyF7pcfUvm2GYUu33o4VQ6BoRyiiEYXt38j4o7JxU3Uo6BMRnpX1XJN8dvdAVjWK6BAaXcV2ukz8xpuxYbdA) | Jupiter Lend `Liquidate`, two relevant inner `Operate` instructions, and Kamino flash borrow/repay logs | Valid pattern confirmation |

## What this establishes

- The outer Jupiter Lend `Liquidate` instruction is necessary. `Operate` instructions or flashloans alone are not enough to identify a liquidation.
- The inner operations need to be scoped to the liquidation instruction, not counted across the entire transaction.
- The two-leg pattern appears in multiple actual liquidation transactions, including transactions with and without flashloans.
- The two negative controls in the original validation notes are genuinely negative controls.

This set validates the decoder's design against representative transactions. It does not replace a full-run Dune check across every row in the export; that check is provided separately in [`../sql/validation.sql`](../sql/validation.sql).
