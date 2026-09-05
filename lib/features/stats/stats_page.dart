import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../providers/stats_provider.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/category_rank_list.dart';
import 'widgets/trend_chart.dart';

/// 统计页：时间粒度切换 + 环形图 + 趋势图 + 排行 + AI 洞察。
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);
    final range = ref.watch(statsRangeProvider);
    final agg = ref.watch(expenseCategoryAggProvider).valueOrNull ?? const [];
    final trend = ref.watch(trendProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text('统计 · ${range.label}')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SegmentedButton<StatsPeriod>(
              segments: const [
                ButtonSegment(value: StatsPeriod.day, label: Text('日')),
                ButtonSegment(value: StatsPeriod.week, label: Text('周')),
                ButtonSegment(value: StatsPeriod.month, label: Text('月')),
              ],
              selected: {period},
              onSelectionChanged: (s) => ref
                  .read(statsPeriodProvider.notifier)
                  .state = s.first,
            ),
            const SizedBox(height: 12),
            _section('分类占比'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CategoryPieChart(data: agg),
              ),
            ),
            _section('收支趋势'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TrendChart(points: trend),
              ),
            ),
            _section('分类排行'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: CategoryRankList(data: agg),
              ),
            ),
            const AiInsightCard(),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorTokens.textSecondary)),
      );
}
