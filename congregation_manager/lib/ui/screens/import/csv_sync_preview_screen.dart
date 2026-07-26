// ignore_for_file: deprecated_member_use

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/services/csv_sync_service.dart';

/// Full-screen dialog that shows CSV sync preview and lets user pick changes.
class CsvSyncPreviewScreen extends ConsumerStatefulWidget {
  final String csvFilePath;

  const CsvSyncPreviewScreen({super.key, required this.csvFilePath});

  @override
  ConsumerState<CsvSyncPreviewScreen> createState() =>
      _CsvSyncPreviewScreenState();
}

class _CsvSyncPreviewScreenState extends ConsumerState<CsvSyncPreviewScreen> {
  SyncResult? _syncResult;
  bool _loading = true;
  String? _error;
  final Set<int> _selectedUpdateIndices = {};
  final Map<int, Person?> _fuzzyMatchSelections = {};

  @override
  void initState() {
    super.initState();
    _loadSync();
  }

  Future<void> _loadSync() async {
    try {
      final db = ref.read(databaseProvider);
      final csvRecords = CsvSyncService.parseCsvFile(widget.csvFilePath);
      final dbPersons = await db.getAllPersons(
        congregationId: ref.read(currentCongregationIdProvider),
      );
      final result = await CsvSyncService.syncRecordsWithPhones(
        csvRecords,
        dbPersons,
        db,
      );

      if (mounted) {
        setState(() {
          _syncResult = result;
          _loading = false;
          // Select all updates by default
          _selectedUpdateIndices.addAll(
            List.generate(result.updates.length, (i) => i),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Sync Preview'),
        actions: [
          if (_syncResult != null)
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
              onPressed: _applyChanges,
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final result = _syncResult!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _summaryChip(Icons.link, 'Matched', result.matched),
                const SizedBox(width: 16),
                _summaryChip(Icons.edit, 'Updates', result.updates.length),
                const SizedBox(width: 16),
                _summaryChip(
                  Icons.person_add,
                  'Unmatched CSV',
                  result.unmatchedCsv.length,
                ),
                const SizedBox(width: 16),
                _summaryChip(
                  Icons.person_off,
                  'Unmatched DB',
                  result.unmatchedDb.length,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Updates section
        if (result.updates.isNotEmpty) ...[
          _sectionHeader(
            'Changes to Apply',
            '${result.updates.length} update(s)',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(
                  () => _selectedUpdateIndices.addAll(
                    List.generate(result.updates.length, (i) => i),
                  ),
                ),
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedUpdateIndices.clear()),
                child: const Text('Deselect All'),
              ),
            ],
          ),
          ...result.updates.asMap().entries.map((entry) {
            final idx = entry.key;
            final update = entry.value;
            return Card(
              child: CheckboxListTile(
                value: _selectedUpdateIndices.contains(idx),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedUpdateIndices.add(idx);
                  } else {
                    _selectedUpdateIndices.remove(idx);
                  }
                }),
                title: Text(
                  formatPersonName(
                    update.dbPerson.firstName,
                    update.dbPerson.lastName,
                    ref.watch(nameOrderProvider),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change: ${update.changeType}',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    if (update.addressChanged) ...[
                      Text(
                        'Old Address: ${update.oldAddress ?? "—"}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'New Address: ${update.newAddress ?? "—"}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                    if (update.phonesChanged) ...[
                      Text(
                        'Old Phones: ${update.oldPhones.isEmpty ? "—" : update.oldPhones.join(", ")}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'New Phones: ${update.newPhones.isEmpty ? "—" : update.newPhones.join(", ")}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        // Unmatched CSV records
        if (result.unmatchedCsv.isNotEmpty) ...[
          _sectionHeader(
            'Unmatched CSV Records',
            '${result.unmatchedCsv.length} record(s) not found in database',
          ),
          const SizedBox(height: 8),
          ...result.unmatchedCsv.asMap().entries.map((entry) {
            final idx = entry.key;
            final csv = entry.value;
            final fuzzyMatches = CsvSyncService.findFuzzyMatches(
              csv,
              result.unmatchedDb,
            );
            return Card(
              child: ExpansionTile(
                title: Text(csv.fullName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (csv.address != null) Text('Address: ${csv.address}'),
                    if (csv.phoneNumbers.isNotEmpty)
                      Text('Phones: ${csv.phoneNumbers.join(", ")}'),
                  ],
                ),
                children: [
                  if (fuzzyMatches.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Possible matches:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...fuzzyMatches.map((match) {
                      final (person, score) = match;
                      return RadioListTile<Person?>(
                        value: person,
                        groupValue: _fuzzyMatchSelections[idx],
                        onChanged: (v) =>
                            setState(() => _fuzzyMatchSelections[idx] = v),
                        title: Text(
                          '${formatPersonName(person.firstName, person.lastName, ref.watch(nameOrderProvider))} (score: $score)',
                        ),
                      );
                    }),
                    RadioListTile<Person?>(
                      value: null,
                      groupValue: _fuzzyMatchSelections.containsKey(idx)
                          ? _fuzzyMatchSelections[idx]
                          : null,
                      onChanged: (v) =>
                          setState(() => _fuzzyMatchSelections[idx] = null),
                      title: const Text('Skip'),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No similar records found in database.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        // Unmatched DB records
        if (result.unmatchedDb.isNotEmpty) ...[
          _sectionHeader(
            'Unmatched Database Records',
            '${result.unmatchedDb.length} person(s) not in CSV',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: result.unmatchedDb.map((p) {
                return ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.orange),
                  title: Text(
                    formatPersonName(
                      p.firstName,
                      p.lastName,
                      ref.watch(nameOrderProvider),
                    ),
                  ),
                  subtitle: Text(p.address.isEmpty ? '—' : p.address),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryChip(IconData icon, String label, int count) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $count'));
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _applyChanges() async {
    final result = _syncResult!;
    final db = ref.read(databaseProvider);
    var appliedCount = 0;

    try {
      // Apply selected updates
      for (final idx in _selectedUpdateIndices) {
        final update = result.updates[idx];
        final person = update.dbPerson;

        if (update.addressChanged && update.newAddress != null) {
          await db.updatePerson(
            PersonsCompanion(
              id: Value(person.id),
              firstName: Value(person.firstName),
              lastName: Value(person.lastName),
              address: Value(update.newAddress ?? ''),
              email: Value(person.email),
            ),
          );
        }

        if (update.phonesChanged) {
          // Delete existing phones and re-create
          final existing = await db.getPhoneNumbers(person.id);
          for (final phone in existing) {
            await db.deletePhoneNumber(phone.id);
          }
          for (final companion in CsvSyncService.buildPhoneCompanions(
            update.newPhones,
            person.id,
          )) {
            await db.insertPhoneNumber(companion);
          }
        }
        appliedCount++;
      }

      // Apply fuzzy matches
      for (final entry in _fuzzyMatchSelections.entries) {
        final person = entry.value;
        if (person == null) continue;
        final csvRecord = result.unmatchedCsv[entry.key];

        if (csvRecord.address != null && csvRecord.address != person.address) {
          await db.updatePerson(
            PersonsCompanion(
              id: Value(person.id),
              firstName: Value(person.firstName),
              lastName: Value(person.lastName),
              address: Value(csvRecord.address ?? ''),
              email: Value(person.email),
            ),
          );
        }

        if (csvRecord.phoneNumbers.isNotEmpty) {
          final existing = await db.getPhoneNumbers(person.id);
          for (final phone in existing) {
            await db.deletePhoneNumber(phone.id);
          }
          for (final companion in CsvSyncService.buildPhoneCompanions(
            csvRecord.phoneNumbers,
            person.id,
          )) {
            await db.insertPhoneNumber(companion);
          }
        }
        appliedCount++;
      }

      ref.invalidate(personsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Applied $appliedCount change(s).')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying changes: $e')));
      }
    }
  }
}
