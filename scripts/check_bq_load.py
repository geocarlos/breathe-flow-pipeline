#!/usr/bin/env python3
"""Check BigQuery table row count and exit non-zero if below threshold.

Usage: check_bq_load.py --project PROJECT --dataset DATASET --table TABLE [--min-rows N]
"""
import argparse
import sys
from google.cloud import bigquery


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--table", required=True)
    parser.add_argument("--min-rows", type=int, default=1)
    args = parser.parse_args()

    client = bigquery.Client(project=args.project)
    table_ref = f"`{args.project}.{args.dataset}.{args.table}`"
    query = f"SELECT COUNT(1) AS cnt FROM {table_ref}"
    job = client.query(query)
    rows = list(job.result())
    cnt = int(rows[0].cnt) if rows else 0
    print(f"count={cnt}")
    if cnt < args.min_rows:
        print(f"ERROR: row count {cnt} < min_rows {args.min_rows}")
        sys.exit(2)
    print("OK")


if __name__ == "__main__":
    main()
