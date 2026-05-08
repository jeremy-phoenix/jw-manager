import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/services/publisher_record_reader.dart';

enum ImportAction { create, merge, skip }

/// Full-screen dialog to preview imported S-21 PDF persons and choose actions.
class ImportPersonsScreen extends ConsumerStatefulWidget {
  final List<ImportedPerson> importedPersons;

  const ImportPersonsScreen({super.key, required this.importedPersons});

  @override
  ConsumerState<ImportPersonsScreen> createState() =>
      _ImportPersonsScreenState();
}

class _ImportPersonsScreenState extends ConsumerState<ImportPersonsScreen> {
  late List<_ImportItem> _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = ref.read(databaseProvider);
    final dbPersons = await db.getAllPersons(
        congregationId: ref.read(currentCongregationIdProvider));

    _items = widget.importedPersons.map((imported) {
      final match = _findExactMatch(imported, dbPersons);
      return _ImportItem(
        imported: imported,
        matchedPerson: match,
        action: match != null ? ImportAction.merge : ImportAction.create,
      );
    }).toList();

    if (mounted) setState(() => _loading = false);
  }

  Person? _findExactMatch(ImportedPerson imported, List<Person> dbPersons) {
    for (final p in dbPersons) {
      if (p.lastName.toLowerCase() == imported.lastName.toLowerCase() &&
          p.firstName.toLowerCase() == imported.firstName.toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Import Preview (${widget.importedPersons.length} record(s))'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Import'),
            onPressed: _loading ? null : _applyImport,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.imported.fullName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (item.matchedPerson != null)
                      Chip(
                        label: const Text('Exists'),
                        avatar: const Icon(Icons.person, size: 16),
                        backgroundColor: Colors.orange[100],
                      ),
                    const SizedBox(width: 8),
                    SegmentedButton<ImportAction>(
                      segments: const [
                        ButtonSegment(
                          value: ImportAction.create,
                          label: Text('Create'),
                          icon: Icon(Icons.add),
                        ),
                        ButtonSegment(
                          value: ImportAction.merge,
                          label: Text('Merge'),
                          icon: Icon(Icons.merge),
                        ),
                        ButtonSegment(
                          value: ImportAction.skip,
                          label: Text('Skip'),
                          icon: Icon(Icons.skip_next),
                        ),
                      ],
                      selected: {item.action},
                      onSelectionChanged: (v) {
                        setState(() => item.action = v.first);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (item.imported.gender != Gender.unknown)
                      _infoChip(Icons.person,
                          item.imported.gender.displayName),
                    if (item.imported.hopeClass != HopeClass.unknown)
                      _infoChip(Icons.church,
                          item.imported.hopeClass.displayName),
                    if (item.imported.congregationRole !=
                        CongregationRole.none)
                      _infoChip(Icons.badge,
                          item.imported.congregationRole.displayName),
                    if (item.imported.pioneerType != PioneerType.none)
                      _infoChip(Icons.hiking,
                          item.imported.pioneerType.displayName),
                    if (item.imported.birthDate != null)
                      _infoChip(Icons.cake,
                          'DOB: ${_formatDate(item.imported.birthDate!)}'),
                    if (item.imported.baptismDate != null)
                      _infoChip(Icons.water,
                          'Baptism: ${_formatDate(item.imported.baptismDate!)}'),
                    _infoChip(Icons.assignment,
                        '${item.imported.serviceReports.length} reports'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _applyImport() async {
    final db = ref.read(databaseProvider);
    var created = 0;
    var merged = 0;
    var skipped = 0;

    try {
      for (final item in _items) {
        switch (item.action) {
          case ImportAction.skip:
            skipped++;
            continue;

          case ImportAction.create:
            final congId = ref.read(currentCongregationIdProvider);
            final personId = await db.insertPerson(PersonsCompanion.insert(
              firstName: Value(item.imported.firstName),
              lastName: Value(item.imported.lastName),
              address: Value(item.imported.address ?? ''),
              birthDate: Value(item.imported.birthDate),
              baptismDate: Value(item.imported.baptismDate),
              gender: Value(item.imported.gender),
              hopeClass: Value(item.imported.hopeClass),
              congregationRole: Value(item.imported.congregationRole),
              pioneerType: Value(item.imported.pioneerType),
              congregationId: Value(congId),
            ));

            if (item.imported.phoneNumber != null) {
              await db.insertPhoneNumber(PhoneNumbersCompanion.insert(
                number: Value(item.imported.phoneNumber!),
                phoneType: Value(PhoneType.mobile),
                isPrimary: Value(true),
                personId: personId,
              ));
            }

            await _importServiceReports(db, personId, item.imported);
            created++;

          case ImportAction.merge:
            final personId = item.matchedPerson?.id;
            if (personId == null) {
              // No match found, create instead
              final newId = await db.insertPerson(PersonsCompanion.insert(
                firstName: Value(item.imported.firstName),
                lastName: Value(item.imported.lastName),
                address: Value(item.imported.address ?? ''),
                birthDate: Value(item.imported.birthDate),
                baptismDate: Value(item.imported.baptismDate),
                gender: Value(item.imported.gender),
                hopeClass: Value(item.imported.hopeClass),
                congregationRole: Value(item.imported.congregationRole),
                pioneerType: Value(item.imported.pioneerType),
                congregationId: Value(ref.read(currentCongregationIdProvider)),
              ));
              await _importServiceReports(db, newId, item.imported);
              created++;
              continue;
            }

            // Merge: update fields that are set in the imported data
            final existing = item.matchedPerson!;
            await db.updatePerson(PersonsCompanion(
              id: Value(personId),
              firstName: Value(existing.firstName),
              lastName: Value(existing.lastName),
              address: item.imported.address != null
                  ? Value(item.imported.address!)
                  : Value(existing.address),
              birthDate: item.imported.birthDate != null
                  ? Value(item.imported.birthDate)
                  : Value(existing.birthDate),
              baptismDate: item.imported.baptismDate != null
                  ? Value(item.imported.baptismDate)
                  : Value(existing.baptismDate),
              gender: item.imported.gender != Gender.unknown
                  ? Value(item.imported.gender)
                  : Value(existing.gender),
              hopeClass: item.imported.hopeClass != HopeClass.unknown
                  ? Value(item.imported.hopeClass)
                  : Value(existing.hopeClass),
              congregationRole:
                  item.imported.congregationRole != CongregationRole.none
                      ? Value(item.imported.congregationRole)
                      : Value(existing.congregationRole),
              pioneerType: item.imported.pioneerType != PioneerType.none
                  ? Value(item.imported.pioneerType)
                  : Value(existing.pioneerType),
            ));

            await _importServiceReports(db, personId, item.imported);
            merged++;
        }
      }

      ref.invalidate(personsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Import complete: $created created, $merged merged, $skipped skipped.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  Future<void> _importServiceReports(
      AppDatabase db, int personId, ImportedPerson imported) async {
    for (final report in imported.serviceReports) {
      // Only import reports that have some data
      if (!report.sharedInMinistry &&
          report.bibleStudies == 0 &&
          !report.isAuxiliaryPioneer &&
          (report.hours == null || report.hours == 0) &&
          (report.note == null || report.note!.isEmpty)) {
        continue;
      }

      await db.upsertServiceReport(ServiceReportsCompanion.insert(
        personId: personId,
        year: report.year,
        month: report.month,
        sharedInMinistry: Value(report.sharedInMinistry),
        bibleStudies: Value(report.bibleStudies),
        isAuxiliaryPioneer: Value(report.isAuxiliaryPioneer),
        hours: Value(report.hours ?? 0),
        note: Value(report.note ?? ''),
      ));
    }
  }
}

class _ImportItem {
  final ImportedPerson imported;
  final Person? matchedPerson;
  ImportAction action;

  _ImportItem({
    required this.imported,
    this.matchedPerson,
    required this.action,
  });
}
