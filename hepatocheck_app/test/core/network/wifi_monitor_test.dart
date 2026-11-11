import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/core/network/wifi_monitor.dart';

void main() {
  test('Wi-Fi e cabo contam como rede sem consumo de dados móveis', () {
    expect(WifiMonitor.isUnmeteredNetwork([ConnectivityResult.wifi]), isTrue);
    expect(
      WifiMonitor.isUnmeteredNetwork([ConnectivityResult.ethernet]),
      isTrue,
    );
    expect(
      WifiMonitor.isUnmeteredNetwork([
        ConnectivityResult.mobile,
        ConnectivityResult.wifi,
      ]),
      isTrue,
    );
  });

  test('dados móveis, VPN sozinha e sem rede não liberam a sincronização', () {
    expect(
      WifiMonitor.isUnmeteredNetwork([ConnectivityResult.mobile]),
      isFalse,
    );
    expect(WifiMonitor.isUnmeteredNetwork([ConnectivityResult.vpn]), isFalse);
    expect(WifiMonitor.isUnmeteredNetwork([ConnectivityResult.none]), isFalse);
    expect(WifiMonitor.isUnmeteredNetwork(const []), isFalse);
  });

  test('consulta o estado atual da conexão', () async {
    final monitor = WifiMonitor(
      checkConnectivity: () async => [ConnectivityResult.wifi],
      connectivityChanges: const Stream.empty(),
    );

    expect(await monitor.isOnWifi(), isTrue);
  });

  test('avisa só quando entra ou sai do Wi-Fi', () async {
    final changes = StreamController<List<ConnectivityResult>>.broadcast();
    final monitor = WifiMonitor(
      checkConnectivity: () async => [ConnectivityResult.mobile],
      connectivityChanges: changes.stream,
    );
    final events = <bool>[];
    final subscription = monitor.watchWifi().listen(events.add);

    await Future<void>.delayed(Duration.zero);
    changes
      ..add([ConnectivityResult.mobile])
      ..add([ConnectivityResult.wifi])
      ..add([ConnectivityResult.wifi])
      ..add([ConnectivityResult.none])
      ..add([ConnectivityResult.ethernet]);
    await Future<void>.delayed(Duration.zero);

    expect(events, [false, true, false, true]);
    await subscription.cancel().timeout(const Duration(seconds: 2));
    expect(changes.hasListener, isFalse);
    await changes.close();
  });

  test('uma mudança que chega antes da consulta inicial prevalece', () async {
    final initialCheck = Completer<List<ConnectivityResult>>();
    final changes = StreamController<List<ConnectivityResult>>.broadcast();
    final monitor = WifiMonitor(
      checkConnectivity: () => initialCheck.future,
      connectivityChanges: changes.stream,
    );
    final events = <bool>[];
    final subscription = monitor.watchWifi().listen(events.add);

    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    initialCheck.complete([ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);

    expect(events, [true]);
    await subscription.cancel();
    await changes.close();
  });
}
