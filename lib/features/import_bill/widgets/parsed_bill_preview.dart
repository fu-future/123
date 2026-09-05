import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money_utils.dart';
import '../../../data/import_parse/parse_result.dart';
import '../../../data/models/category.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/import_provider.dart';

/// 解析结果预览列表（可逐条修改分类/剔除；失败行置灰默认剔除，见 QA-F3/F8）。
class ParsedBillPreview extends ConsumerWidget {
  const ParsedBillPreview({super.key, required this.bills});
  final List<ParsedBill> bills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final import = ref.watch(importProvider).valueOrNull ?? const ImportState();
    final allCategories = ref.watch(allCategoriesProvider).valueOrNull ?? [];

    return Column(
      children: [
        for (var i = 0; i < bills.length; i++)
          _BillRow(
            index: i,
            bill: bills[i],
            excluded: import.excludedIndexes.contains(i),
            categories: allCategories,
          ),
      ],
    );
  }
}

class _BillRow extends ConsumerWidget {
  const _BillRow({
    required this.index,
    required this.bill,
    required this.excluded,
    required this.categories,
  });

  final int index;
  final ParsedBill bill;
  final bool excluded;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valid = bill.isValid;
    return Opacity(
      opacity: valid ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Checkbox(
                value: valid && !excluded,
                onChanged: valid
                    ? (_) => ref
                        .read(importProvider.notifier)
                        .toggleExclude(index)
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!valid)
                      Text(bill.parseError ?? '解析失败',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                    Text(
                      bill.merchant.isEmpty ? bill.note : bill.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (bill.merchant.isNotEmpty && bill.note.isNotEmpty)
                      Text(bill.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    if (valid)
                      _buildCategorySelector(ref)
                    else
                      const Text('不可导入',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                valid ? MoneyUtils.formatYuan(bill.amountCents) : '解析失败',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: bill.type.isExpense
                      ? const Color(0xFFE05C6E)
                      : const Color(0xFF3FAE78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(WidgetRef ref) {
    // QA-F8：空分类渲染占位，避免空 items DropdownButton 断言。
    if (categories.isEmpty) {
      return const Text('暂无可选分类',
          style: TextStyle(fontSize: 11, color: Colors.grey));
    }
    final import = ref.watch(importProvider).valueOrNull ?? const ImportState();
    final current = import.bills[index].suggestedCategoryId;
    return DropdownButton<String>(
      value: current ?? categories.first.id,
      isDense: true,
      items: [
        for (final c in categories)
          DropdownMenuItem<String>(value: c.id, child: Text(c.name)),
      ],
      onChanged: (v) {
        if (v != null) {
          ref.read(importProvider.notifier).setSuggestedCategory(index, v);
        }
      },
    );
  }
}
