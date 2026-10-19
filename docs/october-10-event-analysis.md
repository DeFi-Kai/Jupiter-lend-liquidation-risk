# October 10 Event Analysis

The [visualization notebook](../notebooks/visualization.ipynb) plots Jupiter Lend debt repaid against SOL prices in five-minute intervals on October 10, 2025. Its saved output can be viewed directly on GitHub.

## Reproduce the visualization

Run the following commands from the repository root using Python 3.

### Install dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install duckdb pandas matplotlib jupyterlab
```

### Build the analysis table

The notebook expects a local `jupiter_lend.duckdb` database containing the `liquidation_analysis_5m` table. Build it from the repository's liquidation and SOL-price CSVs using the [analysis SQL](../sql/analysis/create_liquidation_analysis_5m.sql):

```bash
python -c "from pathlib import Path; import duckdb; con = duckdb.connect('notebooks/jupiter_lend.duckdb'); con.execute(Path('sql/analysis/create_liquidation_analysis_5m.sql').read_text()); con.close()"
```

This creates the database beside the notebook. Run this command from the repository root so the SQL can find the CSVs in `data/`.

### Run the notebook

```bash
jupyter lab notebooks/visualization.ipynb
```

Select the Python kernel from the environment above and run all cells. The notebook's working directory should be `notebooks/`, where the database was created.
