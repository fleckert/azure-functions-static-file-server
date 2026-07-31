using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// The Functions host Kestrel cannot forward 304 responses from the custom handler
// [2026-07-30T20:38:32.629Z] Executed 'Functions.http-proxy' (Succeeded, Id=a0298a0c-f7cb-4796-82fc-fad0fe7c34c2, Duration=3ms)
// [2026-07-30T20:38:32.630Z] An unhandled host error has occurred.
// [2026-07-30T20:38:32.630Z] Microsoft.AspNetCore.Server.Kestrel.Core: Writing to the response body is invalid for responses with status code 304.
// 
// this is not user facing in the browser and can be mitigatedby disabling caching headers in the custom handler.
// The Functions host will then always return 200 OK with the file content.
// 
// app.Use((context, next) =>
// {
//     
//     context.Request.Headers.Remove("If-None-Match");
//     context.Request.Headers.Remove("If-Modified-Since");
//     return next();
// });

// app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });
// app.UseStaticFiles(new StaticFileOptions
// {
//     OnPrepareResponse = ctx =>
//     {
//         ctx.Context.Response.Headers.Remove("ETag");
//         ctx.Context.Response.Headers.Remove("Last-Modified");
//     }
// });

app.UseDefaultFiles(new DefaultFilesOptions { DefaultFileNames = { "index.html" } });
app.UseRouting();
app.MapStaticAssets();

app.MapGet("/health", () => Results.Ok());

await app.RunAsync();
