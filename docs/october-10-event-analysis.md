# October 10 Event Analysis

## Reproduce the visualization

The [Jupyter notebook](../notebooks/visualization.ipynb) reproduces Figure 1 by plotting Jupiter Lend debt repayments against SOL prices in five-minute intervals on October 10, 2025.

Follow the steps below to build the analysis table in DuckDB and reproduce the visualization.

### 1. Download the repository

Clone the repository and navigate into its root directory:

```bash
git clone https://github.com/DeFi-Kai/Jupiter-lend-liquidation-risk.git
cd Jupiter-lend-liquidation-risk
```

Alternatively, download the repository as a ZIP from GitHub, extract it, and open a terminal in the extracted directory.

All subsequent DuckDB commands should be run from the repository root unless otherwise specified.

### 2. Install DuckDB

Install the [DuckDB command-line interface](https://duckdb.org/docs/installation/) on Linux or macOS:

```bash
curl -fsSL https://install.duckdb.org | bash
```

Check that DuckDB is installed:

```bash
duckdb --version
```

If your terminal cannot find `duckdb`, add the installation directory to your current session's PATH:

```bash
export PATH="$HOME/.duckdb/cli/latest:$PATH"
```

Windows users can follow the [official installation instructions](https://duckdb.org/docs/installation/).

### 3. Build the analysis table

From the repository root, open DuckDB and create a persistent database in the `notebooks/` directory:

```bash
duckdb notebooks/jupiter_lend.duckdb
```

Inside the DuckDB console, run the existing SQL file:

```sql
.read sql/analysis/create_liquidation_analysis_5m.sql
```

The query reads two CSVs from `data/`:

- `liquidations_2025-10-10.csv` — Liquidation records exported from Dune.
- `sol_price_2025-10-10.csv` — One-minute SOL prices retrieved from Binance.

It combines the datasets into five-minute intervals and creates a table named `liquidation_analysis_5m`.

To verify that the table was created, run:

```sql
SELECT *
FROM liquidation_analysis_5m
LIMIT 5;
```

You should see columns including `timestamp`, `sol_close`, `liquidation_count`, and `debt_repaid_usd`.

Exit DuckDB:

```text
.quit
```

The database is saved as `notebooks/jupiter_lend.duckdb`, where the visualization notebook expects to find it.

### 4. Explore the database in Duck-UI (optional)

We used [Duck-UI](https://duckui.com/?page=connections), a browser-based SQL workbench, to explore the analysis table.

To connect Duck-UI to your local DuckDB database, we'll start a local HTTP server.

**Start the DuckDB HTTP server**

From the repository root, reopen the database:

```bash
duckdb notebooks/jupiter_lend.duckdb
```

In the DuckDB console, install and load the [HTTP Server extension](https://duckdb.org/community_extensions/extensions/httpserver):

```sql
INSTALL httpserver FROM community;
LOAD httpserver;
SELECT httpserve_start('127.0.0.1', 9999, '');
```

This starts an HTTP server on port `9999`, accessible only through your local machine.

Keep the DuckDB console open while using Duck-UI.

**Create a connection in Duck-UI**

Navigate to [Duck-UI's Connections page](https://duckui.com/?page=connections) and create a new connection using these settings:

| Field | Value |
|---|---|
| Connection Name | `Jupiter Lend Local` |
| Connection Type | `DuckDB HTTP Server` |
| Host URL | `http://127.0.0.1:9999` |
| Database (optional) | Leave blank |
| Authentication | `None` |

Save the connection and select it in Duck-UI.

Once connected, open a SQL editor and run:

```sql
SELECT *
FROM liquidation_analysis_5m
LIMIT 10;
```

You can now inspect the analysis table, explore the relationships between SOL prices and liquidation activity, and run additional queries without importing the database.

When finished, return to the DuckDB terminal and stop the HTTP server:

```sql
SELECT httpserve_stop();
```

Then exit DuckDB:

```text
.quit
```

The database remains saved on disk for the notebook.

### 5. Run the Jupyter notebook

The notebook uses Python 3, DuckDB, pandas, and Matplotlib.

From the repository root, create a Python virtual environment and install the dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install duckdb pandas matplotlib jupyterlab ipykernel
```

Navigate to the notebooks directory and launch JupyterLab:

```bash
cd notebooks
jupyter lab visualization.ipynb
```

In JupyterLab, select the Python kernel from your virtual environment and choose **Run All Cells**.

The notebook connects to `jupiter_lend.duckdb`, queries the `liquidation_analysis_5m` table, and generates the visualization comparing SOL prices with liquidation debt repayments.
