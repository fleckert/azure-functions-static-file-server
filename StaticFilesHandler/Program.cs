using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using System;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

var environmentVariableCustomHandlerPort = Environment.GetEnvironmentVariable("FUNCTIONS_CUSTOMHANDLER_PORT");

if(!ushort.TryParse(environmentVariableCustomHandlerPort, out ushort port))
{
    throw new InvalidOperationException($"Environment Variable 'FUNCTIONS_CUSTOMHANDLER_PORT' is set to '{environmentVariableCustomHandlerPort}' and does not specify a valid port number.");
}

app.Urls.Add($"http://127.0.0.1:{port}");
app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });
app.UseStaticFiles();

app.MapGet("/health", () => Results.Ok());

await app.RunAsync();