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

  group('Virada do dia', () {
    late DateTime now;
    late ProviderContainer container;

    setUp(() {
      now = DateTime(2026, 11, 15, 23, 50);
      container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
    });

    test('o período atual passa para a semana nova', () {
      expect(container.read(reportPeriodProvider).start, DateTime(2026, 11, 9));

      now = DateTime(2026, 11, 16, 0, 1);
      container.read(todayProvider.notifier).refresh();

      final period = container.read(reportPeriodProvider);
      expect(period.start, DateTime(2026, 11, 16));
      expect(container.read(reportPeriodProvider.notifier).canGoNext, isFalse);
    });

    test('mantém o tipo do período ao virar o mês', () {
      container
          .read(reportPeriodProvider.notifier)
          .selectType(ReportPeriodType.month);
      now = DateTime(2026, 12, 1, 8);
      container.read(todayProvider.notifier).refresh();

      final period = container.read(reportPeriodProvider);
      expect(period.type, ReportPeriodType.month);
      expect(period.start, DateTime(2026, 12));
    });

    test('um período anterior escolhido continua o mesmo', () {
      container.read(reportPeriodProvider.notifier).previous();
      now = DateTime(2026, 11, 16, 0, 1);
      container.read(todayProvider.notifier).refresh();

      final notifier = container.read(reportPeriodProvider.notifier);
      expect(container.read(reportPeriodProvider).start, DateTime(2026, 11, 2));
      expect(notifier.canGoNext, isTrue);
    });
  });
}
