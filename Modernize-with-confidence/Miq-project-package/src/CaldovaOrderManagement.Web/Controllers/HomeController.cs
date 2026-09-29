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
    [HttpGet] public async Task<IActionResult> NewOrder() => View(await PopulateNewOrder(new NewOrderVm()));
    [HttpPost] public async Task<IActionResult> NewOrder(NewOrderVm request) {
        if(request.CustomerId<=0||request.ProductId<=0||request.Quantity<=0){request.Message="Choose a customer, product, and quantity greater than zero.";return View(await PopulateNewOrder(request));}
        try { var order=await data.CreateOrder(request); TempData["OrderMessage"]=$"Order {order.Number} was created and saved to Azure SQL."; return RedirectToAction(nameof(OrderDetail),new { id=order.Id }); }
        catch(Microsoft.Data.SqlClient.SqlException ex) when(ex.Number is >= 50000 and <= 50003) { request.Message=ex.Message; return View(await PopulateNewOrder(request)); }
        catch(Exception ex) { logger.LogError(ex,"New-order creation failed."); request.Message="The order could not be saved. Please retry."; return View(await PopulateNewOrder(request)); }
    }
    public async Task<IActionResult> OrderDetail(int id) { var order=await data.OrderDetail(id); return order is null ? NotFound() : View(order); }
    [HttpPost] public async Task<IActionResult> UpdateOrderStatus(int id,string status) {
        try { var order=await data.UpdateOrderStatus(id,status); if(order is null)return NotFound(); TempData["OrderMessage"]=$"Order status updated to {order.Status}."; return RedirectToAction(nameof(OrderDetail),new {id}); }
        catch(ArgumentException ex) { TempData["OrderMessage"]=ex.Message; return RedirectToAction(nameof(OrderDetail),new {id}); }
        catch(Exception ex) { logger.LogError(ex,"Order status update failed for {OrderId}.",id); TempData["OrderMessage"]="The status could not be updated. Please retry."; return RedirectToAction(nameof(OrderDetail),new {id}); }
    }
    private async Task<NewOrderVm> PopulateNewOrder(NewOrderVm model) { model.Customers=await data.Customers(""); model.Products=await data.Products(""); return model; }
    public IActionResult Error() => View();
}
