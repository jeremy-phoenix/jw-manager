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
final personProvider =
    FutureProvider.family<Person, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.getPerson(id);
});

/// Provides phone numbers for a person.
final phoneNumbersProvider =
    FutureProvider.family<List<PhoneNumber>, int>((ref, personId) {
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
        PersonSearchQueryNotifier.new);

/// Filtered persons based on search query.
final filteredPersonsProvider = Provider<AsyncValue<List<Person>>>((ref) {
  final personsAsync = ref.watch(personsProvider);
  final query = ref.watch(personSearchQueryProvider).toLowerCase();

  return personsAsync.whenData((persons) {
    if (query.isEmpty) return persons;
    return persons.where((p) {
      final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
      return fullName.contains(query) ||
          p.address.toLowerCase().contains(query);
    }).toList();
  });
});
