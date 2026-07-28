# Requirements

- a Bash-compatible shell
- [.NET SDK 10.0](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)
- [Azure Functions Core Tools v4](https://github.com/Azure/azure-functions-core-tools)
- [Azure CLI](https://github.com/Azure/azure-cli) with [Azure CLI extension authV2](https://github.com/Azure/azure-cli-extensions/blob/main/src/authV2/README.rst)<br/>(`az extension add --name authV2 --upgrade --only-show-errors`)
- Azure Subscription and RBAC permissions
  -  `Contributor` and `User Access Administrator` or
  - `Role Based Access Control Administrator` or
  - `Owner`
- permissions to create Microsoft Entra Id applications or own an existing application

## Build and deploy

Run
- `az login`
- `./deploy.sh`

to

1. Publish the .NET project into `dist`
2. Provision resource group, storage account, and Function App (Flex Consumption)
3. Configure managed identity and app settings
4. Configure authentication (Entra ID)
5. Publish app with `func azure functionapp publish`

