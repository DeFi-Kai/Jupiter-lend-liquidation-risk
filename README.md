# Jupiter Lend Liquidation Data: SQL Decoder, Dataset & Analysis

SQL query and methodology for decoding Jupiter Lend Liquidations and flashloans. The queries reconstruct liquidation activity from raw Solana instructions in DuneSQL to identify liquidated positions, collateral seized, debt repaid, liquidators, and associated flashloans. The project includes a transaction-level dataset of Jupiter Lend liquidations and flashloans during the October 10, 2025 market selloff. 

## Dashboard

The analysis of the October 10, 2025 market selloff is available in the [Jupiter Lend Liquidations and Flash Loans dashboard on Dune](https://dune.com/defi_kai/jupiter-lend-liquidations-and-flash-loans-10102025).

![Jupiter Lend liquidation dashboard](docs/jupiter-lend-liquidation-dashboard.png)

## Background 

Jupiter Lend is a credit market on the Solana blockchain. Blockchain credit markets allow users to supply assets as collateral, borrow against those assets, or provide liquidity that other users can borrow. Similar lending infrastructure is increasingly being integrated into fintech and digital-asset products.

Borrowers deposit cryptocurrencies or tokenized assets as collateral and can borrow up to a specified loan-to-value (LTV) ratio. Each market also has a liquidation threshold that determines when a borrowing position becomes undercollateralized enough to be eligible for liquidation.

When a position crosses its liquidation threshold, Jupiter Lend can programmatically liquidate part of the position to reduce the risk of default and bad debt to the protocol.

Liquidations are carried out by a permissionless network of liquidators that monitor borrowing positions. During a liquidation, a liquidator repays a portion of the borrower’s debt and receives collateral in return, including a liquidation penalty.

Liquidators can also use flashloans from Jupiter Lend to temporarily borrow the liquidity needed to execute a liquidation without supplying the capital upfront.

## Major Findings

The October 10 liquidation cascade produced:

- 484 liquidation records
- 456 associated flashloan records from Jupiter (315) and Kamino (141)
- ~$1.29M in estimated debt repaid
- ~$1.33M in estimated collateral seized
- Nine wallets taking part in liquidations
- The largest liquidated collateral assets SOL ( ~$567k), cbBTC ( ~$372k), and JUPSOL ( ~$264k)

## How the Dataset Is Built

Jupiter Lend liquidations are not recorded onchain as ready-to-query rows containing fields such as `debt_repaid`, `collateral_seized`, or token symbols. A single liquidation transaction produces a trace of outer and inner instructions across several Solana programs.

Building the dataset required identifying the liquidation instruction, locating the related inner instructions, decoding their binary payloads, and combining the results into one analytical record.

**14 raw instruction rows → 1 decoded liquidation record**

### Before: Raw Transaction Instructions

The example below shows the complete instruction trace for a single liquidation transaction. Most of these instructions are not themselves liquidation data.

<details>
<summary>View all 14 raw instruction rows</summary>

| block_time          | tx_id                                                                                   | outer_instruction_index | inner_instruction_index | executing_account                               | tx_signer                                   | account_arguments                                     | payload_hex                                                                                                | tx_success |
| ------------------- | --------------------------------------------------------------------------------------- | ----------------------: | ----------------------: | ----------------------------------------------- | ------------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ---------- |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       1 |                         | ComputeBudget111111111111111111111111111111     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 |                                                       | `038813000000000000`                                                                                       | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       2 |                         | ComputeBudget111111111111111111111111111111     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 |                                                       | `0240420F00`                                                                                               | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       1 | ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL    | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9, FvSH1••• | `0`                                                                                                        | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       2 | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | So11111111111111111111111111111111111111112           | `150700`                                                                                                   | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       3 | 11111111111111111111111111111111                | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9, FvSH1••• | `00000000F01D1F0000000000A50000000000000006DDF6E1D765A193D9CBE146CEEB79AC1CB485ED5F5B37913A8CF5857EFF00A9` | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       4 | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | FvSH1jLik2JQPtdtrYDjH1zTTbzKyQqt8s1bPbgNdBs4          | `16`                                                                                                       | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       5 | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | FvSH1jLik2JQPtdtrYDjH1zTTbzKyQqt8s1bPbgNdBs4, So11••• | `1208AC61A082432CE4422B950FF9AAC80B9D6EF7AB01CDF110D438F1DB287A3C5A`                                       | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       6 | jupnw4B6Eqs7ft6rxpzYLJZYSnrpRgPcr589n5Kv4oc     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | 6QBKbRU6bgjDxLeP8XwZmrikkRR5v913b7xwLPVoeNQ5, 7UVi••• | `E4A949275B521B050500`                                                                                     | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       7 | jupeiUmn818Jg1ekPURTpr4mFo29p46vygyykFJ3wZC     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | nMzVs8GiXMVUENEwkev7JZfDcCENmz18ScheeVRdnb1, 7s1da••• | `81CD9E9BC69B4885C6FA7AF3BEDBAD3A3D65F36AABC97431B1BBE4C2D2F6E0E47CA60203452F5D61`                         | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                       8 | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | 63adfXRJXnKZ8Zk9Pi67xsF5UXZrSzDzKbwon5CostQW, EPjF••• | `0CFFE0F5050000000006`                                                                                     | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                   **9** | **jupeiUmn818Jg1ekPURTpr4mFo29p46vygyykFJ3wZC** | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | nMzVs8GiXMVUENEwkev7JZfDcCENmz18ScheeVRdnb1, 7s1da••• | **`D96AD06374972A87...`**                                                                                  | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                  **10** | **jupeiUmn818Jg1ekPURTpr4mFo29p46vygyykFJ3wZC** | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | nMzVs8GiXMVUENEwkev7JZfDcCENmz18ScheeVRdnb1, 7s1da••• | **`D96AD06374972A87...`**                                                                                  | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                       3 |                      11 | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA     | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | 5JP5zgYCb9W37QQLgAHRHuinFLrKt87akDY1CgZoTPzr, So11••• | `0C18F2881E0000000009`                                                                                     | true       |
| 2025-10-10 21:09:26 | M1zoo3YJzi6D6S74zVaRm9b99Za4MjceAcQgxBufGP8kyjhjtMMN6s4bHN3JWLWjLFqXLutmYNtY9HDvAgbrC7u |                   **3** |                         | **jupr81YtYssSyPt8jbnGuiWon5f6x9TcDEFxYe3Bdzi** | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9, 63adf••• | **`DFB3E27D302E274A...`**                                                                                  | true       |

</details>

The decoder reduces this trace to the instructions needed to reconstruct the liquidation. 

```text
Jupiter Lend outer instruction
DFB3E27D302E274A...
        │
        └── identifies a liquidation transaction
                    │
                    ▼
        Inner Liquidity instructions
        D96AD06374972A87...
             │              │
             │              └── collateral withdrawn
             └── debt repaid
                    │
                    ▼
           one liquidation record
```

Step-by-step, the SQL query:

1. Identifies Jupiter Lend `liquidate` instructions using the protocol's instruction discriminator.
2. Extracts the position, collateral mint, debt mint, and liquidator from the instruction accounts.
3. Traces inner liquidity instructions to reconstruct debt repaid and collateral withdrawn.
4. Identifies flashloans and classify the lender.
5. Normalizes raw token amounts using token decimals.
6. Joins the events to Dune's hourly price data to estimate USD values.

The detailed decoding logic is documented in [`docs/liquidation-methodology.md`](docs/liquidation-methodology.md), with validation notes in [`docs/validation.md`](docs/validation.md).

### After: Decoded Liquidation Record

After decoding the instruction payloads, mapping account positions to token mints, and joining token metadata and prices, the same transaction becomes a single analysis-ready row:

| block_time          | tx_id              | debt_symbol | collateral_symbol | liquidator                                  | position                                     | collateral_seized_usd |    debt_repaid_usd |
| ------------------- | ------------------ | ----------- | ----------------- | ------------------------------------------- | -------------------------------------------- | --------------------: | -----------------: |
| 2025-10-10 21:09:26 | M1zoo3YJ...AgbrC7u | USDC        | SOL               | ariZPxRj8PmzUR5mB3FVopbPUmYmCiTCLdvjW8tTQQ9 | 8W2SoErPPcYvbBvfSBHZECTXsFu8ZSLSYfQkaTatxKVv |        96.83928808748 | 100.75977399240224 |

The resulting dataset converts low-level program execution into fields that can be queried directly for liquidation analysis: **what asset was repaid, what collateral was seized, who executed the liquidation, which position was liquidated, and the value of the event.**


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


## Reproducibility

### Prerequisites
- A Dune account

### Run the query
1. Sign in to Dune.
2. Create a new SQL query.
3. Copy the contents of [`sql/liquidations.sql`](sql/liquidations.sql) into the Dune query editor.
4. Replace the start and end date values with the desired UTC time range.

   Example:

   ```sql
   TIMESTAMP '2025-10-10 00:00:00 UTC'
   ```

5. Run the query.
6. Review or export the resulting liquidation dataset as needed.
