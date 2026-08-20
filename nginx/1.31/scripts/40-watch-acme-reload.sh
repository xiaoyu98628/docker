#!/bin/sh
set -eu

MARKER="/usr/config/acme/nginx.reload"

echo "INFO: Watching ACME reload marker: $MARKER"

(
  last="$(stat -c %Y "$MARKER" 2>/dev/null || true)"

  while sleep 10; do
    current="$(stat -c %Y "$MARKER" 2>/dev/null || true)"

    [ -n "$current" ] || continue
    [ "$current" != "$last" ] || continue

    last="$current"

    if nginx -t; then
      echo "INFO: ACME certificate changed, reloading Nginx"
      nginx -s reload
    else
      echo "Error: ACME certificate changed, but Nginx configuration test failed" >&2
    fi
  done
) &
