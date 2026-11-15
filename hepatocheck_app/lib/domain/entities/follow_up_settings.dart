import 'lab_exam.dart';
import 'risk_level.dart';
import '../usecases/calculate_fib4.dart';

class FollowUpSettings {
  const FollowUpSettings({
    this.education = false,
    this.registration = false,
    this.exam = false,
    this.hour = 19,
    this.minute = 0,
    this.examDate,
    this.lowRiskMonths,
    this.intermediateRiskMonths,
    this.highRiskMonths,
  });
  final bool education, registration, exam;
  final int hour, minute;
  final DateTime? examDate;
  final int? lowRiskMonths, intermediateRiskMonths, highRiskMonths;

  Map<String, Object?> toJson() => {
    'education': education,
    'registration': registration,
    'exam': exam,
    'hour': hour,
    'minute': minute,
    'examDate': examDate?.toIso8601String(),
    'lowRiskMonths': lowRiskMonths,
    'intermediateRiskMonths': intermediateRiskMonths,
    'highRiskMonths': highRiskMonths,
  };

  factory FollowUpSettings.fromJson(Map<String, dynamic> data) =>
      FollowUpSettings(
        education: data['education'] as bool? ?? false,
        registration: data['registration'] as bool? ?? false,
        exam: data['exam'] as bool? ?? false,
        hour: data['hour'] as int? ?? 19,
        minute: data['minute'] as int? ?? 0,
        examDate: DateTime.tryParse(data['examDate'] as String? ?? ''),
        lowRiskMonths: data['lowRiskMonths'] as int?,
        intermediateRiskMonths: data['intermediateRiskMonths'] as int?,
        highRiskMonths: data['highRiskMonths'] as int?,
      );
}

LabExam? latestExam(List<LabExam> exams) {
  if (exams.isEmpty) return null;
  return exams.reduce((a, b) => a.examDate.isAfter(b.examDate) ? a : b);
}

/// Intervalos informados pelo usuário segundo a orientação profissional.
DateTime? nextExamDate(FollowUpSettings settings, List<LabExam> exams) {
  final latest = latestExam(exams);
  final manual = settings.examDate;
  if (manual != null && (latest == null || manual.isAfter(latest.examDate))) {
    return manual;
  }
  if (latest == null) return null;
  final risk = const CalculateFib4()(latest).riskLevel;
  final months = switch (risk) {
    RiskLevel.low => settings.lowRiskMonths,
    RiskLevel.intermediate => settings.intermediateRiskMonths,
    RiskLevel.high => settings.highRiskMonths,
  };
  if (months == null || months < 1) return null;
  final month = DateTime(latest.examDate.year, latest.examDate.month + months);
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  final day = latest.examDate.day > lastDay ? lastDay : latest.examDate.day;
  return DateTime(month.year, month.month, day, settings.hour, settings.minute);
}
