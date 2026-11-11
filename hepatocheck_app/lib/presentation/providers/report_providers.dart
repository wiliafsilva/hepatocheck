import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/consumption_report.dart';
import '../../domain/entities/report_period.dart';

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
      ReportPeriodNotifier.new,
    );

class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  DateTime get _today => ref.read(clockProvider)();

  @override
  ReportPeriod build() =>
      ReportPeriod.containing(_today, ReportPeriodType.week);

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

final consumptionReportProvider = Provider<ConsumptionReport?>((ref) {
  ref.watch(reportPeriodProvider);
  return null;
});
