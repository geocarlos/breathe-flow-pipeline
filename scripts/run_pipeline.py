#!/usr/bin/env python3
"""Local pipeline orchestrator: ingest → load → dbt transform.

Runs the full breathe-flow pipeline in three steps:
  1. Ingest  — fetch OpenAQ station snapshots and upload NDJSON to GCS
  2. Load    — load today's GCS files into the BigQuery raw table
  3. Transform — run dbt models (stg_openaq_raw, fct_station_coverage)

Kestra is an alternative orchestrator for the same steps; see:
  kestra/flows/breatheflow_openaq_to_bigquery.yml

Usage:
    python scripts/run_pipeline.py [options]

    --skip-ingest   Skip the ingest step (data already in GCS)
    --skip-load     Skip the GCS → BigQuery load step
    --skip-dbt      Skip the dbt transformation step
    --dbt-cmd CMD   dbt command to run (default: "run"; use "run test" for both)

Environment variables (required unless skipping relevant steps):
    GCP_PROJECT_ID
    GCS_BUCKET_NAME
    BQ_SOURCE_DATASET   BigQuery dataset for raw source table (default: openaq)
    BQ_DATASET          dbt output dataset
    BQ_TABLE            BigQuery raw table name (default: raw)
    GOOGLE_APPLICATION_CREDENTIALS
    OPENAQ_API_KEY      (optional; public endpoints work without a key)

dbt setup:
    Option A — install locally:   pip install dbt-bigquery
    Option B — use Docker runner: set DBT_USE_DOCKER=1
               (requires Docker; uses scripts/run_dbt.sh)
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"
DBT_PROJECT_DIR = REPO_ROOT / "dbt"


def _banner(label: str) -> None:
    print(f"\n{'=' * 60}")
    print(f"[pipeline] {label}")
    print("=" * 60)


def step_ingest() -> None:
    sys.path.insert(0, str(SCRIPTS_DIR))
    from ingest_openaq import run_ingest  # type: ignore[import]

    result = run_ingest()
    print(f"Uploaded {result['records']} records → {result['filename']}")


def step_load() -> None:
    subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "load_to_bq.py")],
        check=True,
    )


def step_dbt(cmds: list[str]) -> None:
    use_docker = os.getenv("DBT_USE_DOCKER", "").lower() in ("1", "true", "yes")

    for cmd in cmds:
        if use_docker:
            runner = SCRIPTS_DIR / "run_dbt.sh"
            env = {
                **os.environ,
                "DBT_PROJECT_DIR": str(DBT_PROJECT_DIR),
                "PROFILES_DIR": str(DBT_PROJECT_DIR),
            }
            subprocess.run(["bash", str(runner), *cmd.split()], env=env, check=True)
        else:
            subprocess.run(
                [
                    "dbt",
                    *cmd.split(),
                    "--project-dir", str(DBT_PROJECT_DIR),
                    "--profiles-dir", str(DBT_PROJECT_DIR),
                ],
                check=True,
            )


def step_dashboard() -> None:
    dashboard_app = REPO_ROOT / "dashboard" / "app.py"
    print(f"[pipeline] Opening dashboard at http://localhost:8501 …")
    subprocess.run(
        ["uv", "run", "streamlit", "run", str(dashboard_app),
         "--server.port=8501", "--server.address=0.0.0.0"],
        check=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run the full breathe-flow pipeline locally."
    )
    parser.add_argument("--skip-ingest", action="store_true", help="Skip ingestion.")
    parser.add_argument("--skip-load", action="store_true", help="Skip GCS→BQ load.")
    parser.add_argument("--skip-dbt", action="store_true", help="Skip dbt transforms.")
    parser.add_argument("--no-dashboard", action="store_true",
                        help="Do not launch the Streamlit dashboard after transforms.")
    parser.add_argument(
        "--dbt-cmd",
        default="run",
        help='dbt command(s) to run, space-separated (default: "run"). '
             'Pass "run test" to run both.',
    )
    args = parser.parse_args()

    total = sum([not args.skip_ingest, not args.skip_load, not args.skip_dbt,
                 not args.no_dashboard])
    step = 0

    if not args.skip_ingest:
        step += 1
        _banner(f"Step {step}/{total} — Ingest: OpenAQ API → GCS")
        step_ingest()
        print("[pipeline] ✓ Ingest complete")

    if not args.skip_load:
        step += 1
        _banner(f"Step {step}/{total} — Load: GCS → BigQuery")
        step_load()
        print("[pipeline] ✓ Load complete")

    if not args.skip_dbt:
        step += 1
        dbt_cmds = args.dbt_cmd.split()
        _banner(f"Step {step}/{total} — Transform: dbt {' + '.join(dbt_cmds)}")
        step_dbt(dbt_cmds)
        print("[pipeline] ✓ dbt complete")

    if not args.no_dashboard:
        step += 1
        _banner(f"Step {step}/{total} — Dashboard: Streamlit")
        step_dashboard()

    print("\n[pipeline] All steps complete ✓")


if __name__ == "__main__":
    main()
