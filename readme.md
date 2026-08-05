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

The purpose of this repository is not to replace:

- Azure Static Web Apps
- Azure Storage Static Websites
- App Service

Instead it demonstrates how [Azure Function Custom Handler](https://learn.microsoft.com/en-us/azure/azure-functions/functions-custom-handlers) can host a standard ASP.NET Core application and static assets with minimal Azure Functions-specific code on [Azure AppService Plan Flex Consumption](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan).

## Why all this...

Using an [Azure Static Web App](https://azure.microsoft.com/en-us/products/app-service/static) is an option... but this repo is about static html/js/css hosting in a cost effective manner on Azure.

Using an [Azure AppService Plan Flex Consumption](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan) has these upsides
- up to [500](https://azure.github.io/AppService/2017/08/08/FAQ-App-Service-Domain-and-Custom-Domains.html) [custom domains](https://learn.microsoft.com/en-us/azure/app-service/overview-custom-domains)
- unlimited [Microsoft Entra ID](https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id) [authentication](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization)
- extensive Azure regions support
- [virtual network integration](https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration)
- very cost effective


I like the Azure Function programming model while being quiet comfortable to not take a dependency on it.

This inspired me... https://anthonychu.ca/post/azure-functions-static-file-server/ ... but felt kind of a lot of code compared to
```csharp
app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });
app.UseRouting();
app.MapStaticAssets();
```


The best reason... to fool around and try something and... why not?


## Requirements

- a Bash-compatible shell
- [.NET SDK 10.0](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)
- [Azure Functions Core Tools v4](https://github.com/Azure/azure-functions-core-tools)
- [Azure CLI](https://github.com/Azure/azure-cli)
- an Azure Subscription with RBAC permissions on a resource group
  - `Contributor` and `User Access Administrator` or
  - `Owner`

## Local execution

Start the Static File Server with

```
make
```

and visit http://localhost:7071.




## Deploy to Azure

Log in to Azure

```
az login
```
and update the values in [Makefile](./Makefile) or create an `.env` file with

```
SUBSCRIPTION_ID="<fill_in>"
RG_NAME="<fill_in>"
NAME="<fill_in>"
```

and start the deployment

```
make deploy
```

## Extend

- Update [wwwroot](./StaticFilesHandler/wwwroot/) with your html assets...
- Extend the `methods` in [http-proxy/function.json](./http-proxy/function.json) for a full blown [ASP.NET Core](https://dotnet.microsoft.com/en-us/apps/aspnet) application.


## links
- Azure Functions
  - https://learn.microsoft.com/en-us/azure/azure-functions/functions-custom-handlers
  -  https://json.schemastore.org/host.json
- Azure AppService
  - https://learn.microsoft.com/en-us/azure/app-service/configure-ssl-certificate
  - https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale
  - https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-how-to
  - https://json.schemastore.org/host.json
- Azure Static Web Apps Pläne
  - https://learn.microsoft.com/en-us/azure/static-web-apps/plans
  - https://learn.microsoft.com/en-us/azure/static-web-apps/quotas
  - https://learn.microsoft.com/en-us/azure/static-web-apps/faq
  - https://learn.microsoft.com/en-us/azure/static-web-apps/deployment-token-management
- Azure CDN
  - https://learn.microsoft.com/en-us/azure/cdn/classic-cdn-retirement-faq
- Azure Front Door
  - https://learn.microsoft.com/en-us/azure/frontdoor/understanding-pricing
- ASMC-Änderung Juli 2025 / Nachtrag November 2025 — https://go.microsoft.com/fwlink/?linkid=2328307
- MapStaticAssets — https://learn.microsoft.com/en-us/aspnet/core/fundamentals/static-files
- EU Data Boundary, non regional servicel — https://learn.microsoft.com/en-us/privacy/eudb/eu-data-boundary-configure-azure-nonregional-services

## Known Limitations


### 304s

The Functions host Kestrel cannot forward 304 responses from the custom handler
```
[2026-07-30T20:38:32.629Z] Executed 'Functions.http-proxy' (Succeeded, Id=a0298a0c-f7cb-4796-82fc-fad0fe7c34c2, Duration=3ms)
[2026-07-30T20:38:32.630Z] An unhandled host error has occurred.
[2026-07-30T20:38:32.630Z] Microsoft.AspNetCore.Server.Kestrel.Core: Writing to the response body is invalid for responses with status code 304.
```
this is not user facing in the browser and can be mitigatedby disabling caching headers in the custom handler.

The Functions host will then always return 200 OK with the file content.

```csharp
app.Use((context, next) => {
    
    context.Request.Headers.Remove("If-None-Match");
    context.Request.Headers.Remove("If-Modified-Since");
    return next();
});
app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        ctx.Context.Response.Headers.Remove("ETag");
        ctx.Context.Response.Headers.Remove("Last-Modified");
    }
});
```

### Local execution and `Unhealthy` events

To avoid warnings like 
```JSON
[Tag=''] Process reporting unhealthy: Unhealthy. Health check entries are {"azure.functions.web_host.lifecycle":{"status":"Healthy","description":null},"azure.functions.script_host.lifecycle":{"status":"Healthy","description":null},"azure.functions.webjobs.storage":{"status":"Unhealthy","description":"A timeout occurred while running check."}}
```

start the [Azurite emulator](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite)

```
azurite --inMemoryPersistence
```