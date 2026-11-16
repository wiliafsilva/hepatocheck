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
}
