import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../domain/usecases/build_health_summary.dart';
import '../pdf/health_summary_pdf.dart';
import 'drink_providers.dart';
import 'exam_providers.dart';
import 'goal_providers.dart';
import 'report_providers.dart';
import 'risk_providers.dart';

abstract interface class PdfOutput {
  Future<void> preview(Uint8List bytes, String fileName);

  Future<void> share(Uint8List bytes, String fileName);
}

class PrintingPdfOutput implements PdfOutput {
  const PrintingPdfOutput();

  @override
  Future<void> preview(Uint8List bytes, String fileName) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);

  @override
  Future<void> share(Uint8List bytes, String fileName) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);
}

final pdfOutputProvider = Provider<PdfOutput>(
  (ref) => const PrintingPdfOutput(),
);

final buildHealthSummaryProvider = Provider(
  (ref) => BuildHealthSummary(
    assessRisk: ref.watch(assessCurrentRiskProvider),
    buildEvolution: ref.watch(buildExamEvolutionProvider),
    summarizeHistory: ref.watch(summarizeExamHistoryProvider),
    buildReport: ref.watch(buildConsumptionReportProvider),
  ),
);

final currentHealthSummaryProvider = Provider<HealthSummary Function()>(
  (ref) =>
      () => ref.read(buildHealthSummaryProvider)(
        exams: ref.read(examsProvider),
        drinks: ref.read(drinksProvider),
        goals: ref.read(goalsProvider),
        period: ref.read(reportPeriodProvider),
        now: ref.read(clockProvider)(),
      ),
);

final healthSummaryPdfProvider =
    Provider<Future<Uint8List> Function(HealthSummary)>(
      (ref) =>
          (summary) async =>
              HealthSummaryPdf(await HealthSummaryFonts.fromAssets())
                  .build(summary),
    );
