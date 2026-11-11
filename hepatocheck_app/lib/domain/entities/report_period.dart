enum ReportPeriodType { week, month }

class ReportPeriod {
  const ReportPeriod._(this.type, this.start, this.end);

  factory ReportPeriod.containing(DateTime date, ReportPeriodType type) {
    final day = DateTime(date.year, date.month, date.day);
    return switch (type) {
      ReportPeriodType.week => _week(
        DateTime(
          day.year,
          day.month,
          day.day - (day.weekday - DateTime.monday),
        ),
      ),
      ReportPeriodType.month => _month(day.year, day.month),
    };
  }

  static ReportPeriod _week(DateTime monday) => ReportPeriod._(
    ReportPeriodType.week,
    monday,
    DateTime(monday.year, monday.month, monday.day + 7),
  );

  static ReportPeriod _month(int year, int month) => ReportPeriod._(
    ReportPeriodType.month,
    DateTime(year, month),
    DateTime(year, month + 1),
  );

  final ReportPeriodType type;
  final DateTime start;
  final DateTime end;

  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  ReportPeriod get previous => switch (type) {
    ReportPeriodType.week => _week(
      DateTime(start.year, start.month, start.day - 7),
    ),
    ReportPeriodType.month => _month(start.year, start.month - 1),
  };

  ReportPeriod get next => switch (type) {
    ReportPeriodType.week => _week(end),
    ReportPeriodType.month => _month(end.year, end.month),
  };

  int get dayCount => _daysBetween(start, end);

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  bool isCurrent(DateTime today) => contains(today);

  bool isFuture(DateTime today) =>
      start.isAfter(DateTime(today.year, today.month, today.day));

  int elapsedDays(DateTime today) {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    if (!tomorrow.isAfter(start)) return 0;
    if (!tomorrow.isBefore(end)) return dayCount;
    return _daysBetween(start, tomorrow);
  }

  List<DateTime> days() => [
    for (var i = 0; i < dayCount; i++)
      DateTime(start.year, start.month, start.day + i),
  ];

  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.type == type && other.start == start;

  @override
  int get hashCode => Object.hash(type, start);
}
