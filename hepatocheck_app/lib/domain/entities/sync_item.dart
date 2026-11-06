enum SyncEntityType { drink, exam, goal }

enum SyncOperation { create, update, delete }

enum SyncStatus { pending, sending, failed, sent }

class SyncItem {
  const SyncItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.attempts = 0,
    this.status = SyncStatus.pending,
    this.lastError,
    required this.createdAt,
  });

  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final int attempts;
  final SyncStatus status;
  final String? lastError;
  final DateTime createdAt;

  SyncItem copyWith({
    SyncOperation? operation,
    Map<String, dynamic>? payload,
    int? attempts,
    SyncStatus? status,
    String? lastError,
  }) {
    return SyncItem(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
    );
  }
}
