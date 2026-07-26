import 'package:drift/drift.dart';
import 'package:congregation_manager/data/enums.dart';

// ──────────────────────────────────────────────────────
// Drift table definitions matching the existing SQLite schema
// ──────────────────────────────────────────────────────

mixin SyncColumns on Table {
  TextColumn get syncId => text().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}

class Congregations extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get circuitNumber => text().withDefault(const Constant(''))();
  TextColumn get circuitOverseerName =>
      text().withDefault(const Constant(''))();
  TextColumn get circuitOverseerSpouseName =>
      text().withDefault(const Constant(''))();
  TextColumn get circuitOverseerPhone =>
      text().withDefault(const Constant(''))();
  TextColumn get circuitOverseerEmail =>
      text().withDefault(const Constant(''))();
  TextColumn get circuitOverseerAddress =>
      text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Persons extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get otherNames => text().withDefault(const Constant(''))();
  DateTimeColumn get birthDate => dateTime().nullable()();
  DateTimeColumn get baptismDate => dateTime().nullable()();
  IntColumn get gender => intEnum<Gender>().withDefault(const Constant(0))();
  IntColumn get hopeClass =>
      intEnum<HopeClass>().withDefault(const Constant(0))();
  IntColumn get congregationRole =>
      intEnum<CongregationRole>().withDefault(const Constant(0))();
  IntColumn get pioneerType =>
      intEnum<PioneerType>().withDefault(const Constant(0))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get inactiveDate => dateTime().nullable()();
  IntColumn get recordStatus =>
      intEnum<PersonRecordStatus>().withDefault(const Constant(0))();
  IntColumn get archiveReason => intEnum<PersonArchiveReason>().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get trashedAt => dateTime().nullable()();
  IntColumn get congregationId =>
      integer().nullable().references(Congregations, #id)();
  IntColumn get fieldServiceGroupId =>
      integer().nullable().references(FieldServiceGroups, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PhoneNumbers extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().withDefault(const Constant(''))();
  IntColumn get phoneType =>
      intEnum<PhoneType>().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get personId => integer().references(Persons, #id)();
}

class EmergencyContacts extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get phoneNumber => text().withDefault(const Constant(''))();
  IntColumn get relationship =>
      intEnum<Relationship>().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  IntColumn get personId => integer().references(Persons, #id)();
}

class ServiceReports extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  BoolColumn get isAuxiliaryPioneer =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get sharedInMinistry =>
      boolean().withDefault(const Constant(false))();
  IntColumn get bibleStudies => integer().withDefault(const Constant(0))();
  RealColumn get hours => real().withDefault(const Constant(0.0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get personId => integer().references(Persons, #id)();
}

class FieldServiceGroups extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get congregationId =>
      integer().nullable().references(Congregations, #id)();
  IntColumn get groupOverseerId => integer().nullable()();
  IntColumn get assistantId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class AuxiliaryPioneerPeriods extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startMonth => integer()();
  IntColumn get startYear => integer()();
  IntColumn get endMonth => integer().nullable()();
  IntColumn get endYear => integer().nullable()();
  IntColumn get personId => integer().references(Persons, #id)();
}

class SyncSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get serverUrl => text().nullable()();
  TextColumn get bearerToken => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get pullCursor => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingSyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationId => text()();
  TextColumn get entityType => text()();
  TextColumn get entitySyncId => text()();
  TextColumn get operationType => text()();
  TextColumn get payloadJson => text()();
  IntColumn get baseServerVersion => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

class SyncConflicts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entitySyncId => text()();
  TextColumn get localPayloadJson => text()();
  TextColumn get serverPayloadJson => text()();
  IntColumn get serverVersion => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}
