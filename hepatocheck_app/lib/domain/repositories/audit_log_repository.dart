import '../entities/audit_entry.dart';

abstract interface class AuditLogRepository {
  Future<AuditEntry> record({
    required AuditOperation operation,
    required String entityId,
    Map<String, Object?>? content,
  });

  List<AuditEntry> entries();

  bool verifyChain();
}
