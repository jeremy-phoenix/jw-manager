import 'package:intl/intl.dart';

/// Helpers for the September–August service year.
///
/// A service year is named after the calendar year it ends in, so September
/// 2026 through August 2027 all belong to service year 2027. Service reports
/// store that service year, which means a stored year must never be printed
/// next to a month name without translating it back to the calendar year the
/// month actually falls in.

/// Service year that [month] of [calendarYear] belongs to.
int serviceYearOf(int calendarYear, int month) =>
    month >= 9 ? calendarYear + 1 : calendarYear;

/// Calendar year that [month] of [serviceYear] falls in.
int calendarYearOf(int serviceYear, int month) =>
    month >= 9 ? serviceYear - 1 : serviceYear;

/// Service year containing [date], or today when omitted.
int currentServiceYear([DateTime? date]) {
  final day = date ?? DateTime.now();
  return serviceYearOf(day.year, day.month);
}

/// Calendar label for a month of a service year, e.g. `August 2026`.
String formatServiceMonth(int serviceYear, int month) {
  final calendarYear = calendarYearOf(serviceYear, month);
  final monthName = DateFormat.MMMM().format(DateTime(calendarYear, month));
  return '$monthName $calendarYear';
}
