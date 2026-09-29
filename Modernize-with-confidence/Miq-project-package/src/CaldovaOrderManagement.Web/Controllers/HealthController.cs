using CaldovaOrderManagement.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace CaldovaOrderManagement.Web.Controllers;

[ApiController]
[Route("health")]
public sealed class HealthController(CaldovaRepository repository, ILogger<HealthController> logger) : ControllerBase
{
    [HttpGet("ready")]
    public async Task<IActionResult> Ready()
    {
        try { await repository.CheckDatabaseReadiness(); return Ok(new { status = "ready" }); }
        catch (Exception ex) { logger.LogError(ex, "Readiness check could not connect to Azure SQL using the App Service managed identity."); return StatusCode(StatusCodes.Status503ServiceUnavailable, new { status = "not-ready" }); }
    }
}
