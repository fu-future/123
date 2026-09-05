import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../data/models/app_settings.dart';
import '../../../providers/classifier_provider.dart';
import '../../../providers/settings_provider.dart';

/// AI 配置表单（BaseURL/ApiKey/模型名 + 连接测试）。
class AiConfigSection extends ConsumerStatefulWidget {
  const AiConfigSection({super.key});
  @override
  ConsumerState<AiConfigSection> createState() => _AiConfigSectionState();
}

class _AiConfigSectionState extends ConsumerState<AiConfigSection> {
  final _base = TextEditingController();
  final _key = TextEditingController();
  final _model = TextEditingController();
  String? _testResult;
  bool _testing = false;
  bool _loaded = false;

  @override
  void dispose() {
    _base.dispose();
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  void _syncFromSettings() {
    final s = ref.read(settingsProvider).valueOrNull;
    if (s != null && !_loaded) {
      _base.text = s.aiBaseUrl;
      _key.text = s.aiApiKey;
      _model.text = s.aiModel;
      _loaded = true;
    }
  }

  Future<void> _save() async {
    final settings = AppSettings(
      aiBaseUrl: _base.text.trim(),
      aiApiKey: _key.text.trim(),
      aiModel: _model.text.trim(),
    );
    await ref.read(settingsProvider.notifier).save(settings);
    if (!mounted) return;
    _toast('已保存 AI 配置');
  }

  Future<void> _test() async {
    final aiClient = ref.read(aiClientProvider);
    if (aiClient == null) {
      setState(() => _testResult = '配置不完整，请填写三项后测试');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final ok = await aiClient.testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = ok ? '连接成功 ✓' : '连接失败，请检查地址与密钥';
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    _syncFromSettings();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text('AI 智能分类（可选）',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        TextField(
          controller: _base,
          decoration: const InputDecoration(
              labelText: 'BaseURL', hintText: 'https://api.openai.com/v1'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _key,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'API Key'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _model,
          decoration: const InputDecoration(labelText: '模型名'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: _save, child: const Text('保存')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _testing ? null : _test,
                child: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('测试连接'),
              ),
            ),
          ],
        ),
        if (_testResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _testResult!,
              style: TextStyle(
                fontSize: 13,
                color: _testResult!.contains('成功')
                    ? ColorTokens.incomeGreen
                    : ColorTokens.expenseRed,
              ),
            ),
          ),
      ],
    );
  }
}
