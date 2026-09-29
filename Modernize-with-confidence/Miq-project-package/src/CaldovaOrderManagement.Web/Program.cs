using CaldovaOrderManagement.Web.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();
builder.Services.AddHttpClient();
builder.Services.AddSingleton<CaldovaRepository>();
builder.Services.AddSingleton<SemanticSearchService>();
builder.Logging.AddAzureWebAppDiagnostics();
var app = builder.Build();
app.Logger.LogInformation("Caldova application started from deployment revision {Revision}.", app.Configuration["CALDOVA_DEPLOYMENT_REVISION"] ?? "unknown");
app.UseExceptionHandler("/Home/Error");
app.UseStaticFiles();
app.UseRouting();
app.MapControllers();
app.MapControllerRoute(name: "default", pattern: "{controller=Home}/{action=Index}/{id?}");
app.Run();
