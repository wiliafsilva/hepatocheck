enum AuditOperation { create, update, delete }

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.operation,
    required this.entityId,
    required this.timestamp,
    required this.contentHash,
    required this.previousHash,
  });

  final String id;
  final AuditOperation operation;
  final String entityId;
  final DateTime timestamp;
  final String contentHash;
  final String previousHash;
}
