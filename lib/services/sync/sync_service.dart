import '../../data/models/transaction.dart';

/// 同步结果。
class SyncResult {
  const SyncResult({this.pushed = 0, this.error});
  final int pushed;
  final String? error;
}

/// 同步服务抽象：基于「lastUpdatedAt 增量拉推 + UUID 冲突以 syncVersion 高者胜」假设。
abstract interface class SyncService {
  Future<SyncResult> push(List<Transaction> changed);
  Future<List<Transaction>> pull(DateTime since);
}

/// 占位实现（本期落地为 JSON 导出/导入，见架构 1.3）。
class NoopSyncService implements SyncService {
  @override
  Future<SyncResult> push(List<Transaction> changed) async =>
      const SyncResult(pushed: 0);

  @override
  Future<List<Transaction>> pull(DateTime since) async => [];
}
