import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';

/// Provides the list of persons for the current congregation as a stream.
final personsProvider = StreamProvider<List<Person>>((ref) {
  final db = ref.watch(databaseProvider);
  final congId = ref.watch(currentCongregationIdProvider);
  return db.watchAllPersons(congregationId: congId);
});

/// Provides a single person by ID.
final personProvider = FutureProvider.family<Person, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.getPerson(id);
});

/// Provides phone numbers for a person.
final phoneNumbersProvider = FutureProvider.family<List<PhoneNumber>, int>((
  ref,
  personId,
) {
  final db = ref.watch(databaseProvider);
  return db.getPhoneNumbers(personId);
});

/// Provides emergency contacts for a person.
final emergencyContactsProvider =
    FutureProvider.family<List<EmergencyContact>, int>((ref, personId) {
      final db = ref.watch(databaseProvider);
      return db.getEmergencyContacts(personId);
    });

/// Provides auxiliary pioneer periods for a person.
final auxiliaryPioneerPeriodsProvider =
    FutureProvider.family<List<AuxiliaryPioneerPeriod>, int>((ref, personId) {
      final db = ref.watch(databaseProvider);
      return db.getAuxiliaryPioneerPeriods(personId);
    });

/// Search filter for persons list.
class PersonSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final personSearchQueryProvider =
    NotifierProvider<PersonSearchQueryNotifier, String>(
      PersonSearchQueryNotifier.new,
    );

class ShowInactivePersonsNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

final showInactivePersonsProvider =
    NotifierProvider<ShowInactivePersonsNotifier, bool>(
      ShowInactivePersonsNotifier.new,
    );

/// Filtered persons based on search query.
final filteredPersonsProvider = Provider<AsyncValue<List<Person>>>((ref) {
  final personsAsync = ref.watch(personsProvider);
  final query = ref.watch(personSearchQueryProvider).trim().toLowerCase();
  final showInactivePersons = ref.watch(showInactivePersonsProvider);

  return personsAsync.whenData((persons) {
    final activeFiltered = showInactivePersons
        ? persons
        : persons.where((person) => person.isActive).toList();
    if (query.isEmpty) return activeFiltered;
    return activeFiltered.where((p) {
      final searchableName = [
        p.firstName,
        p.lastName,
        p.otherNames,
        '${p.firstName} ${p.lastName}',
        '${p.lastName}, ${p.firstName}',
      ].join(' ').toLowerCase();
      return searchableName.contains(query) ||
          p.address.toLowerCase().contains(query);
    }).toList();
  });
});
