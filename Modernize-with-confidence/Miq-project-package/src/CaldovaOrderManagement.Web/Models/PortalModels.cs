namespace CaldovaOrderManagement.Web.Models;

public record DashboardVm(int Products, int AvailableProducts, int OpenOrders, int PendingShipments, int Searches, IReadOnlyList<TrendPoint> Trend);
public record TrendPoint(DateTime Date, decimal Score);
public record ProductVm(int ProductId, string Sku, string Name, string Category, decimal Price, int Available);
public record CustomerVm(int Id, string Code, string Company, string? Contact, string? Email, string? Phone);
public record OrderVm(int Id, string Number, string Customer, DateTime Date, string Status, decimal Total);
public record SemanticResult(int ProductId, string Name, string Category, string Content, decimal Score);
public record SemanticVm(string Query, string Answer, IReadOnlyList<SemanticResult> Results);
public class NewOrderVm { public int CustomerId { get; set; } public int ProductId { get; set; } public int Quantity { get; set; } = 1; public string? Message { get; set; } }
