/// 账目类型。
enum TransactionType {
  expense('expense'),
  income('income');

  const TransactionType(this.code);
  final String code;

  static TransactionType fromCode(String code) =>
      code == 'income' ? TransactionType.income : TransactionType.expense;

  bool get isExpense => this == TransactionType.expense;
}

/// 账目来源标记（原生扩展点可追溯）。
enum TransactionSource {
  manual('manual'),
  import('import'),
  autoSms('auto_sms'),
  autoNotification('auto_notification');

  const TransactionSource(this.code);
  final String code;

  static TransactionSource fromCode(String? code) => switch (code) {
        'import' => TransactionSource.import,
        'auto_sms' => TransactionSource.autoSms,
        'auto_notification' => TransactionSource.autoNotification,
        _ => TransactionSource.manual,
      };
}

/// 同步状态（为未来云同步预留）。
enum SyncStatus {
  synced('synced'),
  pending('pending');

  const SyncStatus(this.code);
  final String code;
}
