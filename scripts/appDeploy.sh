#!/usr/bin/env bash
set -euo pipefail

func --version > /dev/null || { echo "func CLI is not installed"; exit 1; }

NAME="${1}"

[[ -z "${NAME// }" ]] && { echo "NAME must not be empty"; exit 1; }

echo ''
echo '------------------------'
echo '| Deploying the app... |'
echo '------------------------'
echo "  $NAME"
echo '------------------------'
echo ''

PUBLISH_RETRY_MAX=5
PUBLISH_RETRY_COUNT=0

while true; do
  PUBLISH_OUTPUT=$(func azure functionapp publish "$NAME") || true

  if echo "$PUBLISH_OUTPUT" | grep -q "The deployment was successful!"; then
    echo ''
    echo "$PUBLISH_OUTPUT"
    echo ''
    echo '-----------------------'
    echo '| Deployment complete |'
    echo '-----------------------'
    echo "  https://$NAME.azurewebsites.net"
    echo '-----------------------'
    echo ''

    exit 0
  else
    PUBLISH_RETRY_COUNT=$((PUBLISH_RETRY_COUNT + 1))

    if [ $PUBLISH_RETRY_COUNT -lt $PUBLISH_RETRY_MAX ]; then
      echo "Retrying deployment in 30 seconds... (attempt $PUBLISH_RETRY_COUNT/$PUBLISH_RETRY_MAX)"
      sleep 30
    else
      echo ''
      echo "$PUBLISH_OUTPUT"
      echo ''
      echo '---------------------'
      echo '| Deployment failed |'
      echo '---------------------'
      echo ''

      exit 1
    fi
  fi
done
