import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class WifiMonitor {
  WifiMonitor({
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) : _checkConnectivity =
           checkConnectivity ?? Connectivity().checkConnectivity,
       _connectivityChanges =
           connectivityChanges ?? Connectivity().onConnectivityChanged;

  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _connectivityChanges;

  static bool isUnmeteredNetwork(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet);

  Future<bool> isOnWifi() async =>
      isUnmeteredNetwork(await _checkConnectivity());

  Stream<bool> watchWifi() {
    late final StreamController<bool> controller;
    StreamSubscription<List<ConnectivityResult>>? subscription;
    bool? last;
    var receivedChange = false;

    void emit(bool value) {
      if (value == last) return;
      last = value;
      controller.add(value);
    }

    controller = StreamController<bool>(
      onListen: () {
        subscription = _connectivityChanges.listen((results) {
          receivedChange = true;
          emit(isUnmeteredNetwork(results));
        }, onError: controller.addError);
        _checkConnectivity().then((results) {
          if (!receivedChange && !controller.isClosed) {
            emit(isUnmeteredNetwork(results));
          }
        }, onError: controller.addError);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }
}
