#!/usr/bin/env bash
set -euo pipefail
# Simple dbt runner that executes dbt inside a Docker image.
# Expects the dbt project directory and profiles dir to be mounted or accessible.
# Usage: run_dbt.sh [dbt-args]

DBT_IMAGE="${DBT_IMAGE:-dbt-labs/dbt:1.4.4}"
DBT_PROJECT_DIR="${DBT_PROJECT_DIR:-/opt/app/dbt}"
PROFILES_DIR="${PROFILES_DIR:-/opt/app/.dbt}"

echo "DBT image: ${DBT_IMAGE}"
echo "DBT project dir: ${DBT_PROJECT_DIR}"
echo "DBT profiles dir: ${PROFILES_DIR}"

docker run --rm \
  -v "${DBT_PROJECT_DIR}:/work" \
  -v "${PROFILES_DIR}:/root/.dbt" \
  -w /work \
  ${DBT_IMAGE} dbt "$@"
