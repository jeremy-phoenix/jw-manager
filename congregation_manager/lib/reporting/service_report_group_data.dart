import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/pdf_styles.dart';

/// Label used for publishers without a field service group.
const String kUnassignedGroupName = 'Unassigned';

/// A single publisher's service report line for a period.
class PublisherReportLine {
  final Person person;
  final ServiceReport? report;

  const PublisherReportLine({required this.person, this.report});

  String get name => formatPersonName(person.firstName, person.lastName);

  /// A report counts as "submitted" when the publisher indicated activity,
  /// matching the app's month-statistics definition.
  bool get submitted {
    final r = report;
    if (r == null) return false;
    return r.sharedInMinistry || r.hours > 0 || r.bibleStudies > 0;
  }

  bool get sharedInMinistry => report?.sharedInMinistry ?? false;
  bool get isAuxiliaryPioneer => report?.isAuxiliaryPioneer ?? false;
  int get bibleStudies => report?.bibleStudies ?? 0;
  double get hours => report?.hours ?? 0;
}

/// All publishers belonging to one field service group, with totals.
class ServiceGroupBucket {
  final String name;
  final List<PublisherReportLine> lines;

  const ServiceGroupBucket({required this.name, required this.lines});

  int get publisherCount => lines.length;
  int get reportingCount => lines.where((l) => l.submitted).length;
  int get totalBibleStudies => lines.fold(0, (sum, l) => sum + l.bibleStudies);
  double get totalHours => lines.fold(0.0, (sum, l) => sum + l.hours);

  double get reportingPercent =>
      publisherCount == 0 ? 0 : reportingCount * 100 / publisherCount;
}

/// Resolve the field service group name for a person.
String groupNameForPerson(
  Person person,
  Map<int, FieldServiceGroup> groupsById,
) {
  final groupId = person.fieldServiceGroupId;
  if (groupId == null) return kUnassignedGroupName;
  final name = groupsById[groupId]?.name.trim();
  if (name == null || name.isEmpty) return kUnassignedGroupName;
  return name;
}

/// Build per-group buckets of active publishers and their period reports.
///
/// Groups are sorted alphabetically with [kUnassignedGroupName] last, and the
/// publishers within each group are sorted by "Last, First".
List<ServiceGroupBucket> buildServiceGroupBuckets({
  required List<Person> persons,
  required List<ServiceReport> reports,
  required Map<int, FieldServiceGroup> groupsById,
}) {
  final reportByPerson = <int, ServiceReport>{
    for (final r in reports) r.personId: r,
  };

  final grouped = <String, List<PublisherReportLine>>{};
  for (final person in persons.where((p) => p.isActive)) {
    final groupName = groupNameForPerson(person, groupsById);
    grouped
        .putIfAbsent(groupName, () => [])
        .add(
          PublisherReportLine(
            person: person,
            report: reportByPerson[person.id],
          ),
        );
  }

  final sortedKeys = grouped.keys.toList()..sort(_compareGroupNames);

  return [
    for (final key in sortedKeys)
      ServiceGroupBucket(
        name: key,
        lines: grouped[key]!..sort((a, b) => a.name.compareTo(b.name)),
      ),
  ];
}

/// Alphabetical group comparison that always sorts "Unassigned" last.
int _compareGroupNames(String a, String b) {
  if (a == kUnassignedGroupName) return 1;
  if (b == kUnassignedGroupName) return -1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Format hours for display: integers without a decimal, otherwise one place.
String formatHours(double hours) {
  if (hours <= 0) return '—';
  return hours == hours.roundToDouble()
      ? hours.toInt().toString()
      : hours.toStringAsFixed(1);
}
