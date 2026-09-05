import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/color_tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../providers/category_provider.dart';
import '../../router/app_router.dart';

/// 分类管理列表（按类型分组的图标+名称）。
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses =
        ref.watch(categoryListProvider(TransactionType.expense)).valueOrNull ??
            const <Category>[];
    final incomes =
        ref.watch(categoryListProvider(TransactionType.income)).valueOrNull ??
            const <Category>[];

    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          _SectionLabel('支出分类'),
          ...expenses.map((c) => _tile(context, c)),
          const SizedBox(height: 12),
          _SectionLabel('收入分类'),
          ...incomes.map((c) => _tile(context, c)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('category_edit'),
        icon: const Icon(Icons.add),
        label: const Text('新增分类'),
      ),
    );
  }

  Widget _tile(BuildContext context, Category c) {
    final color = Color(c.colorValue);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        onTap: () => context.pushNamed('category_edit', extra: c),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _icon(c),
        ),
        title: Text(c.name),
        trailing: const Icon(Icons.chevron_right, color: ColorTokens.textSecondary),
      ),
    );
  }

  Widget _icon(Category c) => Icon(
        AppTheme.iconFor(c.iconKey),
        color: colorFor(c),
        size: 22,
      );

  static Color colorFor(Category c) => Color(c.colorValue);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorTokens.textSecondary)),
      );
}
