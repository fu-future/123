import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/repositories/settings_repository.dart';
import 'repository_provider.dart';

/// 设置状态控制器（AsyncNotifier）。
class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.load();
  }

  /// 保存设置。命名避开 riverpod 2.6 中 AsyncNotifierBase.update 的同名冲突。
  Future<void> save(AppSettings settings) async {
    state = AsyncValue.data(settings);
    await ref.read(settingsRepositoryProvider).save(settings);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
