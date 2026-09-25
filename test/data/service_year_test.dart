import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/service_year.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';

void main() {
  group('service year mapping', () {
    test(
      'September starts the service year named after the following year',
      () {
        expect(serviceYearOf(2026, 9), 2027);
        expect(serviceYearOf(2026, 8), 2026);
        expect(calendarYearOf(2027, 9), 2026);
        expect(calendarYearOf(2026, 8), 2026);
      },
    );

    test('formats a month with the calendar year it falls in', () {
      expect(formatServiceMonth(2026, 8), 'August 2026');
      expect(formatServiceMonth(2027, 9), 'September 2026');
      expect(formatServiceMonth(2027, 1), 'January 2027');
    });
  });

  group('default service report period', () {
    test('opens on August 2026 on the first day of the 2027 service year', () {
      final period = defaultServiceReportPeriod(DateTime(2026, 9, 1));

      expect(period.month, 8);
      expect(period.serviceYear, 2026);
      expect(
        formatServiceMonth(period.serviceYear, period.month),
        'August 2026',
      );
    });

    test('shows the current month on the last day of that month', () {
      final period = defaultServiceReportPeriod(DateTime(2026, 8, 31));

      expect(period.month, 8);
      expect(period.serviceYear, 2026);
    });

    test('moves to the new service year after the 20th', () {
      final period = defaultServiceReportPeriod(DateTime(2026, 9, 25));

      expect(period.month, 9);
      expect(period.serviceYear, 2027);
    });

    test('rolls back into the previous calendar year in January', () {
      final period = defaultServiceReportPeriod(DateTime(2027, 1, 5));

      expect(period.month, 12);
      expect(period.serviceYear, 2027);
      expect(
        formatServiceMonth(period.serviceYear, period.month),
        'December 2026',
      );
    });
  });
}
