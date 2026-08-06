#!/usr/bin/env bash
set -euo pipefail

dotnet --version > /dev/null || { echo "dotnet CLI is not installed"; exit 1; }

PATH_CSPROJ="${1}"
PATH_OUTPUT="${2}"

[[ -z "${PATH_CSPROJ// }" ]] && { echo "PATH_CSPROJ must not be empty"; exit 1; }
[[ -z "${PATH_OUTPUT// }" ]] && { echo "PATH_OUTPUT must not be empty"; exit 1; }

echo ''
echo '-----------------------'
echo '| Building the app... |'
echo '-----------------------'
echo "  $PATH_CSPROJ"
echo "  $PATH_OUTPUT"
echo '-----------------------'
echo ''

dotnet publish     "$PATH_CSPROJ"   \
  --output         "$PATH_OUTPUT"   \
  --configuration  Release          \
  --property:OutputType=Exe         \
  --property:PublishSingleFile=true \
  --property:PublishTrimmed=true
