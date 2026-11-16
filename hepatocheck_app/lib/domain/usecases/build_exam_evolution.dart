import '../entities/fib4_result.dart';
import '../entities/lab_exam.dart';
import 'calculate_fib4.dart';

class ExamPoint {
  const ExamPoint({required this.exam, required this.fib4});

  final LabExam exam;
  final Fib4Result fib4;

  DateTime get date => exam.examDate;
}

class BuildExamEvolution {
  const BuildExamEvolution([this._calculate = const CalculateFib4()]);

  final CalculateFib4 _calculate;

  List<ExamPoint> call(List<LabExam> exams) {
    final sorted = [...exams]
      ..sort((a, b) {
        final byDate = a.examDate.compareTo(b.examDate);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
    return [
      for (final exam in sorted) ExamPoint(exam: exam, fib4: _calculate(exam)),
    ];
  }
}
