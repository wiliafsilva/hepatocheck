// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class DrinkTypeAdapter extends TypeAdapter<DrinkType> {
  @override
  final typeId = 0;

  @override
  DrinkType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DrinkType.beer;
      case 1:
        return DrinkType.wine;
      case 2:
        return DrinkType.spirit;
      case 3:
        return DrinkType.cocktail;
      case 4:
        return DrinkType.other;
      default:
        return DrinkType.beer;
    }
  }

  @override
  void write(BinaryWriter writer, DrinkType obj) {
    switch (obj) {
      case DrinkType.beer:
        writer.writeByte(0);
      case DrinkType.wine:
        writer.writeByte(1);
      case DrinkType.spirit:
        writer.writeByte(2);
      case DrinkType.cocktail:
        writer.writeByte(3);
      case DrinkType.other:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrinkTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DrinkEntryAdapter extends TypeAdapter<DrinkEntry> {
  @override
  final typeId = 1;

  @override
  DrinkEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrinkEntry(
      id: fields[0] as String,
      type: fields[1] as DrinkType,
      volumeMl: (fields[2] as num).toDouble(),
      alcoholPercent: (fields[3] as num).toDouble(),
      quantity: (fields[4] as num).toInt(),
      consumedAt: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DrinkEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.volumeMl)
      ..writeByte(3)
      ..write(obj.alcoholPercent)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.consumedAt)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrinkEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LabExamAdapter extends TypeAdapter<LabExam> {
  @override
  final typeId = 2;

  @override
  LabExam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LabExam(
      id: fields[0] as String,
      examDate: fields[1] as DateTime,
      age: (fields[2] as num).toInt(),
      ast: (fields[3] as num).toDouble(),
      alt: (fields[4] as num).toDouble(),
      platelets: (fields[5] as num).toDouble(),
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LabExam obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.examDate)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.ast)
      ..writeByte(4)
      ..write(obj.alt)
      ..writeByte(5)
      ..write(obj.platelets)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncEntityTypeAdapter extends TypeAdapter<SyncEntityType> {
  @override
  final typeId = 3;

  @override
  SyncEntityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncEntityType.drink;
      case 1:
        return SyncEntityType.exam;
      case 2:
        return SyncEntityType.goal;
      default:
        return SyncEntityType.drink;
    }
  }

  @override
  void write(BinaryWriter writer, SyncEntityType obj) {
    switch (obj) {
      case SyncEntityType.drink:
        writer.writeByte(0);
      case SyncEntityType.exam:
        writer.writeByte(1);
      case SyncEntityType.goal:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncEntityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final typeId = 4;

  @override
  SyncOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperation.create;
      case 1:
        return SyncOperation.update;
      case 2:
        return SyncOperation.delete;
      default:
        return SyncOperation.create;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    switch (obj) {
      case SyncOperation.create:
        writer.writeByte(0);
      case SyncOperation.update:
        writer.writeByte(1);
      case SyncOperation.delete:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final typeId = 5;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.sending;
      case 2:
        return SyncStatus.failed;
      case 3:
        return SyncStatus.sent;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
      case SyncStatus.sending:
        writer.writeByte(1);
      case SyncStatus.failed:
        writer.writeByte(2);
      case SyncStatus.sent:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncItemAdapter extends TypeAdapter<SyncItem> {
  @override
  final typeId = 6;

  @override
  SyncItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncItem(
      id: fields[0] as String,
      entityType: fields[1] as SyncEntityType,
      entityId: fields[2] as String,
      operation: fields[3] as SyncOperation,
      payload: (fields[4] as Map).cast<String, dynamic>(),
      attempts: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      status: fields[6] == null ? SyncStatus.pending : fields[6] as SyncStatus,
      lastError: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.operation)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.attempts)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.lastError)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
