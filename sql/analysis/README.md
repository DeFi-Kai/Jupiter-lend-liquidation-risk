### October 10 event analysis

The five-minute analysis combines the liquidation export with one-minute SOL prices. Run [`sql/analysis/create_liquidation_analysis_5m.sql`](sql/analysis/create_liquidation_analysis_5m.sql) from the repository root with DuckDB to build the analysis table. The report-facing calculations are in [`sql/analysis/october_10_event_metrics.sql`](sql/analysis/october_10_event_metrics.sql), and [`notebooks/october_10_event_analysis.ipynb`](notebooks/october_10_event_analysis.ipynb) reproduces [Figure 1](docs/images/figure-1-debt-repaid-vs-sol-price.png).

The SOL prices come from Binance's public market-data endpoint; the October 10 Jupiter Lend TVL snapshot comes from DeFiLlama. The retrieval scripts are in [`scripts/`](scripts/).
