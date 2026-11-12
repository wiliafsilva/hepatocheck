import 'package:hive_ce/hive.dart';

import '../../../domain/repositories/local_data_eraser.dart';

class HiveLocalDataEraser implements LocalDataEraser {
  HiveLocalDataEraser(this._boxes);

  final List<Box<dynamic>> _boxes;

  @override
  Future<void> eraseAll() async {
    for (final box in _boxes) {
      await box.clear();
      await box.flush();
    }
  }
}
