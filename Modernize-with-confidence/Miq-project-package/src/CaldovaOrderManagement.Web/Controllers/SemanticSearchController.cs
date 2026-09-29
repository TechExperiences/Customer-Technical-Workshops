using CaldovaOrderManagement.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace CaldovaOrderManagement.Web.Controllers;

public sealed class SemanticSearchController(SemanticSearchService search) : Controller
{
    public async Task<IActionResult> Index(string? query, string? q) => View(await search.SearchAsync(query ?? q ?? ""));
}
