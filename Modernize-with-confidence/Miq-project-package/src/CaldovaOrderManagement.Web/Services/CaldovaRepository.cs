using System.Data;
using System.Text;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using CaldovaOrderManagement.Web.Models;
using Microsoft.Data.SqlClient;

namespace CaldovaOrderManagement.Web.Services;

public sealed class CaldovaRepository(IConfiguration config, IHttpClientFactory httpClientFactory)
{
    private SqlConnection Connection() {
        var server = config["SQL_SERVER_NAME"] ?? throw new InvalidOperationException("SQL_SERVER_NAME is not configured.");
        return new SqlConnection($"Server=tcp:{server}.database.windows.net,1433;Initial Catalog=CaldovaOrderManagement;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;");
    }
    private async Task<T> Scalar<T>(string sql, params SqlParameter[] parameters) {
        await using var cn = Connection(); await cn.OpenAsync(); await using var cmd = new SqlCommand(sql, cn); cmd.Parameters.AddRange(parameters);
        var value = await cmd.ExecuteScalarAsync(); return (T)Convert.ChangeType(value!, typeof(T));
    }
    public async Task CheckDatabaseReadiness() { _ = await Scalar<int>("SELECT 1;"); }
    public async Task<DashboardVm> Dashboard() {
        const string sql = "SELECT COUNT(*) FROM dbo.ProductCatalog WHERE IsActive=1; SELECT COUNT(*) FROM dbo.Inventory WHERE QuantityAvailable>0; SELECT COUNT(*) FROM dbo.Orders WHERE OrderStatus NOT IN ('Delivered','Cancelled'); SELECT COUNT(*) FROM dbo.Shipments WHERE ShipmentStatus <> 'Delivered'; SELECT COUNT(*) FROM dbo.SemanticSearchLog; SELECT TOP(10) SearchDate, TopScore FROM dbo.SemanticSearchLog ORDER BY SearchDate DESC; SELECT OrderStatus,COUNT(*) FROM dbo.Orders GROUP BY OrderStatus ORDER BY OrderStatus;";
        await using var cn=Connection(); await cn.OpenAsync(); await using var cmd=new SqlCommand(sql,cn); await using var r=await cmd.ExecuteReaderAsync();
        var values=new List<int>(); for(var i=0;i<5;i++){await r.ReadAsync(); values.Add(r.GetInt32(0)); await r.NextResultAsync();}
        var trend=new List<TrendPoint>(); while(await r.ReadAsync()) trend.Add(new TrendPoint(r.GetDateTime(0),r.GetDecimal(1))); trend.Reverse();
        await r.NextResultAsync(); var statuses=new List<MetricPoint>(); while(await r.ReadAsync()) statuses.Add(new MetricPoint(r.GetString(0),r.GetInt32(1)));
        return new DashboardVm(values[0],values[1],values[2],values[3],values[4],trend,statuses);
    }
    public async Task<IReadOnlyList<ProductVm>> Products(string? query) {
        const string sql="SELECT TOP(100) p.ProductID,p.SKU,p.ProductName,c.CategoryName,p.UnitPrice,ISNULL(SUM(i.QuantityAvailable),0) Available FROM dbo.ProductCatalog p JOIN dbo.ProductCategories c ON c.CategoryID=p.CategoryID LEFT JOIN dbo.Inventory i ON i.ProductID=p.ProductID WHERE p.IsActive=1 AND (@q='' OR p.ProductName LIKE '%'+@q+'%' OR p.SKU LIKE '%'+@q+'%' OR c.CategoryName LIKE '%'+@q+'%') GROUP BY p.ProductID,p.SKU,p.ProductName,c.CategoryName,p.UnitPrice ORDER BY p.ProductName";
        return await ReadProducts(sql,new SqlParameter("@q",query??""));
    }
    public async Task<IReadOnlyList<ProductVm>> Traditional(string? query) => await Products(query);
    private async Task<IReadOnlyList<ProductVm>> ReadProducts(string sql, params SqlParameter[] p) {
        var list=new List<ProductVm>(); await using var cn=Connection(); await cn.OpenAsync(); await using var cmd=new SqlCommand(sql,cn); cmd.Parameters.AddRange(p); await using var r=await cmd.ExecuteReaderAsync();
        while(await r.ReadAsync()) list.Add(new ProductVm(r.GetInt32(0),r.GetString(1),r.GetString(2),r.GetString(3),r.GetDecimal(4),r.GetInt32(5))); return list;
    }
    public async Task<IReadOnlyList<CustomerVm>> Customers(string? query) {
        const string sql="SELECT TOP(100) CustomerID,CustomerCode,CompanyName,CONCAT(ISNULL(ContactFirstName,''),' ',ISNULL(ContactLastName,'')),Email,Phone FROM dbo.Customers WHERE @q='' OR CompanyName LIKE '%'+@q+'%' OR CustomerCode LIKE '%'+@q+'%' OR Email LIKE '%'+@q+'%' ORDER BY CompanyName";
        var list=new List<CustomerVm>(); await using var cn=Connection(); await cn.OpenAsync(); await using var cmd=new SqlCommand(sql,cn);cmd.Parameters.AddWithValue("@q",query??"");await using var r=await cmd.ExecuteReaderAsync(); while(await r.ReadAsync()) list.Add(new CustomerVm(r.GetInt32(0),r.GetString(1),r.GetString(2),r.GetString(3).Trim(),r.IsDBNull(4)?null:r.GetString(4),r.IsDBNull(5)?null:r.GetString(5)));return list;
    }
    public async Task<IReadOnlyList<OrderVm>> Orders(string? query) {
        const string sql="SELECT TOP(100) o.OrderID,o.OrderNumber,c.CompanyName,o.OrderDate,o.OrderStatus,o.TotalAmount FROM dbo.Orders o JOIN dbo.Customers c ON c.CustomerID=o.CustomerID WHERE @q='' OR o.OrderNumber LIKE '%'+@q+'%' OR c.CompanyName LIKE '%'+@q+'%' ORDER BY o.OrderDate DESC";
        var list=new List<OrderVm>(); await using var cn=Connection();await cn.OpenAsync();await using var cmd=new SqlCommand(sql,cn);cmd.Parameters.AddWithValue("@q",query??"");await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())list.Add(new OrderVm(r.GetInt32(0),r.GetString(1),r.GetString(2),r.GetDateTime(3),r.GetString(4),r.GetDecimal(5)));return list;
    }
    public async Task<OrderDetailVm> CreateOrder(NewOrderVm request) {
        const string sql="SET XACT_ABORT ON; BEGIN TRAN; DECLARE @id int=(SELECT ISNULL(MAX(OrderID),0)+1 FROM dbo.Orders WITH (UPDLOCK,HOLDLOCK)), @line int=(SELECT ISNULL(MAX(OrderLineID),0)+1 FROM dbo.OrderLines WITH (UPDLOCK,HOLDLOCK)), @price decimal(18,2)=(SELECT UnitPrice FROM dbo.ProductCatalog WHERE ProductID=@product AND IsActive=1), @warehouse int=(SELECT TOP(1) WarehouseID FROM dbo.Inventory WITH (UPDLOCK,ROWLOCK) WHERE ProductID=@product AND QuantityAvailable>=@quantity ORDER BY QuantityAvailable DESC), @address int=(SELECT MIN(AddressID) FROM dbo.CustomerAddresses WHERE CustomerID=@customer), @number nvarchar(40)=CONCAT('SO-',CONVERT(char(8),SYSUTCDATETIME(),112),RIGHT(CONCAT('000000',@id),6)); IF NOT EXISTS(SELECT 1 FROM dbo.Customers WHERE CustomerID=@customer) THROW 50000,'Customer not found.',1; IF @price IS NULL THROW 50001,'Active product not found.',1; IF @warehouse IS NULL THROW 50002,'Insufficient available inventory for the requested quantity.',1; IF @address IS NULL THROW 50003,'Customer shipping address not found.',1; INSERT dbo.Orders(OrderID,OrderNumber,CustomerID,OrderDate,ShippingAddressID,BillingAddressID,WarehouseID,OrderStatus,SubTotal,TaxAmount,ShippingAmount,TotalAmount,CreatedBy,CreatedDate,ModifiedDate) VALUES(@id,@number,@customer,SYSUTCDATETIME(),@address,@address,@warehouse,'Pending',@price*@quantity,0,15,@price*@quantity+15,'Web UI',SYSUTCDATETIME(),SYSUTCDATETIME()); INSERT dbo.OrderLines(OrderLineID,OrderID,LineNumber,ProductID,WarehouseID,Quantity,UnitPrice,DiscountPercent,LineTotal) VALUES(@line,@id,1,@product,@warehouse,@quantity,@price,0,@price*@quantity); UPDATE dbo.Inventory SET QuantityOnHand=QuantityOnHand-@quantity WHERE ProductID=@product AND WarehouseID=@warehouse; COMMIT; SELECT @id;";
        var orderId=await Scalar<int>(sql,new SqlParameter("@customer",request.CustomerId),new SqlParameter("@product",request.ProductId),new SqlParameter("@quantity",request.Quantity));
        return await OrderDetail(orderId) ?? throw new InvalidOperationException("The order was created but could not be read back.");
    }
    public async Task<OrderDetailVm?> OrderDetail(int id) {
        const string sql="SELECT o.OrderID,o.OrderNumber,c.CompanyName,o.OrderDate,o.OrderStatus,o.SubTotal,o.TaxAmount,o.ShippingAmount,o.TotalAmount FROM dbo.Orders o JOIN dbo.Customers c ON c.CustomerID=o.CustomerID WHERE o.OrderID=@id; SELECT p.SKU,p.ProductName,l.Quantity,l.UnitPrice,l.LineTotal FROM dbo.OrderLines l JOIN dbo.ProductCatalog p ON p.ProductID=l.ProductID WHERE l.OrderID=@id ORDER BY l.LineNumber;";
        await using var cn=Connection(); await cn.OpenAsync(); await using var cmd=new SqlCommand(sql,cn); cmd.Parameters.AddWithValue("@id",id); await using var r=await cmd.ExecuteReaderAsync(); if(!await r.ReadAsync())return null;
        var header=new {Id=r.GetInt32(0),Number=r.GetString(1),Customer=r.GetString(2),Date=r.GetDateTime(3),Status=r.GetString(4),SubTotal=r.GetDecimal(5),Tax=r.GetDecimal(6),Shipping=r.GetDecimal(7),Total=r.GetDecimal(8)};
        await r.NextResultAsync(); var lines=new List<OrderLineVm>(); while(await r.ReadAsync())lines.Add(new OrderLineVm(r.GetString(0),r.GetString(1),r.GetInt32(2),r.GetDecimal(3),r.GetDecimal(4))); return new OrderDetailVm(header.Id,header.Number,header.Customer,header.Date,header.Status,header.SubTotal,header.Tax,header.Shipping,header.Total,lines);
    }
    public async Task<OrderDetailVm?> UpdateOrderStatus(int id,string status) {
        var validStatuses=new[]{"Pending","Processing","Shipped","Delivered","Cancelled"}; if(!validStatuses.Contains(status,StringComparer.OrdinalIgnoreCase))throw new ArgumentException("Select a valid order status.");
        const string sql="UPDATE dbo.Orders SET OrderStatus=@status,ModifiedDate=SYSUTCDATETIME() WHERE OrderID=@id;"; await using var cn=Connection(); await cn.OpenAsync(); await using var cmd=new SqlCommand(sql,cn); cmd.Parameters.AddWithValue("@id",id); cmd.Parameters.AddWithValue("@status",status); if(await cmd.ExecuteNonQueryAsync()==0)return null; return await OrderDetail(id);
    }
    public async Task<SemanticVm> Semantic(string query) {
        if(string.IsNullOrWhiteSpace(query)) return new SemanticVm("","Ask a product or medicine question to search the imported catalog.",[]);
        var vector=await Embed(query); const string sql="DECLARE @q VECTOR(1536)=CAST(@vector AS VECTOR(1536)); SELECT TOP(10) p.ProductID,p.ProductName,c.CategoryName,e.ContentText,CAST(1-VECTOR_DISTANCE('cosine',e.Embedding,@q) AS decimal(9,4)) Score FROM dbo.ProductDescriptionEmbeddings e JOIN dbo.ProductCatalog p ON p.ProductID=e.ProductID JOIN dbo.ProductCategories c ON c.CategoryID=p.CategoryID ORDER BY VECTOR_DISTANCE('cosine',e.Embedding,@q);";
        var results=new List<SemanticResult>(); await using(var cn=Connection()){await cn.OpenAsync();await using var cmd=new SqlCommand(sql,cn);cmd.Parameters.Add(new SqlParameter("@vector",SqlDbType.NVarChar,-1){Value=vector});await using var r=await cmd.ExecuteReaderAsync();while(await r.ReadAsync())results.Add(new SemanticResult(r.GetInt32(0),r.GetString(1),r.GetString(2),r.GetString(3),r.GetDecimal(4)));}
        var answer=await Answer(query,results); if(results.Count>0){var top=results[0];await LogSearch(query,top,results.Count);} return new SemanticVm(query,answer,results);
    }
    private async Task LogSearch(string q, SemanticResult top,int count) { const string sql="SET XACT_ABORT ON; BEGIN TRAN; INSERT dbo.SemanticSearchLog(SemanticSearchLogID,QueryText,TopProductID,TopProductName,TopScore,ResultCount,SearchDate) SELECT ISNULL(MAX(SemanticSearchLogID),0)+1,@q,@id,@name,@score,@count,SYSUTCDATETIME() FROM dbo.SemanticSearchLog WITH (UPDLOCK,HOLDLOCK); COMMIT;";await using var cn=Connection();await cn.OpenAsync();await using var cmd=new SqlCommand(sql,cn);cmd.Parameters.AddWithValue("@q",q);cmd.Parameters.AddWithValue("@id",top.ProductId);cmd.Parameters.AddWithValue("@name",top.Name);cmd.Parameters.AddWithValue("@score",top.Score);cmd.Parameters.AddWithValue("@count",count);await cmd.ExecuteNonQueryAsync();}
    private async Task<string> Embed(string input) { var json=await OpenAi("text-embedding-ada-002","2023-05-15",new {input});using var doc=JsonDocument.Parse(json);return doc.RootElement.GetProperty("data")[0].GetProperty("embedding").GetRawText(); }
    private async Task<string> Answer(string q,IReadOnlyList<SemanticResult> results) { if(results.Count==0)return "No matching products were found.";var context=string.Join("\n",results.Take(4).Select(x=>$"{x.Name} ({x.Category}): {x.Content}"));try {var json=await OpenAi("gpt-5-mini","2024-08-01-preview",new {messages=new[]{new{role="system",content="Answer only from the supplied catalog matches. Be concise and state that this is catalog information, not medical advice."},new{role="user",content=$"Question: {q}\nCatalog matches:\n{context}"}},max_completion_tokens=220});using var doc=JsonDocument.Parse(json);return doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "Top catalog matches are shown below.";}catch{return $"Best catalog match: {results[0].Name}. Review the matching products below.";}}
    private async Task<string> OpenAi(string deployment,string version,object body) {var endpoint=config["AZURE_OPENAI_ENDPOINT"]?.TrimEnd('/')??throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT is not configured.");var token=await new DefaultAzureCredential().GetTokenAsync(new TokenRequestContext(["https://cognitiveservices.azure.com/.default"]));var client=httpClientFactory.CreateClient();client.DefaultRequestHeaders.Authorization=new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer",token.Token);var response=await client.PostAsync($"{endpoint}/openai/deployments/{deployment}/{(deployment=="gpt-5-mini"?"chat/completions":"embeddings")}?api-version={version}",new StringContent(JsonSerializer.Serialize(body),Encoding.UTF8,"application/json"));response.EnsureSuccessStatusCode();return await response.Content.ReadAsStringAsync();}
}
