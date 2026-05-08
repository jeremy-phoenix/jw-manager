import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/reporting/publisher_directory_report.dart';
import 'package:congregation_manager/reporting/publisher_list_report.dart';
import 'package:congregation_manager/reporting/publisher_contact_list_report.dart';
import 'package:congregation_manager/reporting/emergency_contact_list_report.dart';
import 'package:congregation_manager/reporting/not_shared_in_ministry_report.dart';
import 'package:congregation_manager/reporting/not_shared_by_group_report.dart';
import 'package:congregation_manager/reporting/congregation_summary_report.dart';
import 'package:congregation_manager/reporting/publisher_contact_list_excel_report.dart';
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
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Publisher List');
  }

  /// Publisher Contact List — landscape, names + addresses + phones + groups.
  Future<void> previewPublisherContactList(BuildContext context) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();

    final doc = generatePublisherContactListReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
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
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Not Shared in Ministry by Group');
  }

  /// Congregation Summary — all active, new inactive, reactivated.
  Future<void> previewCongregationSummary(BuildContext context) async {
    final summary = await _loadCongregationSummary();

    final doc = generateCongregationSummaryReport(
      allActive: summary.allActive,
      newInactive: summary.newInactive,
      reactivated: summary.reactivated,
    );

    if (!context.mounted) return;
    await _showPreview(context, doc, 'Congregation Summary - All Categories');
  }

  Future<_CongregationSummaryLists> _loadCongregationSummary() async {
    final persons = (await db.getAllPersons(
      congregationId: congregationId,
    )).where((p) => p.isActive).toList();
    final allActive = <Person>[];
    final newInactive = <Person>[];
    final reactivated = <Person>[];

    for (final person in persons) {
      final reports = await db.getServiceReports(personId: person.id);
      reports.sort(
        (a, b) => _serviceYearIndex(
          a.year,
          a.month,
        ).compareTo(_serviceYearIndex(b.year, b.month)),
      );

      final shared = reports.map((r) => r.sharedInMinistry).toList();
      if (shared.isEmpty) continue;

      final last6 = shared.length > 6
          ? shared.sublist(shared.length - 6)
          : shared;
      final isMinistryActive = last6.any((value) => value);
      if (isMinistryActive) allActive.add(person);

      final inactivity = _findInactivityStreak(shared);
      if (inactivity.hasStreak && !isMinistryActive) {
        newInactive.add(person);
      }

      if (inactivity.hasStreak && inactivity.endIndex < shared.length - 1) {
        final sharedAfter = shared
            .sublist(inactivity.endIndex + 1)
            .any((value) => value);
        if (sharedAfter) reactivated.add(person);
      }
    }

    return _CongregationSummaryLists(
      allActive: allActive,
      newInactive: newInactive,
      reactivated: reactivated,
    );
  }

  static int _serviceYearIndex(int year, int month) {
    final serviceYear = month >= 9 ? year + 1 : year;
    final serviceMonth = month >= 9 ? month - 8 : month + 4;
    return serviceYear * 12 + serviceMonth;
  }

  static _InactivityStreak _findInactivityStreak(List<bool> reports) {
    var consecutiveNoShare = 0;
    for (var i = 0; i < reports.length; i++) {
      if (reports[i]) {
        consecutiveNoShare = 0;
      } else {
        consecutiveNoShare++;
        if (consecutiveNoShare >= 6) {
          return _InactivityStreak(hasStreak: true, endIndex: i);
        }
      }
    }
    return const _InactivityStreak(hasStreak: false, endIndex: -1);
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

    onProgress?.call(
      const ExportProgress(current: 0, total: 0, message: 'Preparing reports'),
    );

    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();
    final ecs = await _loadAllEmergencyContacts();

    const totalReports = 5;
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
    final summary = await _loadCongregationSummary();
    final summaryDoc = generateCongregationSummaryReport(
      allActive: summary.allActive,
      newInactive: summary.newInactive,
      reactivated: summary.reactivated,
    );
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
  Future<void> exportExcel(String filePath) async {
    final persons = await db.getAllPersons(congregationId: congregationId);
    final phones = await _loadAllPhones();
    final groups = await _loadGroupsById();

    final report = PublisherContactListExcelReport(
      persons: persons,
      phonesByPerson: phones,
      groupsById: groups,
    );

    await report.save(filePath);
  }

  /// Export S-21 publisher record PDFs for all active persons.
  Future<List<String>> exportPublisherRecords({
    required String dirPath,
    required int serviceYear,
    bool flatten = false,
    bool groupByRole = false,
    bool twoYearsPerPage = false,
    bool onlyUpToPreviousMonth = false,
    String fileNameTemplate = '{LastName}, {FirstName}',
    ExportProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const ExportProgress(current: 0, total: 0, message: 'Loading publishers'),
    );
    final persons = await db.getAllPersons(congregationId: congregationId);
    final active = persons.where((p) => p.isActive).toList()
      ..sort(
        (a, b) => '${a.lastName}, ${a.firstName}'.compareTo(
          '${b.lastName}, ${b.firstName}',
        ),
      );

    final reportsByPerson = <int, List<ServiceReport>>{};
    for (var i = 0; i < active.length; i++) {
      final p = active[i];
      onProgress?.call(
        ExportProgress(
          current: i,
          total: active.length,
          message: 'Loading service report history',
          detail: '${p.lastName}, ${p.firstName}',
        ),
      );
      final reports = await db.getServiceReports(personId: p.id);
      reportsByPerson[p.id] = reports;
    }

    return PublisherRecordWriter.exportAllPersonRecords(
      persons: active,
      reportsByPerson: reportsByPerson,
      serviceYear: serviceYear,
      outputDir: dirPath,
      flatten: flatten,
      groupByRole: groupByRole,
      twoYearsPerPage: twoYearsPerPage,
      onlyUpToPreviousMonth: onlyUpToPreviousMonth,
      onProgress: onProgress,
      fileNameFormatter: (person) {
        return fileNameTemplate
            .replaceAll('{FirstName}', person.firstName)
            .replaceAll('{LastName}', person.lastName)
            .replaceAll(
              '{FullName}',
              '${person.lastName}, ${person.firstName}',
            );
      },
    );
  }
}

class _CongregationSummaryLists {
  final List<Person> allActive;
  final List<Person> newInactive;
  final List<Person> reactivated;

  const _CongregationSummaryLists({
    required this.allActive,
    required this.newInactive,
    required this.reactivated,
  });
}

class _InactivityStreak {
  final bool hasStreak;
  final int endIndex;

  const _InactivityStreak({required this.hasStreak, required this.endIndex});
}
