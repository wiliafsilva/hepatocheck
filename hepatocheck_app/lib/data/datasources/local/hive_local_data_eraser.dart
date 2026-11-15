import 'package:hive_ce/hive.dart';

import '../../../domain/repositories/local_data_eraser.dart';

class HiveLocalDataEraser implements LocalDataEraser {
  HiveLocalDataEraser(this._boxes, {this._afterErase});

  final List<Box<dynamic>> _boxes;
  final Future<void> Function()? _afterErase;

  @override
  Future<void> eraseAll() async {
    for (final box in _boxes) {
      await box.clear();
      await box.flush();
    }
    await _afterErase?.call();
  }
}
