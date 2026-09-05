import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../router/app_router.dart';
import 'widgets/month_overview_card.dart';
import 'widgets/transaction_group_list.dart';

/// 首页：本月结余卡片 + 月份切换 + 分组流水 + FAB。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final txAsync = ref.watch(transactionListProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final transactions =
        txAsync.valueOrNull ?? const <Transaction>[];

    final summary = summaryAsync.valueOrNull;
    final title = '${month.year}年${month.month}月';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => ref
                  .read(currentMonthProvider.notifier)
                  .state = _shift(month, -1),
            ),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => ref
                  .read(currentMonthProvider.notifier)
                  .state = _shift(month, 1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: MonthOverviewCard(
              incomeCents: summary?.incomeCents ?? 0,
              expenseCents: summary?.expenseCents ?? 0,
            ),
          ),
          Expanded(
            child: TransactionGroupList(
              transactions: transactions,
              onTapTransaction: (t) => context.pushNamed(
                'record',
                extra: EditPayload(transaction: t),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('record'),
        child: const Icon(Icons.add),
      ),
    );
  }

  DateTime _shift(DateTime m, int delta) =>
      DateTime(m.year, m.month + delta, 1);
}
