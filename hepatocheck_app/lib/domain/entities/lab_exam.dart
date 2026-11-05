class LabExam {
  const LabExam({
    required this.id,
    required this.examDate,
    required this.age,
    required this.ast,
    required this.alt,
    required this.platelets,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime examDate;
  final int age;
  final double ast;
  final double alt;
  final double platelets;
  final DateTime createdAt;
  final DateTime updatedAt;

  LabExam copyWith({
    DateTime? examDate,
    int? age,
    double? ast,
    double? alt,
    double? platelets,
    DateTime? updatedAt,
  }) {
    return LabExam(
      id: id,
      examDate: examDate ?? this.examDate,
      age: age ?? this.age,
      ast: ast ?? this.ast,
      alt: alt ?? this.alt,
      platelets: platelets ?? this.platelets,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
