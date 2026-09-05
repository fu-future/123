import 'package:drift/drift.dart';

import '../models/enums.dart';

/// Drift 类型转换器。
class Converters {
  Converters._();

  /// 类型字符串 <-> TransactionType。
  static const TypeConverter<TransactionType, String> transactionType =
      TypeConverter<TransactionType, String>(
    fromSql: (sql) => TransactionType.fromCode(sql),
    toSql: (value) => value.code,
  );
}
