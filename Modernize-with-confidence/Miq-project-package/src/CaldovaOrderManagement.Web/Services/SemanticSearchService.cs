using CaldovaOrderManagement.Web.Models;

namespace CaldovaOrderManagement.Web.Services;

public sealed class SemanticSearchService(CaldovaRepository repository)
{
    public async Task<SemanticComparisonVm> SearchAsync(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return new SemanticComparisonVm("", "Ask a product question to compare keyword and semantic retrieval.", [], []);
        var traditionalTask = repository.Traditional(query);
        var semanticTask = repository.Semantic(query);
        await Task.WhenAll(traditionalTask, semanticTask);
        var semantic = await semanticTask;
        return new SemanticComparisonVm(query, semantic.Answer, await traditionalTask, semantic.Results);
    }
}
