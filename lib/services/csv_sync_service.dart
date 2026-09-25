import 'dart:io';
import 'package:drift/drift.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';

/// Port of CsvPublisherSyncService from the .NET project.
/// Parses CSV files exported from jw.org and syncs address/phone changes
/// against the local database.
class CsvSyncService {
  /// A parsed CSV publisher record.
  CsvSyncService._();

  static List<CsvPublisherRecord> parseCsvFile(String filePath) {
    final records = <CsvPublisherRecord>[];
    final lines = File(filePath).readAsLinesSync();

    if (lines.length < 4) return records;

    var isActive = true;

    for (var i = 3; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final columns = _parseCsvLine(line);

      if (columns.length > 1 && columns[1].trim().toLowerCase() == 'inactive') {
        isActive = false;
        continue;
      }

      if (columns.length < 2 || columns[1].trim().isEmpty) continue;

      if (int.tryParse(columns[0].trim()) == null) continue;

      final (lastName, firstName) = _parseName(columns[1]);
      final address = columns.length > 2
          ? _nullIfEmpty(columns[2].trim())
          : null;
      final phones = columns.length > 3
          ? _parsePhoneNumbers(columns[3])
          : <String>[];

      records.add(
        CsvPublisherRecord(
          firstName: firstName,
          lastName: lastName,
          address: address,
          phoneNumbers: phones,
          isActive: isActive,
        ),
      );
    }

    return records;
  }

  static (String lastName, String firstName) _parseName(String raw) {
    final parts = raw.split(',');
    final lastName = parts[0].trim();
    final firstName = parts.length > 1
        ? parts
              .sublist(1)
              .join(',')
              .replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ')
              .trim()
        : '';
    return (lastName, firstName);
  }

