import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepatocheck_app/domain/entities/lab_exam.dart';
import 'package:hepatocheck_app/domain/usecases/calculate_fib4.dart';
import 'package:hepatocheck_app/domain/usecases/summarize_exam_history.dart';
import 'package:hepatocheck_app/presentation/widgets/exam_history.dart';

List<LabExam> _exams(int count) => [
  for (var i = 0; i < count; i++)
    LabExam(
      id: 'exame-$i',
      examDate: DateTime(2026, 10, 30 - i),
      age: 45,
      ast: 35.0 + i,
      alt: 36,
      platelets: 181,
      createdAt: DateTime(2026, 10, 30 - i),
      updatedAt: DateTime(2026, 10, 30 - i),
    ),
];

Future<void> _pump(
  WidgetTester tester,
  List<LabExam> exams, {
  ValueChanged<LabExam>? onEdit,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ExamHistory(
            exams: exams,
            calculate: const CalculateFib4(),
            summary: const SummarizeExamHistory()(
              exams,
              today: DateTime(2026, 11, 10),
            ),
            selectedId: null,
            onEdit: onEdit ?? (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra o estado vazio', (tester) async {
    await _pump(tester, const []);

    expect(find.text('Nenhum exame registrado ainda.'), findsOneWidget);
    expect(find.text('Evolução do FIB-4'), findsNothing);
  });

  testWidgets('mostra o resumo e 5 exames até tocar em Ver todos', (
    tester,
  ) async {
    await _pump(tester, _exams(7));

    expect(find.text('Evolução do FIB-4'), findsOneWidget);
    expect(find.text('Melhorou'), findsOneWidget);
    expect(find.text('30/10/2026'), findsWidgets);
    expect(find.text('25/10/2026'), findsNothing);

    await tester.ensureVisible(find.text('Ver todos (7)'));
    await tester.tap(find.text('Ver todos (7)'));
    await tester.pump();
    expect(find.text('25/10/2026'), findsWidgets);
    expect(find.text('Ver menos'), findsOneWidget);
  });

  testWidgets('expande o item com os valores e permite editar', (tester) async {
    LabExam? edited;
    await _pump(tester, _exams(1), onEdit: (exam) => edited = exam);

    expect(find.text('Evolução do FIB-4'), findsNothing);
    expect(find.text('Editar'), findsNothing);

    await tester.tap(find.text('30/10/2026'));
    await tester.pump();
    expect(find.text('35 U/L'), findsOneWidget);
    expect(find.text('181 ×10³/mm³'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    expect(edited?.id, 'exame-0');
  });
}
