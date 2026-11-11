/// Faixa de risco hepático (semáforo): verde, amarelo ou vermelho.
enum RiskLevel {
  low('Risco baixo'),
  intermediate('Risco intermediário'),
  high('Risco alto');

  const RiskLevel(this.label);

  final String label;

  /// Classifica o FIB-4: abaixo de 1,30 é baixo (abaixo de 2,0 a partir de
  /// 65 anos), de 1,30 a 2,67 é intermediário e acima de 2,67 é alto.
  static RiskLevel fromFib4(double fib4, {required int age}) {
    final lowLimit = age >= 65 ? 2.0 : 1.30;
    if (fib4 < lowLimit) return RiskLevel.low;
    if (fib4 <= 2.67) return RiskLevel.intermediate;
    return RiskLevel.high;
  }
}
