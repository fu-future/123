import '../../data/local/daos/transaction_dao.dart';
import '../ai/ai_client.dart';

/// 统计页 AI 洞察：聚合数据 → prompt → 文字洞察；失败返回空（UI 兜底文案）。
class AiInsightService {
  AiInsightService(this._client);
  final AiClient _client;

  Future<String> generateInsight(
    List<CategoryAggregation> data,
    MonthlySummary summary,
  ) async {
    final top = data.isEmpty
        ? '暂无支出数据'
        : data
            .map((c) => '${c.categoryName} ${c.totalCents / 100}元')
            .take(5)
            .join('、');
    final system =
        '你是理财助手。根据用户本月收入支出概况，给出2-3条简短、中肯的消费建议。只输出建议正文。';
    final user = '本月收入${summary.incomeCents / 100}元，支出${summary.expenseCents / 100}元，'
        '支出分类Top: $top。';
    return _client.chatCompletion(system, user);
  }
}
