import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/service_year.dart';
import 'package:congregation_manager/reporting/publisher_directory_report.dart';
import 'package:congregation_manager/reporting/publisher_list_report.dart';
import 'package:congregation_manager/reporting/publisher_contact_list_report.dart';
import 'package:congregation_manager/reporting/emergency_contact_list_report.dart';
import 'package:congregation_manager/reporting/not_shared_in_ministry_report.dart';
import 'package:congregation_manager/reporting/not_shared_by_group_report.dart';
import 'package:congregation_manager/reporting/congregation_summary_report.dart';
import 'package:congregation_manager/reporting/publisher_contact_list_excel_report.dart';
import 'package:congregation_manager/reporting/service_report_by_group_report.dart';
import 'package:congregation_manager/reporting/field_service_group_summary_report.dart';
import 'package:congregation_manager/reporting/pioneer_hours_report.dart';
import 'package:congregation_manager/reporting/missing_reports_by_group_report.dart';
import 'package:congregation_manager/reporting/ministry_totals_report.dart';
import 'package:congregation_manager/services/export_progress.dart';
import 'package:congregation_manager/services/publisher_record_writer.dart';

/// Central service for generating and previewing/printing PDF reports.
class ReportService {
  final AppDatabase db;
  final int? congregationId;

  ReportService(this.db, {this.congregationId});

  // ── Shared data loaders ──────────────────────────

