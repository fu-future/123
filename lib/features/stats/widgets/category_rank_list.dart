import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_utils.dart';
import '../../../data/local/daos/transaction_dao.dart';

/// 分类金额排行列表（含占比条）。
class CategoryRankList extends StatelessWidget {
  const CategoryRankList({super.key, required this.data});
  final List<CategoryAggregation> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (s, c) => s + c.totalCents);
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < data.length; i++)
          _RankRow(
            index: i,
            aggregation: data[i],
            ratio: total == 0 ? 0 : data[i].totalCents / total,
          ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.index,
    required this.aggregation,
    required this.ratio,
  });
  final int index;
  final CategoryAggregation aggregation;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final color = Color(aggregation.colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('${index + 1}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E))),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppTheme.iconFor(aggregation.iconKey),
                color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aggregation.categoryName,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            MoneyUtils.formatYuanPlain(aggregation.totalCents),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE05C6E)),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: Text('${(ratio * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E))),
          ),
        ],
      ),
    );
  }
}
