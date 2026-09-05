import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables.dart';

part 'database.g.dart';

/// 本地唯一数据源：Drift(SQLite)。连接经 [driftDatabase] 初始化，三端可用。
@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    MerchantRules,
  ],
  daos: [
    TransactionDao,
    CategoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await categoryDao.seedBuiltInCategories();
        },
      );

  /// 便捷工厂：三端（Android/iOS/Windows）默认连接。
  static AppDatabase create() {
    return AppDatabase(driftDatabase(name: 'ledger_app'));
  }
}
