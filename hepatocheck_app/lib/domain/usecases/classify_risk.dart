import '../entities/risk_level.dart';

class ClassifyRisk {
  const ClassifyRisk();

  RiskLevel call({
    required RiskLevel fib4Risk,
    double? weeklyStandardDrinks,
    int? weeklyDrinkLimit,
  }) {
    if (weeklyStandardDrinks == null || weeklyDrinkLimit == null) {
      return fib4Risk;
    }
    if (weeklyStandardDrinks <= weeklyDrinkLimit) return fib4Risk;
    return switch (fib4Risk) {
      RiskLevel.low => RiskLevel.intermediate,
      RiskLevel.intermediate => RiskLevel.high,
      RiskLevel.high => RiskLevel.high,
    };
  }
}
