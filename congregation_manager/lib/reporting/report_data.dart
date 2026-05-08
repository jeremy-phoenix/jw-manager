import 'package:congregation_manager/data/database.dart';

/// Data class holding enriched person info for reports.
/// Pre-fetches related data (phones, contacts, groups) so reports
/// don't need to do async lookups per row.
class PersonReportData {
  final Person person;
  final List<PhoneNumber> phoneNumbers;
  final List<EmergencyContact> emergencyContacts;
  final FieldServiceGroup? fieldServiceGroup;

  PersonReportData({
    required this.person,
    this.phoneNumbers = const [],
    this.emergencyContacts = const [],
    this.fieldServiceGroup,
  });

  String get fullName => '${person.lastName}, ${person.firstName}'.trim();

  String get formattedPhones {
    if (phoneNumbers.isEmpty) return '—';
    final sorted = [...phoneNumbers]..sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return 0;
      });
    return sorted.map((p) => p.number).join(', ');
  }

  EmergencyContact? get primaryEmergencyContact {
    if (emergencyContacts.isEmpty) return null;
    return emergencyContacts.firstWhere(
      (c) => c.isPrimary,
      orElse: () => emergencyContacts.first,
    );
  }

  String get groupName => fieldServiceGroup?.name ?? '—';
}

/// Service report with attached person + group data.
class ServiceReportData {
  final ServiceReport report;
  final Person person;
  final FieldServiceGroup? fieldServiceGroup;

  ServiceReportData({
    required this.report,
    required this.person,
    this.fieldServiceGroup,
  });

  String get fullName => '${person.lastName}, ${person.firstName}'.trim();
  String get groupName => fieldServiceGroup?.name ?? '—';
}

/// Helper to load all enriched data for reports.
class ReportDataLoader {
  final AppDatabase db;
  final int? congregationId;

  ReportDataLoader(this.db, {this.congregationId});

  /// Load all persons with their phone numbers, contacts, and groups.
  Future<List<PersonReportData>> loadAllPersons() async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final groups = await db.getAllFieldServiceGroups(congregationId: congregationId);
    final groupMap = {for (final g in groups) g.id: g};

    final result = <PersonReportData>[];
    for (final person in persons) {
      final phones = await db.getPhoneNumbers(person.id);
      final contacts = await db.getEmergencyContacts(person.id);
      result.add(PersonReportData(
        person: person,
        phoneNumbers: phones,
        emergencyContacts: contacts,
        fieldServiceGroup: person.fieldServiceGroupId != null
            ? groupMap[person.fieldServiceGroupId]
            : null,
      ));
    }

    // Sort by last name, first name
    result.sort((a, b) {
      final cmp = a.person.lastName.toLowerCase().compareTo(b.person.lastName.toLowerCase());
      if (cmp != 0) return cmp;
      return a.person.firstName.toLowerCase().compareTo(b.person.firstName.toLowerCase());
    });

    return result;
  }

  /// Load service reports for a period with person + group data.
  Future<List<ServiceReportData>> loadServiceReports({
    required int year,
    required int month,
    bool notSharedOnly = false,
  }) async {
    var reports = await db.getServiceReports(year: year, month: month, congregationId: congregationId);
    if (notSharedOnly) {
      reports = reports.where((r) => !r.sharedInMinistry).toList();
    }

    final persons = await db.getAllPersons(congregationId: congregationId);
    final personMap = {for (final p in persons) p.id: p};
    final groups = await db.getAllFieldServiceGroups(congregationId: congregationId);
    final groupMap = {for (final g in groups) g.id: g};

    final result = <ServiceReportData>[];
    for (final report in reports) {
      final person = personMap[report.personId];
      if (person == null) continue;
      result.add(ServiceReportData(
        report: report,
        person: person,
        fieldServiceGroup: person.fieldServiceGroupId != null
            ? groupMap[person.fieldServiceGroupId]
            : null,
      ));
    }

    result.sort((a, b) {
      final cmp = a.person.lastName.toLowerCase().compareTo(b.person.lastName.toLowerCase());
      if (cmp != 0) return cmp;
      return a.person.firstName.toLowerCase().compareTo(b.person.firstName.toLowerCase());
    });

    return result;
  }
}
