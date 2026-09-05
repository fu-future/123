import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/local/daos/transaction_dao.dart';

/// 分类占比环形图（fl_chart PieChart）。
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.data});

  final List<CategoryAggregation> data;

  @override
  Widget build(BuildContext context) {
    final total =
        data.fold<int>(0, (sum, c) => sum + c.totalCents);
    if (total <= 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('暂无支出数据', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    final sections = data
        .map((c) => PieChartSectionData(
              value: c.totalCents.toDouble(),
              title: total == 0
                  ? ''
                  : '${(c.totalCents / total * 100).toStringAsFixed(0)}%',
              color: Color(c.colorValue),
              radius: 52,
              titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ))
        .toList();
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 48,
          sectionsSpace: 2,
          startDegreeOffset: -90,
        ),
      ),
    );
  }
}
