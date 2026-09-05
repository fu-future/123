import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../data/local/daos/transaction_dao.dart';

/// 收支趋势柱状图（按天：支出红 / 收入绿）。
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无趋势数据', style: TextStyle(color: Colors.grey))),
      );
    }

    // 聚合到「天」（TrendPoint 每类型一行），同一 dayEpoch 合并。
    final byDay = <int, Map<String, int>>{};
    for (final p in points) {
      byDay.putIfAbsent(p.dayEpoch, () => {'expense': 0, 'income': 0});
      byDay[p.dayEpoch]![p.type] = (byDay[p.dayEpoch]![p.type] ?? 0) + p.totalCents;
    }
    final days = byDay.keys.toList()..sort();
    final maxVal = byDay.values
        .fold<int>(0, (m, v) => [m, v['income'] ?? 0, v['expense'] ?? 0].reduce((a, b) => a > b ? a : b));

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < days.length; i++) {
      final v = byDay[days[i]]!;
      final income = (v['income'] ?? 0).toDouble();
      final expense = (v['expense'] ?? 0).toDouble();
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: expense / 100,
            color: ColorTokens.expenseRed,
            width: 7,
          ),
          BarChartRodData(
            toY: income / 100,
            color: ColorTokens.incomeGreen,
            width: 7,
          ),
        ],
        barsSpace: 3,
      ));
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: days.length <= 10,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  final d = DateTime.fromMillisecondsSinceEpoch(days[idx]);
                  return Text('${d.day}', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
          ),
          maxY: (maxVal / 100) * 1.1 + 1,
          barGroups: groups,
        ),
      ),
    );
  }
}
