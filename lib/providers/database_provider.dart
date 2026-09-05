import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';

/// AppDatabase 单例 Provider（异步构造）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.create();
  ref.onDispose(db.close);
  return db;
});
