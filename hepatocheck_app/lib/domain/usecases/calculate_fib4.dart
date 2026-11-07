import 'dart:math' as math;

import '../entities/fib4_result.dart';
import '../entities/lab_exam.dart';
import '../entities/risk_level.dart';

class CalculateFib4 {
  const CalculateFib4();

  static const lowCutoff = 1.30;
  static const lowCutoffElderly = 2.0;
  static const highCutoff = 2.67;
  static const elderlyAge = 65;
  static const minValidatedAge = 35;
  static const maxValidatedAge = 65;

  Fib4Result call(LabExam exam) {
    final value = score(
      age: exam.age,
      ast: exam.ast,
      alt: exam.alt,
      platelets: exam.platelets,
    );
    return Fib4Result(
      examId: exam.id,
      score: value,
      riskLevel: riskFor(score: value, age: exam.age),
      ageOutsideValidatedRange: isAgeOutsideValidatedRange(exam.age),
    );
  }

  static double score({
    required int age,
    required double ast,
    required double alt,
    required double platelets,
  }) {
    if (age <= 0 || ast <= 0 || alt <= 0 || platelets <= 0) {
      throw ArgumentError('Os valores do FIB-4 precisam ser maiores que zero.');
    }
    return (age * ast) / (platelets * math.sqrt(alt));
  }

  static RiskLevel riskFor({required double score, required int age}) {
    final low = age >= elderlyAge ? lowCutoffElderly : lowCutoff;
    if (score < low) return RiskLevel.low;
    if (score <= highCutoff) return RiskLevel.intermediate;
    return RiskLevel.high;
  }

  static bool isAgeOutsideValidatedRange(int age) =>
      age < minValidatedAge || age > maxValidatedAge;
}