  static List<String> _parsePhoneNumbers(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split('/')
        .map((p) => p.replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  static SyncResult syncRecords(
    List<CsvPublisherRecord> csvRecords,
    List<Person> dbPersons,
  ) {
    final updates = <SyncRecordResult>[];
    final unmatchedCsv = <CsvPublisherRecord>[];
    final matchedDbIds = <int>{};

    // Build lookup by (lastName, firstName) case-insensitive
    final dbLookup = <String, Person>{};
    for (final person in dbPersons) {
      final key =
          '${person.lastName.trim().toLowerCase()}|${person.firstName.trim().toLowerCase()}';
      dbLookup.putIfAbsent(key, () => person);
    }

    for (final csv in csvRecords) {
      final key =
          '${csv.lastName.trim().toLowerCase()}|${csv.firstName.trim().toLowerCase()}';

      final dbPerson = dbLookup[key];
      if (dbPerson != null) {
        matchedDbIds.add(dbPerson.id);

        final oldAddress = dbPerson.address.trim();
        final newAddress = csv.address?.trim() ?? '';
        final addressChanged =
            oldAddress.toLowerCase() != newAddress.toLowerCase() &&
            newAddress.isNotEmpty;

        final oldPhones = <String>[]; // will be filled by caller
        final phonesChanged = csv.phoneNumbers.isNotEmpty;

        if (addressChanged || phonesChanged) {
          updates.add(
            SyncRecordResult(
              dbPerson: dbPerson,
              oldAddress: oldAddress.isEmpty ? null : oldAddress,
              newAddress: newAddress.isEmpty ? null : newAddress,
              oldPhones: oldPhones,
              newPhones: csv.phoneNumbers,
              addressChanged: addressChanged,
              phonesChanged: phonesChanged,
            ),
          );
        }
      } else {
        unmatchedCsv.add(csv);
      }
    }

    final unmatchedDb = dbPersons
        .where((p) => !matchedDbIds.contains(p.id))
        .toList();

    return SyncResult(
      matched: matchedDbIds.length,
      updated: updates.length,
      updates: updates,
      unmatchedCsv: unmatchedCsv,
      unmatchedDb: unmatchedDb,
    );
  }

  /// Enhanced sync that also loads phone data for accurate comparison.
  static Future<SyncResult> syncRecordsWithPhones(
    List<CsvPublisherRecord> csvRecords,
    List<Person> dbPersons,
    AppDatabase db,
  ) async {
    final updates = <SyncRecordResult>[];
    final unmatchedCsv = <CsvPublisherRecord>[];
    final matchedDbIds = <int>{};

    final dbLookup = <String, Person>{};
    for (final person in dbPersons) {
      final key =
          '${person.lastName.trim().toLowerCase()}|${person.firstName.trim().toLowerCase()}';
      dbLookup.putIfAbsent(key, () => person);
    }

    for (final csv in csvRecords) {
      final key =
          '${csv.lastName.trim().toLowerCase()}|${csv.firstName.trim().toLowerCase()}';

      final dbPerson = dbLookup[key];
      if (dbPerson != null) {
        matchedDbIds.add(dbPerson.id);

        final oldAddress = dbPerson.address.trim();
        final newAddress = csv.address?.trim() ?? '';
        final addressChanged =
            oldAddress.toLowerCase() != newAddress.toLowerCase() &&
            newAddress.isNotEmpty;

        final existingPhones = await db.getPhoneNumbers(dbPerson.id);
        final oldPhoneNumbers =
            existingPhones.map((p) => p.number.trim()).toList()..sort();
        final newPhoneNumbers = csv.phoneNumbers.map((p) => p.trim()).toList()
          ..sort();

        final phonesChanged =
            csv.phoneNumbers.isNotEmpty &&
            !_listsEqual(oldPhoneNumbers, newPhoneNumbers);

        if (addressChanged || phonesChanged) {
          updates.add(
            SyncRecordResult(
              dbPerson: dbPerson,
              oldAddress: oldAddress.isEmpty ? null : oldAddress,
              newAddress: newAddress.isEmpty ? null : newAddress,
              oldPhones: existingPhones.map((p) => p.number).toList(),
              newPhones: csv.phoneNumbers,
              addressChanged: addressChanged,
              phonesChanged: phonesChanged,
            ),
          );
        }
      } else {
        unmatchedCsv.add(csv);
      }
    }

    final unmatchedDb = dbPersons
        .where((p) => !matchedDbIds.contains(p.id))
        .toList();

    return SyncResult(
      matched: matchedDbIds.length,
      updated: updates.length,
      updates: updates,
      unmatchedCsv: unmatchedCsv,
      unmatchedDb: unmatchedDb,
    );
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].toLowerCase() != b[i].toLowerCase()) return false;
    }
    return true;
  }

  /// Fuzzy match an unmatched CSV record against candidate DB persons.
  static List<(Person person, int score)> findFuzzyMatches(
    CsvPublisherRecord csv,
    List<Person> candidates, {
    int maxResults = 3,
  }) {
    final csvLast = csv.lastName.trim();
    final csvFirst = csv.firstName.trim();
    final scored = <(Person, int)>[];

    for (final person in candidates) {
      final dbLast = person.lastName.trim();
      final dbFirst = person.firstName.trim();
      var score = 0;

      if (dbLast.toLowerCase() == csvLast.toLowerCase()) {
        score += 50;
      } else if (dbLast.toLowerCase().contains(csvLast.toLowerCase()) ||
          csvLast.toLowerCase().contains(dbLast.toLowerCase())) {
        score += 30;
      }

      if (dbFirst.toLowerCase() == csvFirst.toLowerCase()) {
        score += 50;
      } else if (dbFirst.toLowerCase().startsWith(csvFirst.toLowerCase()) ||
          csvFirst.toLowerCase().startsWith(dbFirst.toLowerCase())) {
        score += 25;
      } else if (dbFirst.toLowerCase().contains(csvFirst.toLowerCase()) ||
          csvFirst.toLowerCase().contains(dbFirst.toLowerCase())) {
        score += 25;
      }

      if (person.otherNames.toLowerCase().contains(csvFirst.toLowerCase()) ||
          person.otherNames.toLowerCase().contains(csvLast.toLowerCase())) {
        score += 15;
      }

      if (score >= 25) scored.add((person, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(maxResults).toList();
  }

  /// Build PhoneNumbersCompanion list from raw phone strings.
  static List<PhoneNumbersCompanion> buildPhoneCompanions(
    List<String> phones,
    int personId,
  ) {
    return phones.asMap().entries.map((entry) {
      return PhoneNumbersCompanion.insert(
        number: Value(entry.value),
        phoneType: Value(PhoneType.mobile),
        isPrimary: Value(entry.key == 0),
        personId: personId,
      );
    }).toList();
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var inQuotes = false;
    final field = StringBuffer();

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        fields.add(field.toString());
        field.clear();
      } else {
        field.write(c);
      }
    }

    fields.add(field.toString());
    return fields;
  }

  static String? _nullIfEmpty(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value;
}

class CsvPublisherRecord {
  final String firstName;
  final String lastName;
  final String? address;
  final List<String> phoneNumbers;
  final bool isActive;

  const CsvPublisherRecord({
    required this.firstName,
    required this.lastName,
    this.address,
    this.phoneNumbers = const [],
    this.isActive = true,
  });

  String get fullName => '$lastName, $firstName';
}

class SyncRecordResult {
  final Person dbPerson;
  final String? oldAddress;
  final String? newAddress;
  final List<String> oldPhones;
  final List<String> newPhones;
  final bool addressChanged;
  final bool phonesChanged;

  const SyncRecordResult({
    required this.dbPerson,
    this.oldAddress,
    this.newAddress,
    this.oldPhones = const [],
    this.newPhones = const [],
    this.addressChanged = false,
    this.phonesChanged = false,
  });

  String get changeType {
    if (addressChanged && phonesChanged) return 'Address & Phone';
    if (addressChanged) return 'Address';
    if (phonesChanged) return 'Phone';
    return 'None';
  }
}

class SyncResult {
  final int matched;
  final int updated;
  final List<SyncRecordResult> updates;
  final List<CsvPublisherRecord> unmatchedCsv;
  final List<Person> unmatchedDb;

  const SyncResult({
    required this.matched,
    required this.updated,
    required this.updates,
    required this.unmatchedCsv,
    required this.unmatchedDb,
  });
}
