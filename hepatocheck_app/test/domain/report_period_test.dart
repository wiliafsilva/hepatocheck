import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';

void main() {
  group('Semana de segunda a domingo', () {
    test('segunda e domingo ficam na mesma semana', () {
      final monday = ReportPeriod.containing(
        DateTime(2026, 11, 9, 8),
        ReportPeriodType.week,
      );
      final sunday = ReportPeriod.containing(
        DateTime(2026, 11, 15, 23, 59),
        ReportPeriodType.week,
      );

      expect(monday, sunday);
      expect(monday.start, DateTime(2026, 11, 9));
      expect(monday.end, DateTime(2026, 11, 16));
      expect(monday.lastDay, DateTime(2026, 11, 15));
      expect(monday.dayCount, 7);
    });

    test('a semana pode atravessar a virada do ano', () {
      final week = ReportPeriod.containing(
        DateTime(2027, 1, 1),
        ReportPeriodType.week,
      );

      expect(week.start, DateTime(2026, 12, 28));
      expect(week.end, DateTime(2027, 1, 4));
    });

    test('anterior e próxima andam 7 dias', () {
      final week = ReportPeriod.containing(
        DateTime(2026, 11, 10),
        ReportPeriodType.week,
      );

      expect(week.previous.start, DateTime(2026, 11, 2));
      expect(week.next.start, DateTime(2026, 11, 16));
      expect(week.previous.next, week);
    });
  });

  group('Mês civil', () {
    test('vai do dia 1 ao último dia do mês', () {
      final month = ReportPeriod.containing(
        DateTime(2026, 11, 10),
        ReportPeriodType.month,
      );

      expect(month.start, DateTime(2026, 11));
      expect(month.end, DateTime(2026, 12));
      expect(month.dayCount, 30);
    });

    test('fevereiro bissexto tem 29 dias', () {
      expect(
        ReportPeriod.containing(
          DateTime(2028, 2, 10),
          ReportPeriodType.month,
        ).dayCount,
        29,
      );
      expect(
        ReportPeriod.containing(
          DateTime(2027, 2, 10),
          ReportPeriodType.month,
        ).dayCount,
        28,
      );
    });

    test('anterior e próximo atravessam a virada do ano', () {
      final january = ReportPeriod.containing(
        DateTime(2027, 1, 20),
        ReportPeriodType.month,
      );

      expect(january.previous.start, DateTime(2026, 12));
      expect(january.previous.next, january);
      expect(january.next.start, DateTime(2027, 2));
    });
  });

  group('Dias decorridos e limites', () {
    final week = ReportPeriod.containing(
      DateTime(2026, 11, 10),
      ReportPeriodType.week,
    );

    test('o período atual conta até hoje, incluindo hoje', () {
      expect(week.elapsedDays(DateTime(2026, 11, 9, 0, 1)), 1);
      expect(week.elapsedDays(DateTime(2026, 11, 11, 22)), 3);
      expect(week.elapsedDays(DateTime(2026, 11, 15)), 7);
    });

    test('período passado conta todos os dias e futuro conta zero', () {
      expect(week.elapsedDays(DateTime(2026, 12, 1)), 7);
      expect(week.elapsedDays(DateTime(2026, 11, 8)), 0);
      expect(week.isFuture(DateTime(2026, 11, 8)), isTrue);
      expect(week.isCurrent(DateTime(2026, 11, 12)), isTrue);
    });

    test('inclui a segunda 00:00 e exclui a segunda seguinte', () {
      expect(week.contains(DateTime(2026, 11, 9)), isTrue);
      expect(week.contains(DateTime(2026, 11, 15, 23, 59, 59)), isTrue);
      expect(week.contains(DateTime(2026, 11, 16)), isFalse);
      expect(week.contains(DateTime(2026, 11, 8, 23, 59)), isFalse);
    });

    test('lista os dias do período', () {
      final days = week.days();

      expect(days, hasLength(7));
      expect(days.first, DateTime(2026, 11, 9));
      expect(days.last, DateTime(2026, 11, 15));
    });
  });
}
