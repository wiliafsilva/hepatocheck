import 'risk_level.dart';

class Fib4Result {
  const Fib4Result({
    required this.examId,
    required this.score,
    required this.riskLevel,
    required this.ageOutsideValidatedRange,
  });

  final String examId;
  final double score;
  final RiskLevel riskLevel;
  final bool ageOutsideValidatedRange;
}
