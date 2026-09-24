import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/settings_providers.dart';

/// Provides the list of persons for the current congregation as a stream.
final personsProvider = StreamProvider<List<Person>>((ref) {
  final db = ref.watch(databaseProvider);
  final congId = ref.watch(currentCongregationIdProvider);
  return db.watchAllPersons(congregationId: congId);
});

/// Archived publisher records for the current congregation.
final archivedPersonsProvider = StreamProvider<List<Person>>((ref) {
  final db = ref.watch(databaseProvider);
  final congId = ref.watch(currentCongregationIdProvider);
  return db.watchAllPersons(
    congregationId: congId,
    recordStatus: PersonRecordStatus.archived,
  );
});

/// Trashed publisher records for the current congregation.
final trashedPersonsProvider = StreamProvider<List<Person>>((ref) {
  final db = ref.watch(databaseProvider);
  final congId = ref.watch(currentCongregationIdProvider);
  return db.watchAllPersons(
    congregationId: congId,
    recordStatus: PersonRecordStatus.trashed,
  );
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

enum BaptismDateFilter { any, recorded, missing }

enum GroupAssignmentFilter { any, assigned, unassigned }

enum PioneerAssignmentFilter {
  any,
  pioneer,
  publisher,
  regularPioneer,
  specialPioneer,
  fieldMissionary,
}

enum CongregationRoleFilter { any, noAppointment, elder, ministerialServant }

enum PersonSortField {
  name,
  baptismDate,
  birthDate,
  congregationRole,
  pioneerType,
  activeStatus,
}

class PersonListOptions {
  final bool includeInactive;
  final BaptismDateFilter baptismDateFilter;
  final GroupAssignmentFilter groupAssignmentFilter;
  final PioneerAssignmentFilter pioneerAssignmentFilter;
  final CongregationRoleFilter congregationRoleFilter;
  final PersonSortField sortField;
  final bool sortAscending;

  const PersonListOptions({
    this.includeInactive = true,
    this.baptismDateFilter = BaptismDateFilter.any,
    this.groupAssignmentFilter = GroupAssignmentFilter.any,
    this.pioneerAssignmentFilter = PioneerAssignmentFilter.any,
    this.congregationRoleFilter = CongregationRoleFilter.any,
    this.sortField = PersonSortField.name,
    this.sortAscending = true,
  });

  int get activeOptionCount =>
      (includeInactive ? 0 : 1) +
      (baptismDateFilter == BaptismDateFilter.any ? 0 : 1) +
      (groupAssignmentFilter == GroupAssignmentFilter.any ? 0 : 1) +
      (pioneerAssignmentFilter == PioneerAssignmentFilter.any ? 0 : 1) +
      (congregationRoleFilter == CongregationRoleFilter.any ? 0 : 1) +
      (sortField == PersonSortField.name && sortAscending ? 0 : 1);

  PersonListOptions copyWith({
    bool? includeInactive,
    BaptismDateFilter? baptismDateFilter,
    GroupAssignmentFilter? groupAssignmentFilter,
    PioneerAssignmentFilter? pioneerAssignmentFilter,
    CongregationRoleFilter? congregationRoleFilter,
    PersonSortField? sortField,
    bool? sortAscending,
  }) {
    return PersonListOptions(
      includeInactive: includeInactive ?? this.includeInactive,
      baptismDateFilter: baptismDateFilter ?? this.baptismDateFilter,
      groupAssignmentFilter:
          groupAssignmentFilter ?? this.groupAssignmentFilter,
      pioneerAssignmentFilter:
          pioneerAssignmentFilter ?? this.pioneerAssignmentFilter,
      congregationRoleFilter:
          congregationRoleFilter ?? this.congregationRoleFilter,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class PersonListOptionsNotifier extends Notifier<PersonListOptions> {
  @override
  PersonListOptions build() => const PersonListOptions();

  void set(PersonListOptions value) => state = value;

  void reset() => state = const PersonListOptions();
}

final personListOptionsProvider =
    NotifierProvider<PersonListOptionsNotifier, PersonListOptions>(
      PersonListOptionsNotifier.new,
    );

/// Persons filtered and sorted by the current list options and search query.
final filteredPersonsProvider = Provider<AsyncValue<List<Person>>>((ref) {
  final personsAsync = ref.watch(personsProvider);
  final query = ref.watch(personSearchQueryProvider).trim().toLowerCase();
  final options = ref.watch(personListOptionsProvider);
  final nameOrder = ref.watch(nameOrderProvider);

  return personsAsync.whenData((persons) {
    final filtered = persons.where((person) {
      if (!options.includeInactive && !person.isActive) return false;

      switch (options.baptismDateFilter) {
        case BaptismDateFilter.any:
          break;
        case BaptismDateFilter.recorded:
          if (person.baptismDate == null) return false;
          break;
        case BaptismDateFilter.missing:
          if (person.baptismDate != null) return false;
          break;
      }

      switch (options.groupAssignmentFilter) {
        case GroupAssignmentFilter.any:
          break;
        case GroupAssignmentFilter.assigned:
          if (person.fieldServiceGroupId == null) return false;
          break;
        case GroupAssignmentFilter.unassigned:
          if (person.fieldServiceGroupId != null) return false;
          break;
      }

      final expectedPioneerType = switch (options.pioneerAssignmentFilter) {
        PioneerAssignmentFilter.any => null,
        PioneerAssignmentFilter.pioneer => null,
        PioneerAssignmentFilter.publisher => PioneerType.none,
        PioneerAssignmentFilter.regularPioneer => PioneerType.regularPioneer,
        PioneerAssignmentFilter.specialPioneer => PioneerType.specialPioneer,
        PioneerAssignmentFilter.fieldMissionary => PioneerType.fieldMissionary,
      };
      if (options.pioneerAssignmentFilter == PioneerAssignmentFilter.pioneer &&
          person.pioneerType == PioneerType.none) {
        return false;
      }
      if (expectedPioneerType != null &&
          person.pioneerType != expectedPioneerType) {
        return false;
      }

      final expectedRole = switch (options.congregationRoleFilter) {
        CongregationRoleFilter.any => null,
        CongregationRoleFilter.noAppointment => CongregationRole.none,
        CongregationRoleFilter.elder => CongregationRole.elder,
        CongregationRoleFilter.ministerialServant =>
          CongregationRole.ministerialServant,
      };
      if (expectedRole != null && person.congregationRole != expectedRole) {
        return false;
      }

      if (query.isEmpty) return true;
      final searchableName = [
        person.firstName,
        person.lastName,
        person.otherNames,
        '${person.firstName} ${person.lastName}',
        '${person.lastName}, ${person.firstName}',
      ].join(' ').toLowerCase();
      return searchableName.contains(query) ||
          person.address.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final result = switch (options.sortField) {
        PersonSortField.name => _compareNames(a, b, nameOrder),
        PersonSortField.baptismDate => _compareNullableDates(
          a.baptismDate,
          b.baptismDate,
          ascending: options.sortAscending,
        ),
        PersonSortField.birthDate => _compareNullableDates(
          a.birthDate,
          b.birthDate,
          ascending: options.sortAscending,
        ),
        PersonSortField.congregationRole => a.congregationRole.index.compareTo(
          b.congregationRole.index,
        ),
        PersonSortField.pioneerType => a.pioneerType.index.compareTo(
          b.pioneerType.index,
        ),
        PersonSortField.activeStatus => (a.isActive ? 1 : 0).compareTo(
          b.isActive ? 1 : 0,
        ),
      };
      if (result == 0) return _compareNames(a, b, nameOrder);
      if (options.sortField == PersonSortField.baptismDate ||
          options.sortField == PersonSortField.birthDate) {
        return result;
      }
      return options.sortAscending ? result : -result;
    });
    return filtered;
  });
});

int _compareNames(Person a, Person b, NameOrder order) {
  final first = formatPersonName(a.firstName, a.lastName, order).toLowerCase();
  final second = formatPersonName(b.firstName, b.lastName, order).toLowerCase();
  return first.compareTo(second);
}

int _compareNullableDates(DateTime? a, DateTime? b, {required bool ascending}) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return ascending ? a.compareTo(b) : b.compareTo(a);
}
