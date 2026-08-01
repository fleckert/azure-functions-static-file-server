#!/usr/bin/env bash
set -euo pipefail

TENANT_ID=$(      az account show --query tenantId --output tsv --only-show-errors)
SUBSCRIPTION_ID=$(az account show --query id       --output tsv --only-show-errors)
LOCATION="germanywestcentral"

RG_NAME="azure-functions-static-file-server"
RUN_ID=$(date +%s)
APP_NAME="sttcflsrvr$RUN_ID"
STORAGE_NAME="sttcflsrvr$RUN_ID"

echo ''
echo '-----------------------'
echo '| Building the app... |'
echo '-----------------------'
echo ''

rm -rf dist

dotnet publish StaticFilesHandler/StaticFilesHandler.csproj                                                                                          \
  --configuration                   Release                                                                                                          \
  --runtime                         'linux-x64'                                                                                                      \
  --self-contained                  true                                                                                                             \
  --output                          dist                                                                                                             \
  --property:DebugSymbols=false                                                                                                                      \
  --property:DebugType=None                                                                                                                          \
  --property:InvariantGlobalization=true                                                                                                             \
  --property:OutputType=Exe                                                                                                                          \
  --property:PublishSingleFile=true                                                                                                                  \
  --property:PublishTrimmed=true

