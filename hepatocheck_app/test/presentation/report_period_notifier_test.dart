import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/presentation/providers/report_providers.dart';

ProviderContainer _container(DateTime today) {
  final container = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => today)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final today = DateTime(2026, 11, 10, 14);

  test('começa na semana atual', () {
    final container = _container(today);
    final period = container.read(reportPeriodProvider);

    expect(period.type, ReportPeriodType.week);
    expect(period.start, DateTime(2026, 11, 9));
  });

  test('não avança além do período atual', () {
    final container = _container(today);
    final notifier = container.read(reportPeriodProvider.notifier);

    expect(notifier.canGoNext, isFalse);
    notifier.next();
    expect(container.read(reportPeriodProvider).start, DateTime(2026, 11, 9));

    notifier.previous();
    expect(container.read(reportPeriodProvider).start, DateTime(2026, 11, 2));
    expect(notifier.canGoNext, isTrue);
    notifier.next();
    expect(container.read(reportPeriodProvider).start, DateTime(2026, 11, 9));
  });

  test('trocar para mês mantém a referência do período escolhido', () {
    final container = _container(today);
    final notifier = container.read(reportPeriodProvider.notifier);

    notifier.selectType(ReportPeriodType.month);
    expect(container.read(reportPeriodProvider).start, DateTime(2026, 11));

    notifier.previous();
    notifier.selectType(ReportPeriodType.week);
    expect(container.read(reportPeriodProvider).start, DateTime(2026, 9, 28));
  });
}
