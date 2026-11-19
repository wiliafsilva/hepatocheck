import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/drink_entry.dart';
import 'package:hepatocheck_app/domain/entities/drink_type.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/domain/usecases/build_consumption_report.dart';

var _ids = 0;

DrinkEntry _drink(
  DateTime consumedAt, {
  DrinkType type = DrinkType.beer,
  double volumeMl = 350,
  double alcoholPercent = 5,
  int quantity = 1,
}) {
  return DrinkEntry(
    id: 'drink-${_ids++}',
    type: type,
    volumeMl: volumeMl,
    alcoholPercent: alcoholPercent,
    quantity: quantity,
    consumedAt: consumedAt,
    createdAt: consumedAt,
    updatedAt: consumedAt,
  );
}

const _beerCan = 350 * 0.05 * 0.789 / 14;

void main() {
  const build = BuildConsumptionReport();
  final today = DateTime(2026, 11, 11, 18);
  final week = ReportPeriod.containing(today, ReportPeriodType.week);

  test('período sem registros', () {
    final report = build(const [], week, today: today);

    expect(report.hasData, isFalse);
    expect(report.totalStandardDrinks, 0);
    expect(report.averagePerDay, 0);
    expect(report.elapsedDays, 3);
    expect(report.alcoholFreeDays, 3);
    expect(report.byType, isEmpty);
    expect(report.changePercent, isNull);
  });

  test('soma os drinques padrão e separa por tipo', () {
    final report = build(
      [
        _drink(DateTime(2026, 11, 9, 20), quantity: 2),
        _drink(
          DateTime(2026, 11, 10, 21),
          type: DrinkType.wine,
          volumeMl: 150,
          alcoholPercent: 12,
        ),
      ],
      week,
      today: today,
    );

    const wineGlass = 150 * 0.12 * 0.789 / 14;
    expect(report.entryCount, 2);
    expect(report.byType[DrinkType.beer], closeTo(2 * _beerCan, 0.0001));
    expect(report.byType[DrinkType.wine], closeTo(wineGlass, 0.0001));
    expect(
      report.totalStandardDrinks,
      closeTo(2 * _beerCan + wineGlass, 0.0001),
    );
  });

  test(
    'a média e os dias sem álcool ignoram os dias que ainda não chegaram',
    () {
      final report = build(
        [_drink(DateTime(2026, 11, 9, 20), quantity: 3)],
        week,
        today: today,
      );

      expect(report.elapsedDays, 3);
      expect(report.averagePerDay, closeTo(_beerCan, 0.0001));
      expect(report.drinkingDays, 1);
      expect(report.alcoholFreeDays, 2);
    },
  );

  test('vários registros no mesmo dia contam um dia de consumo', () {
    final report = build(
      [
        _drink(DateTime(2026, 11, 10, 12)),
        _drink(DateTime(2026, 11, 10, 22)),
        _drink(DateTime(2026, 11, 11, 0, 30)),
      ],
      week,
      today: today,
    );

    expect(report.drinkingDays, 2);
    expect(report.alcoholFreeDays, 1);
  });

  test('período passado conta todos os dias', () {
    final report = build(
      [_drink(DateTime(2026, 11, 3, 20))],
      week.previous,
      today: today,
    );

    expect(report.elapsedDays, 7);
    expect(report.alcoholFreeDays, 6);
    expect(report.averagePerDay, closeTo(_beerCan / 7, 0.0001));
  });

  test('inclui a segunda 00:00 e deixa a segunda seguinte de fora', () {
    final report = build(
      [
        _drink(DateTime(2026, 11, 9)),
        _drink(DateTime(2026, 11, 16)),
        _drink(DateTime(2026, 11, 8, 23, 59)),
      ],
      week,
      today: DateTime(2026, 11, 20),
    );

    expect(report.entryCount, 1);
    expect(report.previousTotal, closeTo(_beerCan, 0.0001));
  });

  group('Comparação com o período anterior', () {
    test('aumento', () {
      final report = build(
        [
          _drink(DateTime(2026, 11, 3)),
          _drink(DateTime(2026, 11, 10), quantity: 3),
        ],
        week,
        today: today,
      );

      expect(report.previousTotal, closeTo(_beerCan, 0.0001));
      expect(report.difference, closeTo(2 * _beerCan, 0.0001));
      expect(report.changePercent, closeTo(200, 0.001));
    });

    test('redução', () {
      final report = build(
        [
          _drink(DateTime(2026, 11, 4), quantity: 4),
          _drink(DateTime(2026, 11, 10)),
        ],
        week,
        today: today,
      );

      expect(report.difference, closeTo(-3 * _beerCan, 0.0001));
      expect(report.changePercent, closeTo(-75, 0.001));
    });

    test('sem consumo antes não tem porcentagem', () {
      final report = build(
        [_drink(DateTime(2026, 11, 10))],
        week,
        today: today,
      );

      expect(report.previousTotal, 0);
      expect(report.changePercent, isNull);
    });

    test('o mês em andamento compara com os mesmos dias do mês anterior', () {
      final month = ReportPeriod.containing(today, ReportPeriodType.month);
      final report = build(
        [
          _drink(DateTime(2026, 10, 1)),
          _drink(DateTime(2026, 10, 11, 17)),
          _drink(DateTime(2026, 10, 11, 19)),
          _drink(DateTime(2026, 10, 12)),
          _drink(DateTime(2026, 10, 31, 23)),
          _drink(DateTime(2026, 11, 1)),
        ],
        month,
        today: today,
      );

      expect(report.inProgress, isTrue);
      expect(report.comparedDays, 11);
      expect(report.previousTotal, closeTo(2 * _beerCan, 0.0001));
      expect(report.totalStandardDrinks, closeTo(_beerCan, 0.0001));
      expect(report.elapsedDays, 11);
    });

    test('na terça compara com a semana anterior até o mesmo horário', () {
      final tuesday = DateTime(2026, 11, 10, 9);
      final report = build(
        [
          _drink(DateTime(2026, 11, 2, 20)),
          _drink(DateTime(2026, 11, 3, 23, 59)),
          _drink(DateTime(2026, 11, 4)),
          _drink(DateTime(2026, 11, 7), quantity: 5),
          _drink(DateTime(2026, 11, 9), quantity: 2),
        ],
        ReportPeriod.containing(tuesday, ReportPeriodType.week),
        today: tuesday,
      );

      expect(report.inProgress, isTrue);
      expect(report.comparedDays, 2);
      expect(report.previousTotal, closeTo(_beerCan, 0.0001));
      expect(report.difference, closeTo(_beerCan, 0.0001));
    });

    test('no dia 31 o mês anterior de 30 dias entra inteiro', () {
      final lastDay = DateTime(2026, 12, 31, 10);
      final report = build(
        [
          _drink(DateTime(2026, 11, 1)),
          _drink(DateTime(2026, 11, 30, 22)),
          _drink(DateTime(2026, 12, 1)),
        ],
        ReportPeriod.containing(lastDay, ReportPeriodType.month),
        today: lastDay,
      );

      expect(report.comparedDays, 30);
      expect(report.previousTotal, closeTo(2 * _beerCan, 0.0001));
    });

    test('no dia 30 de março compara os 28 primeiros dias dos dois meses', () {
      final march30 = DateTime(2027, 3, 30, 12);
      final report = build(
        [
          _drink(DateTime(2027, 2, 10)),
          _drink(DateTime(2027, 3, 5)),
          _drink(DateTime(2027, 3, 29, 1)),
          _drink(DateTime(2027, 3, 30, 1)),
        ],
        ReportPeriod.containing(march30, ReportPeriodType.month),
        today: march30,
      );

      expect(report.comparedDays, 28);
      expect(report.totalStandardDrinks, closeTo(3 * _beerCan, 0.0001));
      expect(report.comparedTotal, closeTo(_beerCan, 0.0001));
      expect(report.previousTotal, closeTo(_beerCan, 0.0001));
      expect(report.difference, closeTo(0, 0.0001));
      expect(report.comparesFewerDays, isTrue);
    });

    test('mês encerrado mais longo compara só os dias do mês anterior', () {
      final report = build(
        [
          _drink(DateTime(2027, 2, 28, 20)),
          _drink(DateTime(2027, 3, 1)),
          _drink(DateTime(2027, 3, 31, 20)),
        ],
        ReportPeriod.containing(DateTime(2027, 3, 1), ReportPeriodType.month),
        today: DateTime(2027, 4, 10),
      );

      expect(report.inProgress, isFalse);
      expect(report.comparedDays, 28);
      expect(report.comparedTotal, closeTo(_beerCan, 0.0001));
      expect(report.previousTotal, closeTo(_beerCan, 0.0001));
      expect(report.hasComparisonNote, isTrue);
    });

    test('mês encerrado mais curto compara com o começo do mês anterior', () {
      final report = build(
        [
          _drink(DateTime(2027, 1, 28, 20)),
          _drink(DateTime(2027, 1, 29)),
          _drink(DateTime(2027, 2, 3)),
        ],
        ReportPeriod.containing(DateTime(2027, 2, 1), ReportPeriodType.month),
        today: DateTime(2027, 4, 10),
      );

      expect(report.comparedDays, 28);
      expect(report.previousTotal, closeTo(_beerCan, 0.0001));
      expect(report.comparesFewerDays, isFalse);
      expect(report.comparesPartOfPrevious, isTrue);
    });

    test('período encerrado compara com o período anterior inteiro', () {
      final report = build(
        [
          _drink(DateTime(2026, 10, 26)),
          _drink(DateTime(2026, 11, 1, 23)),
          _drink(DateTime(2026, 11, 2)),
        ],
        week.previous,
        today: today,
      );

      expect(report.inProgress, isFalse);
      expect(report.comparedDays, 7);
      expect(report.previousTotal, closeTo(2 * _beerCan, 0.0001));
    });
  });

  group('Consumo por dia', () {
    test('tem um item por dia do período com a soma do dia', () {
      final report = build(
        [
          _drink(DateTime(2026, 11, 10, 12)),
          _drink(DateTime(2026, 11, 10, 22), quantity: 2),
          _drink(DateTime(2026, 11, 11, 10)),
        ],
        week,
        today: today,
      );

      expect(report.daily, hasLength(7));
      expect(report.daily.first.day, DateTime(2026, 11, 9));
      expect(report.daily.first.standardDrinks, 0);
      expect(report.daily[1].standardDrinks, closeTo(3 * _beerCan, 0.0001));
      expect(report.daily[2].standardDrinks, closeTo(_beerCan, 0.0001));
    });

    test('o mês tem um item por dia do mês', () {
      final report = build(
        const [],
        ReportPeriod.containing(DateTime(2027, 2, 10), ReportPeriodType.month),
        today: today,
      );

      expect(report.daily, hasLength(28));
    });
  });

  test('drinques com data futura ficam fora do total', () {
    final report = build(
      [_drink(DateTime(2026, 11, 10, 20)), _drink(DateTime(2026, 11, 13, 20))],
      week,
      today: today,
    );

    expect(report.entryCount, 1);
    expect(report.totalStandardDrinks, closeTo(_beerCan, 0.0001));
    expect(report.daily.last.standardDrinks, 0);
  });
}
