using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.Use((context, next) =>
{
    // The Functions host Kestrel cannot forward 304 responses from the custom handler
    context.Request.Headers.Remove("If-None-Match");
    context.Request.Headers.Remove("If-Modified-Since");

    // MapStaticAssets has no OnPrepareResponse, so the validators are removed
    // just before the response starts.
    context.Response.OnStarting(() =>
    {
        context.Response.Headers.Remove("ETag");
        context.Response.Headers.Remove("Last-Modified");
        return Task.CompletedTask;
    });

    return next();
});

app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });

// UseRouting has to run after UseDefaultFiles, otherwise endpoint selection
// happens before the rewrite to index.html and "/" ends up as a 404.
app.UseRouting();

app.MapStaticAssets();

app.MapGet("/health", () => Results.Ok());

await app.RunAsync();
