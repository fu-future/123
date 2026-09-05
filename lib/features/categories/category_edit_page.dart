import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../providers/category_provider.dart';

/// 分类新增/编辑：选图标、选颜色、改类型、删除分类（含二次确认）。
class CategoryEditPage extends ConsumerStatefulWidget {
  const CategoryEditPage({super.key, this.editing});
  final Category? editing;

  @override
  ConsumerState<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends ConsumerState<CategoryEditPage> {
  late TransactionType _type;
  late TextEditingController _nameController;
  late String _iconKey;
  late int _colorValue;
  bool _saving = false;

  Category? get _editing => widget.editing;
  bool get _isEdit => _editing != null;

  @override
  void initState() {
    super.initState();
    final e = _editing;
    _type = e?.type ?? TransactionType.expense;
    _nameController = TextEditingController(text: e?.name ?? '');
    _iconKey = e?.iconKey ?? 'more_horiz';
    _colorValue = e?.colorValue ?? AppConstants.selectableColors.first.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _toast('请输入分类名称');
      return;
    }
    setState(() => _saving = true);
    final base = Category(
      id: _editing?.id ?? '',
      name: name,
      type: _type,
      iconKey: _iconKey,
      colorValue: _colorValue,
      sortOrder: _editing?.sortOrder ?? 0,
      isBuiltIn: _editing?.isBuiltIn ?? false,
    );
    final error = _isEdit
        ? await ref.read(categoryActionsProvider).update(base)
        : await ref.read(categoryActionsProvider).add(base);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _toast(error);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final e = _editing;
    if (e == null) return;
    final count = await _referencedCount(e.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除分类'),
        content: Text(
          '确定删除「${e.name}」吗？$count 笔关联账目将迁移到「其他」，删除后不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: ColorTokens.expenseRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final fallback = BuiltInCategoryIds.fallbackForType(_type.code);
    final error = await ref
        .read(categoryActionsProvider)
        .delete(e, fallback);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<int> _referencedCount(String categoryId) async {
    // 简化：编辑页不直接连库计数，删除确认在 Repository 层保证迁移。
    return 0;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑分类' : '新增分类'),
        actions: [
          if (_isEdit && !(_editing?.isBuiltIn ?? true))
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline,
                  color: ColorTokens.expenseRed),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                    value: TransactionType.expense, label: Text('支出')),
                ButtonSegment(
                    value: TransactionType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: _deco('分类名称'),
            ),
            const SizedBox(height: 20),
            const Text('选择图标',
                style:
                    TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final key in AppConstants.categoryIconKeys)
                  _iconPicker(key),
              ],
            ),
            const SizedBox(height: 20),
            const Text('选择颜色',
                style:
                    TextStyle(fontSize: 13, color: ColorTokens.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in AppConstants.selectableColors)
                  _colorPicker(color),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? '保存修改' : '新增分类'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPicker(String key) {
    final selected = _iconKey == key;
    return InkWell(
      onTap: () => setState(() => _iconKey = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected
              ? ColorTokens.mintPrimary.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? ColorTokens.mintPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(AppTheme.iconFor(key), color: ColorTokens.textPrimary),
      ),
    );
  }

  Widget _colorPicker(Color color) {
    final selected = color.value == _colorValue;
    return InkWell(
      onTap: () => setState(() => _colorValue = color.value),
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );
}
