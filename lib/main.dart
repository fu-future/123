import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/database_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 提前预热数据库（含首次内置分类种子），再挂载应用。
  final container = ProviderContainer();
  container.read(databaseProvider);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LedgerApp(),
    ),
  );
}
