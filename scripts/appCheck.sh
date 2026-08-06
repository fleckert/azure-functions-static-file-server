#!/usr/bin/env bash
set -euo pipefail

URL="${1}"

[[ -z "${URL// }" ]] && { echo "URL must not be empty"; exit 1; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo ''
echo '--------------------------'
echo '| Checking deployment... |'
echo '--------------------------'
echo "  $URL"
echo '--------------------------'
echo ''

for i in {1..30}; do
  HTTP=$(curl -s -o index.html -w "%{http_code}" "$URL")
  if [ "$HTTP" = "200" ]; then
      break
  fi
  echo "Checking '$URL'... (last status: $HTTP)"
  sleep 2
done

[ "$HTTP" = "200" ] || { echo "Expected HTTP 200, got $HTTP"; exit 1; }

diff -q index.html "$SCRIPT_DIR/../dist/wwwroot/index.html" || { echo "Downloaded index.html does not match source file"; exit 1; }

echo ''
echo '------------------------------------------------------------'
echo "index.html content:"
echo '------------------------------------------------------------'
echo ''
cat index.html
echo ''
echo '------------------------------------------------------------'
