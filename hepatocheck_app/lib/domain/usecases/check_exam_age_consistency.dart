import '../entities/lab_exam.dart';

class ExamAgeConflict {
  const ExamAgeConflict({
    required this.exam,
    required this.minAge,
    required this.maxAge,
  });

  final LabExam exam;
  final int minAge;
  final int maxAge;
}

class CheckExamAgeConsistency {
  const CheckExamAgeConsistency();

  ExamAgeConflict? call({
    required DateTime examDate,
    required int age,
    required List<LabExam> exams,
    String? ignoreId,
  }) {
    final date = _dateOnly(examDate);
    final others = exams.where((exam) => exam.id != ignoreId).toList()
      ..sort(
        (a, b) =>
            _distance(a.examDate, date).compareTo(_distance(b.examDate, date)),
      );

    for (final other in others) {
      final (minAge, maxAge) = expectedAgeRange(
        knownDate: other.examDate,
        knownAge: other.age,
        targetDate: date,
      );
      if (age < minAge || age > maxAge) {
        return ExamAgeConflict(exam: other, minAge: minAge, maxAge: maxAge);
      }
    }
    return null;
  }

  static (int, int) expectedAgeRange({
    required DateTime knownDate,
    required int knownAge,
    required DateTime targetDate,
  }) {
    final known = _dateOnly(knownDate);
    final target = _dateOnly(targetDate);
    final forward = !target.isBefore(known);
    final start = forward ? known : target;
    final end = forward ? target : known;

    var years = end.year - start.year;
    final beforeAnniversary =
        end.month < start.month ||
        (end.month == start.month && end.day < start.day);
    if (beforeAnniversary) years--;
    final partial = end.month != start.month || end.day != start.day ? 1 : 0;

    return forward
        ? (knownAge + years, knownAge + years + partial)
        : (knownAge - years - partial, knownAge - years);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _distance(DateTime a, DateTime b) =>
      _dateOnly(a).difference(b).inDays.abs();
}
