#!/bin/bash

# Delete all resource groups with names starting with test178530

# Get all resource groups that start with test178530
resource_groups=$(az group list --query "[?starts_with(name, 'test178')].name" -o tsv)

if [ -z "$resource_groups" ]; then
    echo "No resource groups found starting with test178"
    exit 0
fi

echo "Found the following resource groups to delete:"
echo "$resource_groups"
echo ""

# Confirm before deletion
read -p "Are you sure you want to delete these resource groups? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Deletion cancelled."
    exit 0
fi

# Delete each resource group
while IFS= read -r rg_name; do
    echo "Deleting resource group: $rg_name"
    az group delete --name "$rg_name" --yes --no-wait
done <<< "$resource_groups"

echo "Deletion commands submitted."
