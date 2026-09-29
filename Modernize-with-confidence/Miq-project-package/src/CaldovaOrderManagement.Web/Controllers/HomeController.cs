using CaldovaOrderManagement.Web.Models;
using CaldovaOrderManagement.Web.Services;
using Microsoft.AspNetCore.Mvc;

namespace CaldovaOrderManagement.Web.Controllers;

public class HomeController(CaldovaRepository data, ILogger<HomeController> logger) : Controller
{
    public async Task<IActionResult> Index() { try { return View(await data.Dashboard()); } catch (Exception ex) { logger.LogError(ex, "Dashboard database query failed."); throw; } }
    public async Task<IActionResult> Products(string? q) { ViewBag.Query=q; return View(await data.Products(q)); }
    public async Task<IActionResult> TraditionalSearch(string? q) { ViewBag.Query=q; return View(await data.Traditional(q)); }
    public async Task<IActionResult> Customers(string? q) { ViewBag.Query=q; return View(await data.Customers(q)); }
    public async Task<IActionResult> Orders(string? q) { ViewBag.Query=q; return View(await data.Orders(q)); }
    [HttpGet] public IActionResult NewOrder() => View(new NewOrderVm());
    [HttpPost] public async Task<IActionResult> NewOrder(NewOrderVm request) { if(request.CustomerId<=0||request.ProductId<=0||request.Quantity<=0){request.Message="Enter a valid customer ID, product ID, and quantity.";return View(request);} request.Message=await data.CreateOrder(request);return View(request); }
    public IActionResult Error() => View();
}
