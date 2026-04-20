#!/bin/sh
set -eu

# If /opt/kestra/flows is missing or empty, copy flows from /app/flows (if present)
if [ ! -d "/opt/kestra/flows" ] || [ -z "$(ls -A /opt/kestra/flows 2>/dev/null || true)" ]; then
  if [ -d "/app/flows" ]; then
    echo "[entrypoint] copying flows from /app/flows to /opt/kestra/flows"
    mkdir -p /opt/kestra/flows
    cp -a /app/flows/. /opt/kestra/flows || true
    chown -R kestra:kestra /opt/kestra/flows || true
    chmod -R a+rX /opt/kestra/flows || true
  else
    echo "[entrypoint] /app/flows not found; nothing to copy"
  fi
fi

# Exec Kestra binary if present, otherwise exec provided command
if [ -x "/app/kestra" ]; then
  exec /app/kestra "$@"
elif [ -x "/opt/kestra/bin/kestra" ]; then
  exec /opt/kestra/bin/kestra "$@"
else
  exec "$@"
fi
