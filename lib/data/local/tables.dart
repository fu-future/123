import 'package:drift/drift.dart';

/// 统一数据类型：日期存 UTC epoch 毫秒。
class DateTimeEpochConverter extends TypeConverter<DateTime, int> {
  const DateTimeEpochConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true).toLocal();

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}

/// 账目表（金额分、UUID 主键、sync 预留字段）。
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get type => text()(); // 'expense' | 'income'
  TextColumn get categoryId => text()();
  DateTimeColumn get date => dateTime()(); // epoch ms
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get merchant => text().withDefault(const Constant(''))();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get syncVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 分类表。
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'expense' | 'income'
  TextColumn get iconKey => text().withDefault(const Constant('more_horiz'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF8FD9A8))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 商户→分类映射规则表（本期建表，RuleClassifier 暂用静态 Map，见 QA-F7）。
@DataClassName('MerchantRuleRow')
class MerchantRules extends Table {
  TextColumn get id => text()();
  TextColumn get keyword => text()();
  TextColumn get categoryId => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