# create semantics, no update
if ! az functionapp show                                                                                                                             \
       --subscription               "$SUBSCRIPTION_ID"                                                                                               \
       --resource-group             "$RG_NAME"                                                                                                       \
       --name                       "$APP_NAME"                                                                                                      \
       --output                     none                                                                                                             \
       --only-show-errors 2>/dev/null; then
  
  echo ''
  echo '-----------------------------------'
  echo '| Creating the Azure resources... |'
  echo '-----------------------------------'
  echo ''

  ROLE_STORAGE_BLOB_DATA="Storage Blob Data Contributor"
  
  # az group create                                                                                                                                    \
  #   --subscription                  "$SUBSCRIPTION_ID"                                                                                               \
  #   --name                          "$RG_NAME"                                                                                                       \
  #   --location                      "$LOCATION"                                                                                                      \
  #   --output                        none                                                                                                             \
  #   --only-show-errors
  
  az storage account create                                                                                                                          \
    --subscription                  "$SUBSCRIPTION_ID"                                                                                               \
    --resource-group                "$RG_NAME"                                                                                                       \
    --location                      "$LOCATION"                                                                                                      \
    --name                          "$STORAGE_NAME"                                                                                                  \
    --sku                           "Standard_LRS"                                                                                                   \
    --min-tls-version               TLS1_2                                                                                                           \
    --allow-blob-public-access      false                                                                                                            \
    --allow-shared-key-access       false                                                                                                            \
    --output                        none                                                                                                             \
    --only-show-errors

  az functionapp create                                                                                                                              \
    --subscription                  "$SUBSCRIPTION_ID"                                                                                               \
    --resource-group                "$RG_NAME"                                                                                                       \
    --name                          "$APP_NAME"                                                                                                      \
    --disable-app-insights          true                                                                                                             \
    --https-only                    true                                                                                                             \
    --flexconsumption-location      "$LOCATION"                                                                                                      \
    --runtime                       "custom"                                                                                                         \
    --instance-memory               512                                                                                                              \
    --maximum-instance-count        1                                                                                                                \
    --assign-identity               "[system]"                                                                                                       \
    --storage-account               "$STORAGE_NAME"                                                                                                  \
    --deployment-storage-auth-type  SystemAssignedIdentity                                                                                           \
    --output                        none                                                                                                             \
    --only-show-errors

  az functionapp config appsettings delete                                                                                                           \
    --subscription                  "$SUBSCRIPTION_ID"                                                                                               \
    --resource-group                "$RG_NAME"                                                                                                       \
    --name                          "$APP_NAME"                                                                                                      \
    --setting-names                 AzureWebJobsStorage                                                                                              \
    --output                        none                                                                                                             \
    --only-show-errors

  az functionapp config appsettings set                                                                                                              \
    --subscription                  "$SUBSCRIPTION_ID"                                                                                               \
    --resource-group                "$RG_NAME"                                                                                                       \
    --name                          "$APP_NAME"                                                                                                      \
    --settings                      AzureWebJobsStorage__accountName="$STORAGE_NAME"                                                                 \
                                    AzureWebJobsStorage__credential=managedidentity                                                                  \
    --output                        none                                                                                                             \
    --only-show-errors

  # func cli does not support tls1.3
  az resource update                                                                                                                                 \
    --subscription                  "$SUBSCRIPTION_ID"                                                                                               \
    --ids                           "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/$APP_NAME/config/web"     \
    --set                           properties.minTlsVersion=1.2                                                                                     \
                                    properties.scmMinTlsVersion=1.2                                                                                  \
                                    properties.healthCheckPath=/health                                                                               \
                                    properties.http20Enabled=true                                                                                    \
    --output                        none                                                                                                             \
    --only-show-errors

  STORAGE_ACCOUNT_ID=$(                                                                                                                              \
    az storage account show                                                                                                                          \
      --subscription                "$SUBSCRIPTION_ID"                                                                                               \
      --resource-group              "$RG_NAME"                                                                                                       \
      --name                        "$STORAGE_NAME"                                                                                                  \
      --query                       'id'                                                                                                             \
      --output                      tsv                                                                                                              \
      --only-show-errors                                                                                                                             \
  )

  FUNCTIONAPP_PRINCIPAL_ID=$(                                                                                                                        \
    az functionapp identity show                                                                                                                     \
      --subscription                "$SUBSCRIPTION_ID"                                                                                               \
      --resource-group              "$RG_NAME"                                                                                                       \
      --name                        "$APP_NAME"                                                                                                      \
      --query                       principalId                                                                                                      \
      --output                      tsv                                                                                                              \
      --only-show-errors                                                                                                                             \
  )

  az role assignment create                                                                                                                          \
    --assignee-principal-type       ServicePrincipal                                                                                                 \
    --role                          "$ROLE_STORAGE_BLOB_DATA"                                                                                        \
    --assignee-object-id            "$FUNCTIONAPP_PRINCIPAL_ID"                                                                                      \
    --scope                         "$STORAGE_ACCOUNT_ID"                                                                                            \
    --output                        none                                                                                                             \
    --only-show-errors

  # Wait for role assignment to be visible (up to 5 minutes)
  ROLE_CHECK_TIMEOUT=300
  ROLE_CHECK_INTERVAL=10
  ROLE_CHECK_ELAPSED=0
  while [ $ROLE_CHECK_ELAPSED -lt $ROLE_CHECK_TIMEOUT ]; do
    ROLE_COUNT=$(                                                                                                                                    \
      az role assignment list                                                                                                                        \
        --subscription              "$SUBSCRIPTION_ID"                                                                                               \
        --assignee-object-id        "$FUNCTIONAPP_PRINCIPAL_ID"                                                                                      \
        --scope                     "$STORAGE_ACCOUNT_ID"                                                                                            \
        --role                      "$ROLE_STORAGE_BLOB_DATA"                                                                                        \
        --query                     "length(@)"                                                                                                      \
        --output                    tsv                                                                                                              \
        --only-show-errors
      )
    if [ "${ROLE_COUNT:-0}" -gt 0 ]; then
      break
    fi
    ROLE_CHECK_ELAPSED=$((ROLE_CHECK_ELAPSED + ROLE_CHECK_INTERVAL))
    if [ $ROLE_CHECK_ELAPSED -lt $ROLE_CHECK_TIMEOUT ]; then
      sleep $ROLE_CHECK_INTERVAL
    fi
  done
  
  if [ $ROLE_CHECK_ELAPSED -ge $ROLE_CHECK_TIMEOUT ]; then
    echo "ERROR: $ROLE_STORAGE_BLOB_DATA role did not propagate within 5 minutes."
    exit 1
  fi
fi

echo ''
echo '------------------------'
echo '| Deploying the app... |'
echo '------------------------'
echo ''

PUBLISH_RETRY_MAX=5
PUBLISH_RETRY_COUNT=0

while true; do
  PUBLISH_OUTPUT=$(func azure functionapp publish "$APP_NAME") || true

  if echo "$PUBLISH_OUTPUT" | grep -q "The deployment was successful!"; then
    echo ''
    echo "$PUBLISH_OUTPUT"
    echo ''
    echo '-----------------------'
    echo '| Deployment complete |'
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

