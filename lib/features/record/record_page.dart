import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/classifier_provider.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/amount_input.dart';
import 'widgets/category_grid_selector.dart';
import 'widgets/save_bar.dart';

/// 记账页（新增/编辑复用）。编辑时传入 [editing]。
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key, this.editing});
  final Transaction? editing;

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  late TransactionType _type;
  late int _amountCents;
  late String _categoryId;
  late DateTime _date;
  late final TextEditingController _noteController;
  late final TextEditingController _merchantController;
  String? _suggestedId;
  bool _saving = false;

  Transaction? get _editing => widget.editing;
  bool get _isEdit => _editing != null;

  int _amountGeneration = 0;

  @override
  void initState() {
    super.initState();
    final e = _editing;
    _type = e?.type ?? TransactionType.expense;
    _amountCents = e?.amountCents ?? 0;
    _categoryId = e?.categoryId ?? '';
    _date = e?.date ?? DateTime.now();
    _noteController = TextEditingController(text: e?.note ?? '');
    _merchantController = TextEditingController(text: e?.merchant ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _switchType(TransactionType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = '';
      _suggestedId = null;
    });
  }

  void _onAmountChanged(int cents) => _amountCents = cents;

  Future<void> _suggest() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _amountCents <= 0) return;
    final classifier = ref.read(classifierProvider);
    final id = await classifier.classify(text, _type);
    if (!mounted) return;
    setState(() => _suggestedId = id);
  }

  Future<void> _save({bool andNext = false}) async {
    if (_amountCents <= 0) {
      _toast('请输入金额');
      return;
    }
    if (_categoryId.isEmpty) {
      _toast('请选择分类');
      return;
    }
    setState(() => _saving = true);
    final actions = ref.read(transactionActionsProvider.notifier);
    final t = Transaction(
      id: _editing?.id ?? '',
      amountCents: _amountCents,
      type: _type,
      categoryId: _categoryId,
      date: _date,
      note: _noteController.text.trim(),
      merchant: _merchantController.text.trim(),
      currency: 'CNY',
      source: _editing?.source ?? TransactionSource.manual,
    );
    final error = _isEdit ? await actions.save(t) : await actions.add(t);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _toast(error);
      return;
    }
    if (andNext) {
      _resetForNext();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 「再记一笔」：清空金额/备注/分类，保留类型与日期。
  void _resetForNext() {
    setState(() {
      _amountCents = 0;
      _amountGeneration++;
      _categoryId = '';
      _suggestedId = null;
      _noteController.clear();
      _merchantController.clear();
    });
    _toast('已保存，可继续记账');
  }

  /// QA-F1：编辑模式删除账目 + 二次确认。
  Future<void> _delete() async {
    final e = _editing;
    if (e == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账目'),
        content: const Text('确定删除该账目吗？删除后不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorTokens.expenseRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await ref.read(transactionActionsProvider.notifier).delete(e.id);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoryListProvider(_type)).valueOrNull ?? const <Category>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑账目' : '记一笔'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline,
                  color: ColorTokens.expenseRed),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTypeSwitch(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AmountInput(
                          valueCents: _amountCents,
                          generation: _amountGeneration,
                          onChanged: _onAmountChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('选择分类',
                          style: TextStyle(
                              fontSize: 13,
                              color: ColorTokens.textSecondary)),
                    ),
                    CategoryGridSelector(
                      categories: categories,
                      selectedId: _categoryId,
                      suggestedId: _suggestedId,
                      onSelect: (c) =>
                          setState(() => _categoryId = c.id),
                    ),
                    const SizedBox(height: 16),
                    _buildNoteField(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            SaveBar(
              onSave: () => _save(),
              onSaveAndNext: _isEdit ? null : () => _save(andNext: true),
              saving: _saving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SegmentedButton<TransactionType>(
        segments: const [
          ButtonSegment(
              value: TransactionType.expense,
              label: Text('支出'),
              icon: Icon(Icons.trending_down)),
          ButtonSegment(
              value: TransactionType.income,
              label: Text('收入'),
              icon: Icon(Icons.trending_up)),
        ],
        selected: {_type},
        onSelectionChanged: (s) => _switchType(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: ColorTokens.mintPrimary,
          selectedForegroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _noteController,
            maxLines: 1,
            onChanged: (_) {},
            onSubmitted: (_) => _suggest(),
            decoration: _inputDeco('备注（可选，支持 AI 分类）'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _merchantController,
            maxLines: 1,
            decoration: _inputDeco('商户（可选）'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _suggest,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('智能分类', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E1D6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 18, color: ColorTokens.textSecondary),
            const SizedBox(width: 10),
            Text(
              '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: ColorTokens.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E1D6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E1D6)),
      ),
    );
  }
}