  Future<Map<int, List<PhoneNumber>>> _loadAllPhones() async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final result = <int, List<PhoneNumber>>{};
    for (final p in persons) {
      result[p.id] = await db.getPhoneNumbers(p.id);
    }
    return result;
  }

  Future<Map<int, List<EmergencyContact>>> _loadAllEmergencyContacts() async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final result = <int, List<EmergencyContact>>{};
    for (final p in persons) {
      result[p.id] = await db.getEmergencyContacts(p.id);
    }
    return result;
  }

  Future<Map<int, FieldServiceGroup>> _loadGroupsById() async {
    final groups = await db.getAllFieldServiceGroups(
      congregationId: congregationId,
    );
    return {for (final g in groups) g.id: g};
  }

  Future<Map<int, Person>> _loadPersonsById() async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    return {for (final p in persons) p.id: p};
  }

  Future<Congregation?> _loadCongregation() async =>
      congregationId == null ? null : await db.getCongregation(congregationId!);

  // ── Report generators ────────────────────────────

  /// Publisher Directory — landscape, with phones and groups.
  Future<void> previewPublisherDirectory(BuildContext context) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();

    final doc = generatePublisherDirectoryReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Publisher Directory');
  }

  /// Publisher List — portrait, names + addresses + groups.
  Future<void> previewPublisherList(BuildContext context) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final groups = await _loadGroupsById();

    final doc = generatePublisherListReport(
      persons: persons,
      groupsById: groups,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Publisher List');
  }

  /// Publisher Contact List — landscape, names + addresses + phones + groups.
  Future<void> previewPublisherContactList(
    BuildContext context, {
    bool startInactiveOnNewPage = false,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();

    final doc = generatePublisherContactListReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
      congregation: await _loadCongregation(),
      startInactiveOnNewPage: startInactiveOnNewPage,
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Publisher Contact List');
  }

  /// Emergency Contact List — landscape.
  Future<void> previewEmergencyContactList(BuildContext context) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final ecs = await _loadAllEmergencyContacts();

    final doc = generateEmergencyContactListReport(
      persons: persons,
      phonesByPerson: phones,
      emergencyContactsByPerson: ecs,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Emergency Contact List');
  }

  /// Not Shared in Ministry — flat list.
  Future<void> previewNotSharedInMinistry(
    BuildContext context, {
    required int year,
    required int month,
  }) async {
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final notShared = reports.where((r) => !r.sharedInMinistry).toList();
    final personsById = await _loadPersonsById();
    final groups = await _loadGroupsById();

    final doc = generateNotSharedInMinistryReport(
      reports: notShared,
      personsById: personsById,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Not Shared in Ministry');
  }

  /// Not Shared in Ministry by Group.
  Future<void> previewNotSharedByGroup(
    BuildContext context, {
    required int year,
    required int month,
  }) async {
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final notShared = reports.where((r) => !r.sharedInMinistry).toList();
    final personsById = await _loadPersonsById();
    final groups = await _loadGroupsById();

    final doc = generateNotSharedInMinistryByGroupReport(
      reports: notShared,
      personsById: personsById,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Not Shared in Ministry by Group');
  }

  // ── Period reports by field service group ─────────

  /// Field Service Reports by Group — full roster with figures and totals.
  Future<void> previewServiceReportsByGroup(
    BuildContext context, {
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    final doc = generateServiceReportByGroupReport(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Field Service Reports by Group');
  }

  Future<Uint8List> buildServiceReportsByGroupExcelBytes({
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    return buildServiceReportByGroupExcel(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );
  }

  /// Field Service Group Totals — one row per group with monthly totals.
  Future<void> previewFieldServiceGroupSummary(
    BuildContext context, {
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    final doc = generateFieldServiceGroupSummaryReport(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Field Service Group Totals');
  }

  Future<Uint8List> buildFieldServiceGroupSummaryExcelBytes({
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    return buildFieldServiceGroupSummaryExcel(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );
  }

  /// Pioneer Hours — monthly and service-year-to-date hours per pioneer.
  Future<void> previewPioneerHours(
    BuildContext context, {
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    final doc = generatePioneerHoursReport(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Pioneer Hours');
  }

  Future<Uint8List> buildPioneerHoursExcelBytes({
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    return buildPioneerHoursExcel(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );
  }

  /// Missing Reports by Group — active publishers with no report submitted.
  Future<void> previewMissingReportsByGroup(
    BuildContext context, {
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    final doc = generateMissingReportsByGroupReport(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Missing Reports by Group');
  }

  Future<Uint8List> buildMissingReportsByGroupExcelBytes({
    required int year,
    required int month,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: year,
      month: month,
      congregationId: congregationId,
    );
    final groups = await _loadGroupsById();

    return buildMissingReportsByGroupExcel(
      persons: persons,
      reports: reports,
      groupsById: groups,
      year: year,
      month: month,
      congregation: await _loadCongregation(),
    );
  }

  /// Congregation Ministry Totals — a service year of monthly figures for
  /// publishers, auxiliary pioneers and regular pioneers.
  Future<void> previewMinistryTotals(
    BuildContext context, {
    required int serviceYear,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: serviceYear,
      congregationId: congregationId,
    );

    final doc = generateMinistryTotalsReport(
      persons: persons,
      reports: reports,
      serviceYear: serviceYear,
      congregation: await _loadCongregation(),
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, kMinistryTotalsTitle);
  }

  Future<Uint8List> buildMinistryTotalsExcelBytes({
    required int serviceYear,
  }) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final reports = await db.getServiceReports(
      year: serviceYear,
      congregationId: congregationId,
    );

    return buildMinistryTotalsExcel(
      persons: persons,
      reports: reports,
      serviceYear: serviceYear,
      congregation: await _loadCongregation(),
    );
  }

  /// Congregation Summary — all active, new inactive, reactivated.
  Future<void> previewCongregationSummary(
    BuildContext context, {
    int? serviceYear,
    int throughMonth = 8,
  }) async {
    final doc = await buildCongregationSummary(
      serviceYear: serviceYear,
      throughMonth: throughMonth,
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Congregation Summary - All Categories');
  }

  /// Uses the same analysis as the screen; defaults to the last completed year.
  Future<pw.Document> buildCongregationSummary({
    int? serviceYear,
    int throughMonth = 8,
  }) async {
    final analysis = await db.getCongregationAnalysis(
      congregationId: congregationId,
      serviceYear: serviceYear,
      throughMonth: throughMonth,
    );
    final people = await db.getAllPersons(congregationId: congregationId);
    List<Person> members(List<int> personIds) {
      final ids = personIds.toSet();
      return people.where((person) => ids.contains(person.id)).toList();
    }

    return generateCongregationSummaryReport(
      allActive: members(analysis.allActivePersonIds),
      newInactive: members(analysis.newInactivePersonIds),
      reactivated: members(analysis.reactivatedPersonIds),
      periodLabel:
          'Service year ${analysis.serviceYear}: '
          '${formatServiceMonth(analysis.serviceYear, 9)} - '
          '${formatServiceMonth(analysis.serviceYear, analysis.throughMonth)}',
      congregation: await _loadCongregation(),
    );
  }

  // ── Preview helper ───────────────────────────────

  Future<void> _showPreview(
    BuildContext context,
    dynamic doc,
    String title,
  ) async {
    final bytes = await doc.save();
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: PdfPreview(
            build: (_) async => bytes,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: '${title.replaceAll(' ', '_')}.pdf',
          ),
        ),
      ),
    );
  }

  // ── File export methods ──────────────────────────

  /// Export all standard publisher PDF reports to a directory.
  Future<void> exportAllReports(
    String dirPath, {
    ExportProgressCallback? onProgress,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    const totalReports = 5;
    onProgress?.call(
      const ExportProgress(
        current: 0,
        total: totalReports,
        message: 'Preparing reports',
      ),
    );

    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();
    final ecs = await _loadAllEmergencyContacts();
    final congregation = await _loadCongregation();

    var completed = 0;

    // Publisher Directory
    onProgress?.call(
      const ExportProgress(
        current: 0,
        total: totalReports,
        message: 'Exporting Publisher Directory',
      ),
    );
    final dirDoc = generatePublisherDirectoryReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
      congregation: congregation,
    );
    await File(
      '$dirPath/Publisher_Directory.pdf',
    ).writeAsBytes(await dirDoc.save());
    completed++;
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exported Publisher Directory',
      ),
    );

    // Publisher List
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exporting Publisher List',
      ),
    );
    final listDoc = generatePublisherListReport(
      persons: persons,
      groupsById: groups,
      congregation: congregation,
    );
    await File(
      '$dirPath/Publisher_List.pdf',
    ).writeAsBytes(await listDoc.save());
    completed++;
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exported Publisher List',
      ),
    );

    // Publisher Contact List
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exporting Publisher Contact List',
      ),
    );
    final contactDoc = generatePublisherContactListReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
      congregation: congregation,
    );
    await File(
      '$dirPath/Publisher_Contact_List.pdf',
    ).writeAsBytes(await contactDoc.save());
    completed++;
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exported Publisher Contact List',
      ),
    );

    // Emergency Contact List
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exporting Emergency Contact List',
      ),
    );
    final emergDoc = generateEmergencyContactListReport(
      persons: persons,
      phonesByPerson: phones,
      emergencyContactsByPerson: ecs,
      congregation: congregation,
    );
    await File(
      '$dirPath/Emergency_Contact_List.pdf',
    ).writeAsBytes(await emergDoc.save());
    completed++;
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exported Emergency Contact List',
      ),
    );

    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Exporting Congregation Summary',
      ),
    );
    final summaryDoc = await buildCongregationSummary();
    await File(
      '$dirPath/Congregation_Summary_All_Categories.pdf',
    ).writeAsBytes(await summaryDoc.save());
    completed++;
    onProgress?.call(
      ExportProgress(
        current: completed,
        total: totalReports,
        message: 'Export complete',
      ),
    );
  }

  /// Export publisher contact list as an Excel (.xlsx) file.
  Future<Uint8List> buildPublisherContactListExcel() async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();

    final report = PublisherContactListExcelReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
      congregation: await _loadCongregation(),
    );

    return report.buildBytes();
  }

  /// Export publisher contact list as an Excel (.xlsx) file.
  Future<void> exportExcel(String filePath) async {
    final bytes = await buildPublisherContactListExcel();
    await File(filePath).writeAsBytes(bytes);
  }

  /// Export S-21 publisher record PDFs.
  ///
  /// Covers the active persons by default; [includeInactive] adds the
  /// inactive ones, and [personIds] restricts the export to a selection.
  Future<List<String>> exportPublisherRecords({
    required String dirPath,
    required int serviceYear,
    bool flatten = false,
    bool groupByRole = false,
    bool groupByFieldServiceGroup = false,
    bool twoYearsPerPage = false,
    bool onlyUpToPreviousMonth = false,
    bool includeInactive = false,
    Set<int>? personIds,
    String fileNameTemplate = '{LastName}, {FirstName}',
    ExportProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const ExportProgress(current: 0, total: 0, message: 'Loading publishers'),
    );
    final persons = await db.getAllPersons(congregationId: congregationId);
    final groupsById = groupByFieldServiceGroup
        ? await _loadGroupsById()
        : const <int, FieldServiceGroup>{};
    // An explicit selection wins over the active/inactive filter: the user
    // already picked exactly whose records to export.
    final selected =
        persons.where((p) {
          if (personIds != null) return personIds.contains(p.id);
          return includeInactive || p.isActive;
        }).toList()..sort((a, b) {
          if (groupByFieldServiceGroup) {
            final byGroup = _groupSortName(
              a,
              groupsById,
            ).compareTo(_groupSortName(b, groupsById));
            if (byGroup != 0) return byGroup;
          }
          return '${a.lastName}, ${a.firstName}'.compareTo(
            '${b.lastName}, ${b.firstName}',
          );
        });

    final reportsByPerson = <int, List<ServiceReport>>{};
    for (var i = 0; i < selected.length; i++) {
      final p = selected[i];
      onProgress?.call(
        ExportProgress(
          current: i,
          total: selected.length,
          message: 'Loading service report history',
          detail: '${p.lastName}, ${p.firstName}',
        ),
      );
      final reports = await db.getServiceReports(personId: p.id);
      reportsByPerson[p.id] = reports;
    }

    String formatRecordName(Person person) {
      return _formatRecordNameTemplate(person, fileNameTemplate);
    }

    return PublisherRecordWriter.exportAllPersonRecords(
      persons: selected,
      reportsByPerson: reportsByPerson,
      serviceYear: serviceYear,
      outputDir: dirPath,
      flatten: flatten,
      groupByRole: groupByRole,
      groupByFieldServiceGroup: groupByFieldServiceGroup,
      groupsById: groupsById,
      twoYearsPerPage: twoYearsPerPage,
      onlyUpToPreviousMonth: onlyUpToPreviousMonth,
      onProgress: onProgress,
      fileNameFormatter: formatRecordName,
      nameFormatter: formatRecordName,
    );
  }

  static String _formatRecordNameTemplate(Person person, String template) {
    return template
        .replaceAll('{FirstName}', person.firstName)
        .replaceAll('{LastName}', person.lastName)
        .replaceAll('{FullName}', '${person.lastName}, ${person.firstName}');
  }

  static String _groupSortName(
    Person person,
    Map<int, FieldServiceGroup> groupsById,
  ) {
    final groupId = person.fieldServiceGroupId;
    if (groupId == null) return 'Unassigned';
    final groupName = groupsById[groupId]?.name.trim();
    if (groupName == null || groupName.isEmpty) return 'Unassigned';
    return groupName;
  }
}
