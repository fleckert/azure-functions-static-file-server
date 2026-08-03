#!/usr/bin/env bash
set -euo pipefail

az --version > /dev/null || { echo "az CLI is not installed"; exit 1; }

SUBSCRIPTION_ID="${1}"
RG_NAME="${2}"
NAME="${3}"

# delete
FUNCTIONAPP_ID=$(                        \
  az functionapp show                    \
    --subscription   "$SUBSCRIPTION_ID"  \
    --resource-group "$RG_NAME"          \
    --name           "$NAME"             \
    --query          "id"                \
    --output         tsv                 \
    --only-show-errors                   \
)

APPSERVICEPLAN_ID=$(                     \
  az functionapp show                    \
    --subscription   "$SUBSCRIPTION_ID"  \
    --resource-group "$RG_NAME"          \
    --name           "$NAME"             \
    --query          "appServicePlanId"  \
    --output         tsv                 \
    --only-show-errors                   \
)

STORAGEACCOUNT_ID=$(                     \
  az storage account show                \
    --subscription   "$SUBSCRIPTION_ID"  \
    --resource-group "$RG_NAME"          \
    --name           "$NAME"             \
    --query          "id"                \
    --output         tsv                 \
    --only-show-errors                   \
)

if [ -n "$FUNCTIONAPP_ID" ]; then
  az functionapp delete                  \
    --ids "$FUNCTIONAPP_ID"              \
    --only-show-errors
fi

if [ -n "$APPSERVICEPLAN_ID" ]; then
  az appservice plan delete              \
    --ids "$APPSERVICEPLAN_ID"           \
    --yes                                \
    --only-show-errors
fi

if [ -n "$STORAGEACCOUNT_ID" ]; then
  az storage account delete              \
    --ids "$STORAGEACCOUNT_ID"           \
    --yes                                \
    --only-show-errors
fi