using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.Use((context, next) =>
{
    // The Functions host Kestrel cannot forward 304 responses from the custom handler
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

app.MapGet("/health", () => Results.Ok());

await app.RunAsync();
