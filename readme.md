## azure-functions-static-file-server

This repository demonstrates the usage of an [Azure Function custom handler](https://learn.microsoft.com/en-us/azure/azure-functions/functions-custom-handlers) to serve static html assets from an [Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions).


```mermaid
graph LR
    User["👤 User"]
    Endpoint["Azure<br/>Function"]
    Handler["Custom<br/>Handler"]
    AspNet["ASP.NET Core<br/>Application"]

    User -->|HTTP<br/>GET/HEAD/OPTIONS| Endpoint
    Endpoint -->| HTTP<br/>GET/HEAD/OPTIONS| Handler
    Handler -->|HTTP<br/>ET/HEAD/OPTIONS| AspNet
    AspNet -->|HTTP<br/>html/js/css| Handler
    Handler -->| HTTP<br/>html/js/css| Endpoint
    Endpoint -->|HTTP<br/>html/js/css| User
```

Let's (ab)use the [Azure Function](https://learn.microsoft.com/en-us/azure/azure-functions) as a networking appliance/proxy/... into 'my' application.

## Why all this...

I liked the `Azure Storage Website with a CDN with a custom domain` pattern and the costs increased due to sundowned services and [Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-overview) being expensive.

I like the full feature set of the [Azure AppService Plan Flex Consumption](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan).

I like the Azure Function programming model while being quiet comfortable to not take a dependency on it.

This inspired me... https://anthonychu.ca/post/azure-functions-static-file-server/ ... but felt kind of a lot of code compared to
```csharp
app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });
app.UseStaticFiles();
```


The best reason... to fool around and try something and... why not?


## Requirements

- a Bash-compatible shell
- [.NET SDK 10.0](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)
- [Azure Functions Core Tools v4](https://github.com/Azure/azure-functions-core-tools)
- [Azure CLI](https://github.com/Azure/azure-cli) with [Azure CLI extension authV2](https://github.com/Azure/azure-cli-extensions/blob/main/src/authV2/README.rst)<br/>(`az extension add --name authV2 --upgrade --only-show-errors`)
- an Azure Subscription with RBAC permissions on a resource group
  - `Contributor` and `User Access Administrator` or
  - `Owner`

## Build and deploy

Log in to Azure
```
az login
```

and update the resource names in [deploy.sh](./deploy.sh)

```
RG_NAME="<fill_in>"
APP_NAME="$RG_NAME"
STORAGE_NAME="$RG_NAME"
```

and start the deployment

```
chmod +x ./deploy.sh
./deploy.sh
```

# Extend

- Update [wwwroot](./StaticFilesHandler/wwwroot/) with your html assets...
- Extend the `methods` in [function.json](./function/function.json) for a full blown [ASP.NET Core](https://dotnet.microsoft.com/en-us/apps/aspnet) application.