using CaldovaOrderManagement.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace CaldovaOrderManagement.Web.Controllers;

[ApiController]
[Route("dashboard")]
public sealed class DashboardController(CaldovaRepository repository) : ControllerBase
{
    [HttpGet("live")]
    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public async Task<IActionResult> Live() => Ok(await repository.Dashboard());
}
