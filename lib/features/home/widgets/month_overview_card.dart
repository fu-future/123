import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/money_utils.dart';

/// 本月结余卡片（渐变浅色背景 + 收入/支出大数字）。
class MonthOverviewCard extends StatelessWidget {
  const MonthOverviewCard({
    super.key,
    required this.incomeCents,
    required this.expenseCents,
  });

  final int incomeCents;
  final int expenseCents;

  @override
  Widget build(BuildContext context) {
    final balance = incomeCents - expenseCents;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorTokens.mintPrimary, ColorTokens.creamCard],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本月结余（元）',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            MoneyUtils.formatYuanPlain(balance),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryChip(
                label: '收入',
                color: ColorTokens.incomeGreen,
                amount: incomeCents,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: '支出',
                color: ColorTokens.expenseRed,
                amount: expenseCents,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.color,
    required this.amount,
  });
  final String label;
  final Color color;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('$label  ${MoneyUtils.formatYuanPlain(amount)}',
                style: const TextStyle(
                    fontSize: 13, color: ColorTokens.textPrimary)),
          ],
        ),
      ),
    );
  }
}
