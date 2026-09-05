import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../data/import_parse/parse_result.dart';
import '../../data/models/enums.dart';
import '../../data/models/transaction.dart';
import '../../providers/import_provider.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/parsed_bill_preview.dart';

/// 导入页：粘贴文本/选 CSV → 预览 → 确认导入。
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});
  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (result == null || result.files.single.path == null) return;
    try {
      final bytes = await result.files.single.xFile.readAsString();
      await ref.read(importProvider.notifier).parseCsv(bytes);
    } catch (e) {
      _toast('读取文件失败：$e');
    }
  }

  Future<void> _confirm() async {
    final state = ref.read(importProvider).valueOrNull ?? const ImportState();
    if (state.bills.isEmpty) {
      _toast('没有可导入的内容');
      return;
    }
    setState(() => _busy = true);
    final validBills = <ParsedBill>[];
    var failedCount = 0;
    for (var i = 0; i < state.bills.length; i++) {
      final b = state.bills[i];
      if (state.excludedIndexes.contains(i)) continue;
      if (!b.isValid) {
        failedCount++;
        continue;
      }
      validBills.add(b);
    }

    final txns = validBills.map((b) {
      return Transaction(
        id: '',
        amountCents: b.amountCents,
        type: b.type,
        categoryId: b.suggestedCategoryId ?? '',
        date: b.date ?? DateTime.now(),
        note: b.note,
        merchant: b.merchant,
        currency: 'CNY',
        source: TransactionSource.import,
      );
    }).toList();

    if (txns.isNotEmpty) {
      final error = await ref.read(transactionActionsProvider).addBatch(txns);
      if (error != null) {
        _toast(error);
        setState(() => _busy = false);
        return;
      }
    }
    await ref.read(importProvider.notifier).clear();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('导入成功 ${txns.length} 条'
        '${failedCount > 0 ? '，解析失败 $failedCount 条已跳过' : ''}');
    Navigator.of(context).pop();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final import = ref.watch(importProvider).valueOrNull ?? const ImportState();
    final hasBills = import.bills.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('导入账单')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        hintText: '粘贴账单文本（如短信/流水句式）…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(importProvider.notifier)
                            .parseText(_controller.text),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('解析'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _chooseCsv,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('选CSV'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (import.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(import.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            if (hasBills)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '解析出 ${import.bills.length} 条'
                  '${import.skippedCount > 0 ? '（CSV 跳过 ${import.skippedCount} 行）' : ''}'
                  ' · 已剔除 ${import.excludedIndexes.length} 条',
                  style: const TextStyle(
                      fontSize: 12, color: ColorTokens.textSecondary),
                ),
              ),
            const Divider(),
            Expanded(
              child: hasBills
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ParsedBillPreview(bills: import.bills),
                    )
                  : const Center(
                      child: Text('暂无解析结果',
                          style: TextStyle(color: Colors.grey)),
                    ),
            ),
            if (hasBills)
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('确认导入'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
