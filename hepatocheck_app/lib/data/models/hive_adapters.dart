import 'package:hive_ce/hive.dart';

import '../../domain/entities/drink_entry.dart';
import '../../domain/entities/drink_type.dart';
import '../../domain/entities/lab_exam.dart';
import '../../domain/entities/sync_item.dart';

@GenerateAdapters([
  AdapterSpec<DrinkType>(),
  AdapterSpec<DrinkEntry>(),
  AdapterSpec<LabExam>(),
  AdapterSpec<SyncEntityType>(),
  AdapterSpec<SyncOperation>(),
  AdapterSpec<SyncStatus>(),
  AdapterSpec<SyncItem>(),
])
part 'hive_adapters.g.dart';
