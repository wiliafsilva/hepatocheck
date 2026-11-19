import '../entities/sync_item.dart';

/// Anonimiza o documento antes de ir para o Firestore (tarefa 41).
///
/// - Só campos conhecidos passam (lista de permissão): nome, e-mail,
///   observações livres e qualquer campo novo ficam de fora por padrão.
/// - Data e hora viram só a data (meia-noite UTC do dia local).
/// - A idade exata vira faixa etária, por exemplo 40-49.
/// - O uid do Firebase não entra no documento; ele só aparece no caminho
///   `users/{uid}/...`, usado pelas regras de segurança.
class AnonymizeSyncPayload {
  const AnonymizeSyncPayload();

  static final _invalidDate = Object();

  static const _allowedFields = <SyncEntityType, Set<String>>{
    SyncEntityType.drink: {
      'type',
      'volumeMl',
      'alcoholPercent',
      'quantity',
      'consumedAt',
      'createdAt',
      'updatedAt',
    },
    SyncEntityType.exam: {
      'examDate',
      'ast',
      'alt',
      'platelets',
      'createdAt',
      'updatedAt',
    },
    SyncEntityType.goal: {
      'type',
      'target',
      'startDate',
      'endDate',
      'active',
      'createdAt',
      'updatedAt',
    },
  };

  static const _dateFields = {
    'consumedAt',
    'createdAt',
    'updatedAt',
    'examDate',
    'startDate',
    'endDate',
  };

  Map<String, dynamic> call(
    SyncEntityType entityType,
    Map<String, dynamic> payload,
  ) {
    final allowed = _allowedFields[entityType]!;
    final result = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (!allowed.contains(entry.key)) continue;
      if (_dateFields.contains(entry.key)) {
        final date = _dateOnly(entry.value);
        if (!identical(date, _invalidDate)) result[entry.key] = date;
        continue;
      }
      result[entry.key] = entry.value;
    }
    if (entityType == SyncEntityType.exam) {
      final range = ageRange(payload['age']);
      if (range != null) result['ageRange'] = range;
    }
    return result;
  }

  /// Faixa etária de dez em dez anos: 43 vira "40-49".
  static String? ageRange(Object? age) {
    if (age is! num || !age.isFinite || age < 0) return null;
    final lower = (age ~/ 10) * 10;
    return '$lower-${lower + 9}';
  }

  static Object? _dateOnly(Object? value) {
    if (value == null) return null;
    final date = switch (value) {
      DateTime() => value,
      String() => DateTime.tryParse(value),
      _ => null,
    };
    if (date == null) return _invalidDate;
    final local = date.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }
}
