# dbt Quickstart (breathe_flow_dbt)

Steps to run locally or in CI:

1. Create a `profiles.yml` for dbt (example in `dbt/profiles.yml.example`).

2. Place your service account JSON where dbt can read it (example uses `/root/.gcp/service-account.json`).

3. Install dbt (or use the provided Docker runner):

   - Using Docker runner (recommended for reproducibility):

     ```bash
     # set env vars if needed
     export DBT_PROJECT_DIR=$(pwd)/dbt
     export PROFILES_DIR=$(pwd)/dbt
     ./scripts/run_dbt.sh deps
     ./scripts/run_dbt.sh run
     ```

   - Or install dbt-core and adapter for BigQuery and run `dbt run` in `dbt/`.

4. The Kestra flow `kestra/flows/openaq_to_bigquery.yml` invokes `/opt/app/run_dbt.sh run` after ingestion verification. Ensure the Kestra container has the dbt project mounted at `/opt/app/dbt` and credentials accessible.

Notes:
- Update `dbt_project.yml` and `dbt/models` to implement your transformations.
- The included `models/openaq` is a minimal scaffold to get started.
