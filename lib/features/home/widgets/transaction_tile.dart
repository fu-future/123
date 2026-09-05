import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/money_utils.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../providers/category_provider.dart';

/// 单条账目行（图标/名称/备注/金额着色）。
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final isExpense = transaction.type.isExpense;
    final color = category == null
        ? (isExpense ? ColorTokens.expenseRed : ColorTokens.incomeGreen)
        : Color(category.colorValue);
    final iconKey = category?.iconKey ?? (isExpense ? 'more_horiz' : 'wallet');

    final amountText = isExpense
        ? MoneyUtils.formatSigned(-transaction.amountCents)
        : MoneyUtils.formatSigned(transaction.amountCents);
    final amountColor =
        isExpense ? ColorTokens.expenseRed : ColorTokens.incomeGreen;

    final subtitle = [
      if (transaction.merchant.isNotEmpty) transaction.merchant,
      if (transaction.note.isNotEmpty) transaction.note,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      leading: _CategoryBadge(iconKey: iconKey, color: color),
      title: Text(
        category?.name ?? '未分类',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ColorTokens.textPrimary,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: ColorTokens.textSecondary),
            ),
      trailing: Text(
        amountText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: amountColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.iconKey, required this.color});
  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        AppTheme.iconFor(iconKey),
        color: color,
        size: 22,
      ),
    );
  }
}
