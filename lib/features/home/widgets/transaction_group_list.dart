import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/transaction.dart';
import 'transaction_tile.dart';

/// 按日期分组的账目列表 + 空状态。
class TransactionGroupList extends StatelessWidget {
  const TransactionGroupList({
    super.key,
    required this.transactions,
    this.onTapTransaction,
  });

  final List<Transaction> transactions;
  final ValueChanged<Transaction>? onTapTransaction;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _EmptyState();
    }

    // 按日期（仅年月日）分组，保留倒序。
    final groups = <String, List<Transaction>>{};
    final order = <String>[];
    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      groups.putIfAbsent(key, () {
        order.add(key);
        return <Transaction>[];
      });
      groups[key]!.add(t);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final key in order)
          _DateGroup(
            date: groups[key]!.first.date,
            transactions: groups[key]!,
            onTapTransaction: onTapTransaction,
          ),
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.date,
    required this.transactions,
    this.onTapTransaction,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final ValueChanged<Transaction>? onTapTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text(
                DateUtilsEx.friendlyDate(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '共 ${transactions.length} 笔',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Column(
            children: [
              for (var i = 0; i < transactions.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 66),
                TransactionTile(
                  transaction: transactions[i],
                  onTap: onTapTransaction == null
                      ? null
                      : () => onTapTransaction!(transactions[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wallet_outlined, size: 64, color: ColorTokens.textSecondary),
          SizedBox(height: 12),
          Text(
            '本月还没有账目\n点击右下角 + 记一笔吧',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColorTokens.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
