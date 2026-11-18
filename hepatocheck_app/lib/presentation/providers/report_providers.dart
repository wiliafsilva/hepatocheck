import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/consumption_report.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/usecases/build_consumption_report.dart';
import 'drink_providers.dart';

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _midnight;

  @override
  DateTime build() {
    ref.onDispose(() => _midnight?.cancel());
    return _schedule(ref.watch(clockProvider)());
  }

  void refresh() => state = _schedule(ref.read(clockProvider)());

  DateTime _schedule(DateTime now) {
    _midnight?.cancel();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(tomorrow.difference(now), refresh);
    return now;
  }
}

final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
      ReportPeriodNotifier.new,
    );

class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  DateTime? _shownOn;

  DateTime get _today => ref.read(todayProvider);

  @override
  ReportPeriod build() {
    final today = ref.watch(todayProvider);
    final shown = stateOrNull;
    final shownOn = _shownOn;
    _shownOn = today;
    if (shown == null || shownOn == null) {
      return ReportPeriod.containing(today, ReportPeriodType.week);
    }
    if (shown.isCurrent(shownOn)) {
      return ReportPeriod.containing(today, shown.type);
    }
    return shown;
  }

  bool get canGoNext => !state.next.isFuture(_today);

  void selectType(ReportPeriodType type) {
    if (type == state.type) return;
    final reference = state.isCurrent(_today) ? _today : state.start;
    state = ReportPeriod.containing(reference, type);
  }

  void previous() => state = state.previous;

  void next() {
    if (canGoNext) state = state.next;
  }
}

final buildConsumptionReportProvider = Provider(
  (ref) => BuildConsumptionReport(ref.watch(convertToStandardDrinksProvider)),
);

final consumptionReportProvider = Provider<ConsumptionReport>((ref) {
  final build = ref.watch(buildConsumptionReportProvider);
  return build(
    ref.watch(drinksProvider),
    ref.watch(reportPeriodProvider),
    today: ref.watch(todayProvider),
  );
});
