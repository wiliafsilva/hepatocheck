import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/reduction_goal.dart';
import 'package:hepatocheck_app/domain/entities/report_period.dart';
import 'package:hepatocheck_app/domain/usecases/build_health_summary.dart';
import 'package:hepatocheck_app/presentation/pdf/health_summary_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../support/test_data.dart';

pw.Font _font(String name) => pw.Font.ttf(
  ByteData.sublistView(File('assets/fonts/Inter-$name.ttf').readAsBytesSync()),
);

void main() {
  final pdf = HealthSummaryPdf(
    HealthSummaryFonts(regular: _font('Regular'), bold: _font('Bold')),
  );
  final now = DateTime(2026, 11, 11, 18);
  const build = BuildHealthSummary();

  bool isPdf(Uint8List bytes) =>
      String.fromCharCodes(bytes.take(5)) == '%PDF-' && bytes.length > 1000;

  test('gera o PDF completo com exames, consumo e metas', () async {
    final bytes = await pdf.build(
      build(
        exams: [
          testExam(id: 'a', examDate: DateTime(2026, 1, 1), ast: 60),
          testExam(id: 'b', examDate: DateTime(2026, 5, 1), ast: 45),
          testExam(id: 'c', examDate: DateTime(2026, 10, 1), age: 70),
        ],
        drinks: [
          testDrink(3, DateTime(2026, 11, 3)),
          testDrink(4, DateTime(2026, 11, 10)),
        ],
        goals: [
          ReductionGoal(
            id: 'g1',
            type: GoalType.maxDrinksPerWeek,
            target: 2,
            startDate: DateTime(2026, 11, 2),
            active: true,
            createdAt: DateTime(2026, 11, 2),
            updatedAt: DateTime(2026, 11, 2),
          ),
        ],
        period: ReportPeriod.containing(now, ReportPeriodType.month),
        now: now,
      ),
    );

    expect(isPdf(bytes), isTrue);
  });

  test('gera o PDF mesmo sem nenhum dado', () async {
    final bytes = await pdf.build(
      build(
        exams: const [],
        drinks: const [],
        goals: const [],
        period: ReportPeriod.containing(now, ReportPeriodType.week),
        now: now,
      ),
    );

    expect(isPdf(bytes), isTrue);
  });

  test('gera o PDF com um único exame, sem gráfico', () async {
    final bytes = await pdf.build(
      build(
        exams: [testExam()],
        drinks: const [],
        goals: const [],
        period: ReportPeriod.containing(now, ReportPeriodType.week),
        now: now,
      ),
    );

    expect(isPdf(bytes), isTrue);
  });

  test('o nome do arquivo é neutro e leva a data', () {
    expect(
      HealthSummaryPdf.fileName(DateTime(2026, 3, 7)),
      'resumo-saude-2026-03-07.pdf',
    );
  });

  test('gera o gráfico com muitos exames e datas repetidas', () async {
    final bytes = await pdf.build(
      build(
        exams: [
          for (var i = 0; i < 15; i++)
            testExam(
              id: 'e$i',
              examDate: DateTime(2024, 1 + i, i.isEven ? 1 : 2),
              ast: 30 + i.toDouble(),
            ),
          testExam(id: 'dup', examDate: DateTime(2025, 3, 2), ast: 50),
        ],
        drinks: const [],
        goals: const [],
        period: ReportPeriod.containing(now, ReportPeriodType.month),
        now: now,
      ),
    );

    expect(isPdf(bytes), isTrue);
  });

  test('gera o gráfico com dois exames no mesmo dia', () async {
    final bytes = await pdf.build(
      build(
        exams: [
          testExam(id: 'a', examDate: DateTime(2026, 9, 12)),
          testExam(id: 'b', examDate: DateTime(2026, 9, 12), ast: 50),
        ],
        drinks: [testDrink(2, DateTime(2026, 11, 2))],
        goals: const [],
        period: ReportPeriod.containing(now, ReportPeriodType.month),
        now: now,
      ),
    );

    expect(isPdf(bytes), isTrue);
  });

  test('a seta da escala do FIB-4 fica no lugar certo e não sai da barra', () {
    expect(HealthSummaryPdf.scaleFraction(0), 0);
    expect(HealthSummaryPdf.scaleFraction(2), 0.5);
    expect(HealthSummaryPdf.scaleFraction(9.4), 1);
  });

  test('gera a escala para risco alto e para mais de 65 anos', () async {
    for (final exam in [
      testExam(id: 'alto', ast: 120, platelets: 90),
      testExam(id: 'idoso', age: 70),
    ]) {
      final bytes = await pdf.build(
        build(
          exams: [exam],
          drinks: const [],
          goals: const [],
          period: ReportPeriod.containing(now, ReportPeriodType.month),
          now: now,
        ),
      );
      expect(isPdf(bytes), isTrue);
    }
  });
}
