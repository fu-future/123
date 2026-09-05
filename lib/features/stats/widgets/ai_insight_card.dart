import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../data/models/enums.dart';
import '../../../providers/classifier_provider.dart';
import '../../../providers/repository_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../services/ai/ai_insight_service.dart';

/// AI 洞察卡片：生成/加载/离线兜底文案。
class AiInsightCard extends ConsumerStatefulWidget {
  const AiInsightCard({super.key});
  @override
  ConsumerState<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<AiInsightCard> {
  String? _insight;
  bool _loading = false;

  Future<void> _generate() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    final aiClient = ref.read(aiClientProvider);
    if (settings == null || !settings.hasAiConfigured || aiClient == null) {
      setState(() {
        _insight =
            '尚未配置 AI，无法生成洞察。可在「设置」中填写 BaseURL / API Key / 模型名后开启智能分析。';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final summary = await ref
          .read(transactionRepositoryProvider)
          .watchMonthlySummary(DateTime.now().year, DateTime.now().month)
          .first;
      final range = ref.read(statsRangeProvider);
      final agg = await ref
          .read(transactionRepositoryProvider)
          .watchCategoryAggregation(
            range.start,
            range.end,
            TransactionType.expense,
          )
          .first;
      final service = AiInsightService(aiClient);
      final text = await service.generateInsight(agg, summary);
      if (mounted) setState(() => _insight = text);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _insight = 'AI 洞察生成失败，请稍后重试或检查网络与 AI 配置。');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 18, color: ColorTokens.sakuraAccent),
                const SizedBox(width: 8),
                const Text('AI 消费洞察',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: _loading ? null : _generate,
                  child: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('生成'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _insight ??
                  '点击「生成」，让 AI 基于你的收支结构给出消费建议。',
              style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: ColorTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
