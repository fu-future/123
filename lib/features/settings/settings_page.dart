import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/color_tokens.dart';
import '../../data/models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/repository_provider.dart';
import '../../router/app_router.dart';
import '../../services/export_import/csv_exporter.dart';
import '../../services/export_import/json_backup_service.dart';
import '../../services/sync/sync_service.dart';
import 'widgets/ai_config_section.dart';

/// 设置页：AI 配置、数据导出/备份、同步占位、关于。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _backup = JsonBackupService();
  final _csv = CsvExporter();
  final _sync = NoopSyncService();

  Future<Map<String, Category>> _loadCategoryMap() async {
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    return {for (final c in cats) c.id: c};
  }

  Future<void> _exportCsv() async {
    final txns = await ref.read(transactionRepositoryProvider).exportAll();
    final catMap = await _loadCategoryMap();
    final content = _csv.export(txns, catMap);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ledger_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(content);
    if (!mounted) return;
    _toast('已导出到：${file.path}');
  }

  Future<void> _backupJson() async {
    final txns = await ref.read(transactionRepositoryProvider).exportAll();
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ledger_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await _backup.exportToFile(file, txns, cats);
    if (!mounted) return;
    _toast('备份已保存：${file.path}');
  }

  Future<void> _restoreJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    try {
      final parsed = await _backup.importFromFile(file);
      // 导入分类与账目（经仓库统一写入）。
      final catRepo = ref.read(categoryRepositoryProvider);
      for (final c in parsed.categories) {
        if (!c.isBuiltIn) await catRepo.addCategory(c);
      }
      final txRepo = ref.read(transactionRepositoryProvider);
      await txRepo.addTransactionsBatch(parsed.transactions);
      if (!mounted) return;
      _toast('恢复完成：分类 ${parsed.categoriesImported}，账目 ${parsed.transactionsImported}');
    } catch (e) {
      if (mounted) _toast('恢复失败：$e');
    }
  }

  Future<void> _toast(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 智能分类',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const AiConfigSection(),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file,
                      color: ColorTokens.mintDark),
                  title: const Text('导出 CSV'),
                  subtitle: const Text('将全部账目导出为 CSV 文件'),
                  onTap: _exportCsv,
                ),
                ListTile(
                  leading: const Icon(Icons.backup,
                      color: ColorTokens.mintDark),
                  title: const Text('备份（JSON）'),
                  subtitle: const Text('导出全量 JSON 备份'),
                  onTap: _backupJson,
                ),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore,
                      color: ColorTokens.mintDark),
                  title: const Text('恢复备份'),
                  subtitle: const Text('从 JSON 备份文件恢复'),
                  onTap: _restoreJson,
                ),
                ListTile(
                  leading:
                      const Icon(Icons.cloud_off, color: ColorTokens.textSecondary),
                  title: const Text('云同步'),
                  subtitle: const Text('当前为本地模式（JSON 导出/导入）'),
                  trailing: const Text('占位',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pie_chart, color: ColorTokens.mintDark),
                  title: const Text('统计'),
                  onTap: () => context.goNamed('stats'),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.import_contacts, color: ColorTokens.mintDark),
                  title: const Text('导入账单'),
                  onTap: () => context.pushNamed('import'),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.category_outlined, color: ColorTokens.mintDark),
                  title: const Text('分类管理'),
                  onTap: () => context.goNamed('categories'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('${AppConstants.appName} v1.0.0',
                style:
                    const TextStyle(fontSize: 12, color: ColorTokens.textSecondary)),
          ),
        ],
      ),
    );
  }
}
