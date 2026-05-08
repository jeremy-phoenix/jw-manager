// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CongregationsTable extends Congregations
    with TableInfo<$CongregationsTable, Congregation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CongregationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _circuitNumberMeta = const VerificationMeta(
    'circuitNumber',
  );
  @override
  late final GeneratedColumn<String> circuitNumber = GeneratedColumn<String>(
    'circuit_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    name,
    number,
    city,
    circuitNumber,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'congregations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Congregation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('circuit_number')) {
      context.handle(
        _circuitNumberMeta,
        circuitNumber.isAcceptableOrUnknown(
          data['circuit_number']!,
          _circuitNumberMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Congregation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Congregation(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      circuitNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}circuit_number'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CongregationsTable createAlias(String alias) {
    return $CongregationsTable(attachedDatabase, alias);
  }
}

class Congregation extends DataClass implements Insertable<Congregation> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final String name;
  final String number;
  final String city;
  final String circuitNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Congregation({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.name,
    required this.number,
    required this.city,
    required this.circuitNumber,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['number'] = Variable<String>(number);
    map['city'] = Variable<String>(city);
    map['circuit_number'] = Variable<String>(circuitNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CongregationsCompanion toCompanion(bool nullToAbsent) {
    return CongregationsCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      name: Value(name),
      number: Value(number),
      city: Value(city),
      circuitNumber: Value(circuitNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Congregation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Congregation(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      number: serializer.fromJson<String>(json['number']),
      city: serializer.fromJson<String>(json['city']),
      circuitNumber: serializer.fromJson<String>(json['circuitNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'number': serializer.toJson<String>(number),
      'city': serializer.toJson<String>(city),
      'circuitNumber': serializer.toJson<String>(circuitNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Congregation copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    String? name,
    String? number,
    String? city,
    String? circuitNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Congregation(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    number: number ?? this.number,
    city: city ?? this.city,
    circuitNumber: circuitNumber ?? this.circuitNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Congregation copyWithCompanion(CongregationsCompanion data) {
    return Congregation(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      number: data.number.present ? data.number.value : this.number,
      city: data.city.present ? data.city.value : this.city,
      circuitNumber: data.circuitNumber.present
          ? data.circuitNumber.value
          : this.circuitNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Congregation(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('city: $city, ')
          ..write('circuitNumber: $circuitNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    name,
    number,
    city,
    circuitNumber,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Congregation &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.number == this.number &&
          other.city == this.city &&
          other.circuitNumber == this.circuitNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CongregationsCompanion extends UpdateCompanion<Congregation> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<String> name;
  final Value<String> number;
  final Value<String> city;
  final Value<String> circuitNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CongregationsCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.number = const Value.absent(),
    this.city = const Value.absent(),
    this.circuitNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CongregationsCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.number = const Value.absent(),
    this.city = const Value.absent(),
    this.circuitNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<Congregation> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? number,
    Expression<String>? city,
    Expression<String>? circuitNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (number != null) 'number': number,
      if (city != null) 'city': city,
      if (circuitNumber != null) 'circuit_number': circuitNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CongregationsCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<String>? name,
    Value<String>? number,
    Value<String>? city,
    Value<String>? circuitNumber,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CongregationsCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      city: city ?? this.city,
      circuitNumber: circuitNumber ?? this.circuitNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (circuitNumber.present) {
      map['circuit_number'] = Variable<String>(circuitNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CongregationsCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('city: $city, ')
          ..write('circuitNumber: $circuitNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FieldServiceGroupsTable extends FieldServiceGroups
    with TableInfo<$FieldServiceGroupsTable, FieldServiceGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FieldServiceGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _congregationIdMeta = const VerificationMeta(
    'congregationId',
  );
  @override
  late final GeneratedColumn<int> congregationId = GeneratedColumn<int>(
    'congregation_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES congregations (id)',
    ),
  );
  static const VerificationMeta _groupOverseerIdMeta = const VerificationMeta(
    'groupOverseerId',
  );
  @override
  late final GeneratedColumn<int> groupOverseerId = GeneratedColumn<int>(
    'group_overseer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assistantIdMeta = const VerificationMeta(
    'assistantId',
  );
  @override
  late final GeneratedColumn<int> assistantId = GeneratedColumn<int>(
    'assistant_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    name,
    description,
    congregationId,
    groupOverseerId,
    assistantId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'field_service_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldServiceGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('congregation_id')) {
      context.handle(
        _congregationIdMeta,
        congregationId.isAcceptableOrUnknown(
          data['congregation_id']!,
          _congregationIdMeta,
        ),
      );
    }
    if (data.containsKey('group_overseer_id')) {
      context.handle(
        _groupOverseerIdMeta,
        groupOverseerId.isAcceptableOrUnknown(
          data['group_overseer_id']!,
          _groupOverseerIdMeta,
        ),
      );
    }
    if (data.containsKey('assistant_id')) {
      context.handle(
        _assistantIdMeta,
        assistantId.isAcceptableOrUnknown(
          data['assistant_id']!,
          _assistantIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldServiceGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldServiceGroup(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      congregationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}congregation_id'],
      ),
      groupOverseerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_overseer_id'],
      ),
      assistantId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assistant_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FieldServiceGroupsTable createAlias(String alias) {
    return $FieldServiceGroupsTable(attachedDatabase, alias);
  }
}

class FieldServiceGroup extends DataClass
    implements Insertable<FieldServiceGroup> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final String name;
  final String description;
  final int? congregationId;
  final int? groupOverseerId;
  final int? assistantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FieldServiceGroup({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.name,
    required this.description,
    this.congregationId,
    this.groupOverseerId,
    this.assistantId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || congregationId != null) {
      map['congregation_id'] = Variable<int>(congregationId);
    }
    if (!nullToAbsent || groupOverseerId != null) {
      map['group_overseer_id'] = Variable<int>(groupOverseerId);
    }
    if (!nullToAbsent || assistantId != null) {
      map['assistant_id'] = Variable<int>(assistantId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FieldServiceGroupsCompanion toCompanion(bool nullToAbsent) {
    return FieldServiceGroupsCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      name: Value(name),
      description: Value(description),
      congregationId: congregationId == null && nullToAbsent
          ? const Value.absent()
          : Value(congregationId),
      groupOverseerId: groupOverseerId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupOverseerId),
      assistantId: assistantId == null && nullToAbsent
          ? const Value.absent()
          : Value(assistantId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FieldServiceGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldServiceGroup(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      congregationId: serializer.fromJson<int?>(json['congregationId']),
      groupOverseerId: serializer.fromJson<int?>(json['groupOverseerId']),
      assistantId: serializer.fromJson<int?>(json['assistantId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'congregationId': serializer.toJson<int?>(congregationId),
      'groupOverseerId': serializer.toJson<int?>(groupOverseerId),
      'assistantId': serializer.toJson<int?>(assistantId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FieldServiceGroup copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    String? name,
    String? description,
    Value<int?> congregationId = const Value.absent(),
    Value<int?> groupOverseerId = const Value.absent(),
    Value<int?> assistantId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FieldServiceGroup(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    congregationId: congregationId.present
        ? congregationId.value
        : this.congregationId,
    groupOverseerId: groupOverseerId.present
        ? groupOverseerId.value
        : this.groupOverseerId,
    assistantId: assistantId.present ? assistantId.value : this.assistantId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FieldServiceGroup copyWithCompanion(FieldServiceGroupsCompanion data) {
    return FieldServiceGroup(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      congregationId: data.congregationId.present
          ? data.congregationId.value
          : this.congregationId,
      groupOverseerId: data.groupOverseerId.present
          ? data.groupOverseerId.value
          : this.groupOverseerId,
      assistantId: data.assistantId.present
          ? data.assistantId.value
          : this.assistantId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldServiceGroup(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('congregationId: $congregationId, ')
          ..write('groupOverseerId: $groupOverseerId, ')
          ..write('assistantId: $assistantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    name,
    description,
    congregationId,
    groupOverseerId,
    assistantId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldServiceGroup &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.congregationId == this.congregationId &&
          other.groupOverseerId == this.groupOverseerId &&
          other.assistantId == this.assistantId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FieldServiceGroupsCompanion extends UpdateCompanion<FieldServiceGroup> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<int?> congregationId;
  final Value<int?> groupOverseerId;
  final Value<int?> assistantId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FieldServiceGroupsCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.congregationId = const Value.absent(),
    this.groupOverseerId = const Value.absent(),
    this.assistantId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FieldServiceGroupsCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.congregationId = const Value.absent(),
    this.groupOverseerId = const Value.absent(),
    this.assistantId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<FieldServiceGroup> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? congregationId,
    Expression<int>? groupOverseerId,
    Expression<int>? assistantId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (congregationId != null) 'congregation_id': congregationId,
      if (groupOverseerId != null) 'group_overseer_id': groupOverseerId,
      if (assistantId != null) 'assistant_id': assistantId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FieldServiceGroupsCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<String>? name,
    Value<String>? description,
    Value<int?>? congregationId,
    Value<int?>? groupOverseerId,
    Value<int?>? assistantId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FieldServiceGroupsCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      congregationId: congregationId ?? this.congregationId,
      groupOverseerId: groupOverseerId ?? this.groupOverseerId,
      assistantId: assistantId ?? this.assistantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (congregationId.present) {
      map['congregation_id'] = Variable<int>(congregationId.value);
    }
    if (groupOverseerId.present) {
      map['group_overseer_id'] = Variable<int>(groupOverseerId.value);
    }
    if (assistantId.present) {
      map['assistant_id'] = Variable<int>(assistantId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FieldServiceGroupsCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('congregationId: $congregationId, ')
          ..write('groupOverseerId: $groupOverseerId, ')
          ..write('assistantId: $assistantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _otherNamesMeta = const VerificationMeta(
    'otherNames',
  );
  @override
  late final GeneratedColumn<String> otherNames = GeneratedColumn<String>(
    'other_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baptismDateMeta = const VerificationMeta(
    'baptismDate',
  );
  @override
  late final GeneratedColumn<DateTime> baptismDate = GeneratedColumn<DateTime>(
    'baptism_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Gender, int> gender =
      GeneratedColumn<int>(
        'gender',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Gender>($PersonsTable.$convertergender);
  @override
  late final GeneratedColumnWithTypeConverter<HopeClass, int> hopeClass =
      GeneratedColumn<int>(
        'hope_class',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<HopeClass>($PersonsTable.$converterhopeClass);
  @override
  late final GeneratedColumnWithTypeConverter<CongregationRole, int>
  congregationRole = GeneratedColumn<int>(
    'congregation_role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<CongregationRole>($PersonsTable.$convertercongregationRole);
  @override
  late final GeneratedColumnWithTypeConverter<PioneerType, int> pioneerType =
      GeneratedColumn<int>(
        'pioneer_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PioneerType>($PersonsTable.$converterpioneerType);
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _inactiveDateMeta = const VerificationMeta(
    'inactiveDate',
  );
  @override
  late final GeneratedColumn<DateTime> inactiveDate = GeneratedColumn<DateTime>(
    'inactive_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _congregationIdMeta = const VerificationMeta(
    'congregationId',
  );
  @override
  late final GeneratedColumn<int> congregationId = GeneratedColumn<int>(
    'congregation_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES congregations (id)',
    ),
  );
  static const VerificationMeta _fieldServiceGroupIdMeta =
      const VerificationMeta('fieldServiceGroupId');
  @override
  late final GeneratedColumn<int> fieldServiceGroupId = GeneratedColumn<int>(
    'field_service_group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES field_service_groups (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    firstName,
    lastName,
    otherNames,
    birthDate,
    baptismDate,
    gender,
    hopeClass,
    congregationRole,
    pioneerType,
    address,
    isActive,
    inactiveDate,
    congregationId,
    fieldServiceGroupId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('other_names')) {
      context.handle(
        _otherNamesMeta,
        otherNames.isAcceptableOrUnknown(data['other_names']!, _otherNamesMeta),
      );
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    }
    if (data.containsKey('baptism_date')) {
      context.handle(
        _baptismDateMeta,
        baptismDate.isAcceptableOrUnknown(
          data['baptism_date']!,
          _baptismDateMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('inactive_date')) {
      context.handle(
        _inactiveDateMeta,
        inactiveDate.isAcceptableOrUnknown(
          data['inactive_date']!,
          _inactiveDateMeta,
        ),
      );
    }
    if (data.containsKey('congregation_id')) {
      context.handle(
        _congregationIdMeta,
        congregationId.isAcceptableOrUnknown(
          data['congregation_id']!,
          _congregationIdMeta,
        ),
      );
    }
    if (data.containsKey('field_service_group_id')) {
      context.handle(
        _fieldServiceGroupIdMeta,
        fieldServiceGroupId.isAcceptableOrUnknown(
          data['field_service_group_id']!,
          _fieldServiceGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      otherNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_names'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      ),
      baptismDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}baptism_date'],
      ),
      gender: $PersonsTable.$convertergender.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}gender'],
        )!,
      ),
      hopeClass: $PersonsTable.$converterhopeClass.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}hope_class'],
        )!,
      ),
      congregationRole: $PersonsTable.$convertercongregationRole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}congregation_role'],
        )!,
      ),
      pioneerType: $PersonsTable.$converterpioneerType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pioneer_type'],
        )!,
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      inactiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}inactive_date'],
      ),
      congregationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}congregation_id'],
      ),
      fieldServiceGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}field_service_group_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Gender, int, int> $convertergender =
      const EnumIndexConverter<Gender>(Gender.values);
  static JsonTypeConverter2<HopeClass, int, int> $converterhopeClass =
      const EnumIndexConverter<HopeClass>(HopeClass.values);
  static JsonTypeConverter2<CongregationRole, int, int>
  $convertercongregationRole = const EnumIndexConverter<CongregationRole>(
    CongregationRole.values,
  );
  static JsonTypeConverter2<PioneerType, int, int> $converterpioneerType =
      const EnumIndexConverter<PioneerType>(PioneerType.values);
}

class Person extends DataClass implements Insertable<Person> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final String firstName;
  final String lastName;
  final String otherNames;
  final DateTime? birthDate;
  final DateTime? baptismDate;
  final Gender gender;
  final HopeClass hopeClass;
  final CongregationRole congregationRole;
  final PioneerType pioneerType;
  final String address;
  final bool isActive;
  final DateTime? inactiveDate;
  final int? congregationId;
  final int? fieldServiceGroupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Person({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.otherNames,
    this.birthDate,
    this.baptismDate,
    required this.gender,
    required this.hopeClass,
    required this.congregationRole,
    required this.pioneerType,
    required this.address,
    required this.isActive,
    this.inactiveDate,
    this.congregationId,
    this.fieldServiceGroupId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['other_names'] = Variable<String>(otherNames);
    if (!nullToAbsent || birthDate != null) {
      map['birth_date'] = Variable<DateTime>(birthDate);
    }
    if (!nullToAbsent || baptismDate != null) {
      map['baptism_date'] = Variable<DateTime>(baptismDate);
    }
    {
      map['gender'] = Variable<int>(
        $PersonsTable.$convertergender.toSql(gender),
      );
    }
    {
      map['hope_class'] = Variable<int>(
        $PersonsTable.$converterhopeClass.toSql(hopeClass),
      );
    }
    {
      map['congregation_role'] = Variable<int>(
        $PersonsTable.$convertercongregationRole.toSql(congregationRole),
      );
    }
    {
      map['pioneer_type'] = Variable<int>(
        $PersonsTable.$converterpioneerType.toSql(pioneerType),
      );
    }
    map['address'] = Variable<String>(address);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || inactiveDate != null) {
      map['inactive_date'] = Variable<DateTime>(inactiveDate);
    }
    if (!nullToAbsent || congregationId != null) {
      map['congregation_id'] = Variable<int>(congregationId);
    }
    if (!nullToAbsent || fieldServiceGroupId != null) {
      map['field_service_group_id'] = Variable<int>(fieldServiceGroupId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      otherNames: Value(otherNames),
      birthDate: birthDate == null && nullToAbsent
          ? const Value.absent()
          : Value(birthDate),
      baptismDate: baptismDate == null && nullToAbsent
          ? const Value.absent()
          : Value(baptismDate),
      gender: Value(gender),
      hopeClass: Value(hopeClass),
      congregationRole: Value(congregationRole),
      pioneerType: Value(pioneerType),
      address: Value(address),
      isActive: Value(isActive),
      inactiveDate: inactiveDate == null && nullToAbsent
          ? const Value.absent()
          : Value(inactiveDate),
      congregationId: congregationId == null && nullToAbsent
          ? const Value.absent()
          : Value(congregationId),
      fieldServiceGroupId: fieldServiceGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldServiceGroupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      otherNames: serializer.fromJson<String>(json['otherNames']),
      birthDate: serializer.fromJson<DateTime?>(json['birthDate']),
      baptismDate: serializer.fromJson<DateTime?>(json['baptismDate']),
      gender: $PersonsTable.$convertergender.fromJson(
        serializer.fromJson<int>(json['gender']),
      ),
      hopeClass: $PersonsTable.$converterhopeClass.fromJson(
        serializer.fromJson<int>(json['hopeClass']),
      ),
      congregationRole: $PersonsTable.$convertercongregationRole.fromJson(
        serializer.fromJson<int>(json['congregationRole']),
      ),
      pioneerType: $PersonsTable.$converterpioneerType.fromJson(
        serializer.fromJson<int>(json['pioneerType']),
      ),
      address: serializer.fromJson<String>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      inactiveDate: serializer.fromJson<DateTime?>(json['inactiveDate']),
      congregationId: serializer.fromJson<int?>(json['congregationId']),
      fieldServiceGroupId: serializer.fromJson<int?>(
        json['fieldServiceGroupId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'otherNames': serializer.toJson<String>(otherNames),
      'birthDate': serializer.toJson<DateTime?>(birthDate),
      'baptismDate': serializer.toJson<DateTime?>(baptismDate),
      'gender': serializer.toJson<int>(
        $PersonsTable.$convertergender.toJson(gender),
      ),
      'hopeClass': serializer.toJson<int>(
        $PersonsTable.$converterhopeClass.toJson(hopeClass),
      ),
      'congregationRole': serializer.toJson<int>(
        $PersonsTable.$convertercongregationRole.toJson(congregationRole),
      ),
      'pioneerType': serializer.toJson<int>(
        $PersonsTable.$converterpioneerType.toJson(pioneerType),
      ),
      'address': serializer.toJson<String>(address),
      'isActive': serializer.toJson<bool>(isActive),
      'inactiveDate': serializer.toJson<DateTime?>(inactiveDate),
      'congregationId': serializer.toJson<int?>(congregationId),
      'fieldServiceGroupId': serializer.toJson<int?>(fieldServiceGroupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Person copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    String? firstName,
    String? lastName,
    String? otherNames,
    Value<DateTime?> birthDate = const Value.absent(),
    Value<DateTime?> baptismDate = const Value.absent(),
    Gender? gender,
    HopeClass? hopeClass,
    CongregationRole? congregationRole,
    PioneerType? pioneerType,
    String? address,
    bool? isActive,
    Value<DateTime?> inactiveDate = const Value.absent(),
    Value<int?> congregationId = const Value.absent(),
    Value<int?> fieldServiceGroupId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Person(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    otherNames: otherNames ?? this.otherNames,
    birthDate: birthDate.present ? birthDate.value : this.birthDate,
    baptismDate: baptismDate.present ? baptismDate.value : this.baptismDate,
    gender: gender ?? this.gender,
    hopeClass: hopeClass ?? this.hopeClass,
    congregationRole: congregationRole ?? this.congregationRole,
    pioneerType: pioneerType ?? this.pioneerType,
    address: address ?? this.address,
    isActive: isActive ?? this.isActive,
    inactiveDate: inactiveDate.present ? inactiveDate.value : this.inactiveDate,
    congregationId: congregationId.present
        ? congregationId.value
        : this.congregationId,
    fieldServiceGroupId: fieldServiceGroupId.present
        ? fieldServiceGroupId.value
        : this.fieldServiceGroupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      otherNames: data.otherNames.present
          ? data.otherNames.value
          : this.otherNames,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      baptismDate: data.baptismDate.present
          ? data.baptismDate.value
          : this.baptismDate,
      gender: data.gender.present ? data.gender.value : this.gender,
      hopeClass: data.hopeClass.present ? data.hopeClass.value : this.hopeClass,
      congregationRole: data.congregationRole.present
          ? data.congregationRole.value
          : this.congregationRole,
      pioneerType: data.pioneerType.present
          ? data.pioneerType.value
          : this.pioneerType,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      inactiveDate: data.inactiveDate.present
          ? data.inactiveDate.value
          : this.inactiveDate,
      congregationId: data.congregationId.present
          ? data.congregationId.value
          : this.congregationId,
      fieldServiceGroupId: data.fieldServiceGroupId.present
          ? data.fieldServiceGroupId.value
          : this.fieldServiceGroupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('otherNames: $otherNames, ')
          ..write('birthDate: $birthDate, ')
          ..write('baptismDate: $baptismDate, ')
          ..write('gender: $gender, ')
          ..write('hopeClass: $hopeClass, ')
          ..write('congregationRole: $congregationRole, ')
          ..write('pioneerType: $pioneerType, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('inactiveDate: $inactiveDate, ')
          ..write('congregationId: $congregationId, ')
          ..write('fieldServiceGroupId: $fieldServiceGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    firstName,
    lastName,
    otherNames,
    birthDate,
    baptismDate,
    gender,
    hopeClass,
    congregationRole,
    pioneerType,
    address,
    isActive,
    inactiveDate,
    congregationId,
    fieldServiceGroupId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.otherNames == this.otherNames &&
          other.birthDate == this.birthDate &&
          other.baptismDate == this.baptismDate &&
          other.gender == this.gender &&
          other.hopeClass == this.hopeClass &&
          other.congregationRole == this.congregationRole &&
          other.pioneerType == this.pioneerType &&
          other.address == this.address &&
          other.isActive == this.isActive &&
          other.inactiveDate == this.inactiveDate &&
          other.congregationId == this.congregationId &&
          other.fieldServiceGroupId == this.fieldServiceGroupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> otherNames;
  final Value<DateTime?> birthDate;
  final Value<DateTime?> baptismDate;
  final Value<Gender> gender;
  final Value<HopeClass> hopeClass;
  final Value<CongregationRole> congregationRole;
  final Value<PioneerType> pioneerType;
  final Value<String> address;
  final Value<bool> isActive;
  final Value<DateTime?> inactiveDate;
  final Value<int?> congregationId;
  final Value<int?> fieldServiceGroupId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PersonsCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.otherNames = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.baptismDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.hopeClass = const Value.absent(),
    this.congregationRole = const Value.absent(),
    this.pioneerType = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.inactiveDate = const Value.absent(),
    this.congregationId = const Value.absent(),
    this.fieldServiceGroupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.otherNames = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.baptismDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.hopeClass = const Value.absent(),
    this.congregationRole = const Value.absent(),
    this.pioneerType = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.inactiveDate = const Value.absent(),
    this.congregationId = const Value.absent(),
    this.fieldServiceGroupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<Person> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? otherNames,
    Expression<DateTime>? birthDate,
    Expression<DateTime>? baptismDate,
    Expression<int>? gender,
    Expression<int>? hopeClass,
    Expression<int>? congregationRole,
    Expression<int>? pioneerType,
    Expression<String>? address,
    Expression<bool>? isActive,
    Expression<DateTime>? inactiveDate,
    Expression<int>? congregationId,
    Expression<int>? fieldServiceGroupId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (otherNames != null) 'other_names': otherNames,
      if (birthDate != null) 'birth_date': birthDate,
      if (baptismDate != null) 'baptism_date': baptismDate,
      if (gender != null) 'gender': gender,
      if (hopeClass != null) 'hope_class': hopeClass,
      if (congregationRole != null) 'congregation_role': congregationRole,
      if (pioneerType != null) 'pioneer_type': pioneerType,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (inactiveDate != null) 'inactive_date': inactiveDate,
      if (congregationId != null) 'congregation_id': congregationId,
      if (fieldServiceGroupId != null)
        'field_service_group_id': fieldServiceGroupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PersonsCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? otherNames,
    Value<DateTime?>? birthDate,
    Value<DateTime?>? baptismDate,
    Value<Gender>? gender,
    Value<HopeClass>? hopeClass,
    Value<CongregationRole>? congregationRole,
    Value<PioneerType>? pioneerType,
    Value<String>? address,
    Value<bool>? isActive,
    Value<DateTime?>? inactiveDate,
    Value<int?>? congregationId,
    Value<int?>? fieldServiceGroupId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PersonsCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      otherNames: otherNames ?? this.otherNames,
      birthDate: birthDate ?? this.birthDate,
      baptismDate: baptismDate ?? this.baptismDate,
      gender: gender ?? this.gender,
      hopeClass: hopeClass ?? this.hopeClass,
      congregationRole: congregationRole ?? this.congregationRole,
      pioneerType: pioneerType ?? this.pioneerType,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      inactiveDate: inactiveDate ?? this.inactiveDate,
      congregationId: congregationId ?? this.congregationId,
      fieldServiceGroupId: fieldServiceGroupId ?? this.fieldServiceGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (otherNames.present) {
      map['other_names'] = Variable<String>(otherNames.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (baptismDate.present) {
      map['baptism_date'] = Variable<DateTime>(baptismDate.value);
    }
    if (gender.present) {
      map['gender'] = Variable<int>(
        $PersonsTable.$convertergender.toSql(gender.value),
      );
    }
    if (hopeClass.present) {
      map['hope_class'] = Variable<int>(
        $PersonsTable.$converterhopeClass.toSql(hopeClass.value),
      );
    }
    if (congregationRole.present) {
      map['congregation_role'] = Variable<int>(
        $PersonsTable.$convertercongregationRole.toSql(congregationRole.value),
      );
    }
    if (pioneerType.present) {
      map['pioneer_type'] = Variable<int>(
        $PersonsTable.$converterpioneerType.toSql(pioneerType.value),
      );
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (inactiveDate.present) {
      map['inactive_date'] = Variable<DateTime>(inactiveDate.value);
    }
    if (congregationId.present) {
      map['congregation_id'] = Variable<int>(congregationId.value);
    }
    if (fieldServiceGroupId.present) {
      map['field_service_group_id'] = Variable<int>(fieldServiceGroupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('otherNames: $otherNames, ')
          ..write('birthDate: $birthDate, ')
          ..write('baptismDate: $baptismDate, ')
          ..write('gender: $gender, ')
          ..write('hopeClass: $hopeClass, ')
          ..write('congregationRole: $congregationRole, ')
          ..write('pioneerType: $pioneerType, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('inactiveDate: $inactiveDate, ')
          ..write('congregationId: $congregationId, ')
          ..write('fieldServiceGroupId: $fieldServiceGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PhoneNumbersTable extends PhoneNumbers
    with TableInfo<$PhoneNumbersTable, PhoneNumber> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhoneNumbersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PhoneType, int> phoneType =
      GeneratedColumn<int>(
        'phone_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PhoneType>($PhoneNumbersTable.$converterphoneType);
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    number,
    phoneType,
    isPrimary,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phone_numbers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhoneNumber> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhoneNumber map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhoneNumber(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      phoneType: $PhoneNumbersTable.$converterphoneType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}phone_type'],
        )!,
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $PhoneNumbersTable createAlias(String alias) {
    return $PhoneNumbersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PhoneType, int, int> $converterphoneType =
      const EnumIndexConverter<PhoneType>(PhoneType.values);
}

class PhoneNumber extends DataClass implements Insertable<PhoneNumber> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final String number;
  final PhoneType phoneType;
  final bool isPrimary;
  final int personId;
  const PhoneNumber({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.number,
    required this.phoneType,
    required this.isPrimary,
    required this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['number'] = Variable<String>(number);
    {
      map['phone_type'] = Variable<int>(
        $PhoneNumbersTable.$converterphoneType.toSql(phoneType),
      );
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['person_id'] = Variable<int>(personId);
    return map;
  }

  PhoneNumbersCompanion toCompanion(bool nullToAbsent) {
    return PhoneNumbersCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      number: Value(number),
      phoneType: Value(phoneType),
      isPrimary: Value(isPrimary),
      personId: Value(personId),
    );
  }

  factory PhoneNumber.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhoneNumber(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<String>(json['number']),
      phoneType: $PhoneNumbersTable.$converterphoneType.fromJson(
        serializer.fromJson<int>(json['phoneType']),
      ),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      personId: serializer.fromJson<int>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<String>(number),
      'phoneType': serializer.toJson<int>(
        $PhoneNumbersTable.$converterphoneType.toJson(phoneType),
      ),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'personId': serializer.toJson<int>(personId),
    };
  }

  PhoneNumber copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    String? number,
    PhoneType? phoneType,
    bool? isPrimary,
    int? personId,
  }) => PhoneNumber(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    number: number ?? this.number,
    phoneType: phoneType ?? this.phoneType,
    isPrimary: isPrimary ?? this.isPrimary,
    personId: personId ?? this.personId,
  );
  PhoneNumber copyWithCompanion(PhoneNumbersCompanion data) {
    return PhoneNumber(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      phoneType: data.phoneType.present ? data.phoneType.value : this.phoneType,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhoneNumber(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('phoneType: $phoneType, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    number,
    phoneType,
    isPrimary,
    personId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhoneNumber &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.number == this.number &&
          other.phoneType == this.phoneType &&
          other.isPrimary == this.isPrimary &&
          other.personId == this.personId);
}

class PhoneNumbersCompanion extends UpdateCompanion<PhoneNumber> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<String> number;
  final Value<PhoneType> phoneType;
  final Value<bool> isPrimary;
  final Value<int> personId;
  const PhoneNumbersCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.phoneType = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.personId = const Value.absent(),
  });
  PhoneNumbersCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.phoneType = const Value.absent(),
    this.isPrimary = const Value.absent(),
    required int personId,
  }) : personId = Value(personId);
  static Insertable<PhoneNumber> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<String>? number,
    Expression<int>? phoneType,
    Expression<bool>? isPrimary,
    Expression<int>? personId,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (phoneType != null) 'phone_type': phoneType,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (personId != null) 'person_id': personId,
    });
  }

  PhoneNumbersCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<String>? number,
    Value<PhoneType>? phoneType,
    Value<bool>? isPrimary,
    Value<int>? personId,
  }) {
    return PhoneNumbersCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      number: number ?? this.number,
      phoneType: phoneType ?? this.phoneType,
      isPrimary: isPrimary ?? this.isPrimary,
      personId: personId ?? this.personId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (phoneType.present) {
      map['phone_type'] = Variable<int>(
        $PhoneNumbersTable.$converterphoneType.toSql(phoneType.value),
      );
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhoneNumbersCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('phoneType: $phoneType, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }
}

class $EmergencyContactsTable extends EmergencyContacts
    with TableInfo<$EmergencyContactsTable, EmergencyContact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergencyContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Relationship, int> relationship =
      GeneratedColumn<int>(
        'relationship',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Relationship>(
        $EmergencyContactsTable.$converterrelationship,
      );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    name,
    phoneNumber,
    relationship,
    isPrimary,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmergencyContact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyContact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyContact(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      )!,
      relationship: $EmergencyContactsTable.$converterrelationship.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}relationship'],
        )!,
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $EmergencyContactsTable createAlias(String alias) {
    return $EmergencyContactsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Relationship, int, int> $converterrelationship =
      const EnumIndexConverter<Relationship>(Relationship.values);
}

class EmergencyContact extends DataClass
    implements Insertable<EmergencyContact> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final String name;
  final String phoneNumber;
  final Relationship relationship;
  final bool isPrimary;
  final int personId;
  const EmergencyContact({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.isPrimary,
    required this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['phone_number'] = Variable<String>(phoneNumber);
    {
      map['relationship'] = Variable<int>(
        $EmergencyContactsTable.$converterrelationship.toSql(relationship),
      );
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['person_id'] = Variable<int>(personId);
    return map;
  }

  EmergencyContactsCompanion toCompanion(bool nullToAbsent) {
    return EmergencyContactsCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      name: Value(name),
      phoneNumber: Value(phoneNumber),
      relationship: Value(relationship),
      isPrimary: Value(isPrimary),
      personId: Value(personId),
    );
  }

  factory EmergencyContact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyContact(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      relationship: $EmergencyContactsTable.$converterrelationship.fromJson(
        serializer.fromJson<int>(json['relationship']),
      ),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      personId: serializer.fromJson<int>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'relationship': serializer.toJson<int>(
        $EmergencyContactsTable.$converterrelationship.toJson(relationship),
      ),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'personId': serializer.toJson<int>(personId),
    };
  }

  EmergencyContact copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    String? name,
    String? phoneNumber,
    Relationship? relationship,
    bool? isPrimary,
    int? personId,
  }) => EmergencyContact(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    relationship: relationship ?? this.relationship,
    isPrimary: isPrimary ?? this.isPrimary,
    personId: personId ?? this.personId,
  );
  EmergencyContact copyWithCompanion(EmergencyContactsCompanion data) {
    return EmergencyContact(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContact(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('relationship: $relationship, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    name,
    phoneNumber,
    relationship,
    isPrimary,
    personId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyContact &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.phoneNumber == this.phoneNumber &&
          other.relationship == this.relationship &&
          other.isPrimary == this.isPrimary &&
          other.personId == this.personId);
}

class EmergencyContactsCompanion extends UpdateCompanion<EmergencyContact> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<String> name;
  final Value<String> phoneNumber;
  final Value<Relationship> relationship;
  final Value<bool> isPrimary;
  final Value<int> personId;
  const EmergencyContactsCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.relationship = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.personId = const Value.absent(),
  });
  EmergencyContactsCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.relationship = const Value.absent(),
    this.isPrimary = const Value.absent(),
    required int personId,
  }) : personId = Value(personId);
  static Insertable<EmergencyContact> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phoneNumber,
    Expression<int>? relationship,
    Expression<bool>? isPrimary,
    Expression<int>? personId,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (relationship != null) 'relationship': relationship,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (personId != null) 'person_id': personId,
    });
  }

  EmergencyContactsCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<String>? name,
    Value<String>? phoneNumber,
    Value<Relationship>? relationship,
    Value<bool>? isPrimary,
    Value<int>? personId,
  }) {
    return EmergencyContactsCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      personId: personId ?? this.personId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<int>(
        $EmergencyContactsTable.$converterrelationship.toSql(
          relationship.value,
        ),
      );
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactsCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('relationship: $relationship, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }
}

class $ServiceReportsTable extends ServiceReports
    with TableInfo<$ServiceReportsTable, ServiceReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAuxiliaryPioneerMeta =
      const VerificationMeta('isAuxiliaryPioneer');
  @override
  late final GeneratedColumn<bool> isAuxiliaryPioneer = GeneratedColumn<bool>(
    'is_auxiliary_pioneer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_auxiliary_pioneer" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sharedInMinistryMeta = const VerificationMeta(
    'sharedInMinistry',
  );
  @override
  late final GeneratedColumn<bool> sharedInMinistry = GeneratedColumn<bool>(
    'shared_in_ministry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shared_in_ministry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bibleStudiesMeta = const VerificationMeta(
    'bibleStudies',
  );
  @override
  late final GeneratedColumn<int> bibleStudies = GeneratedColumn<int>(
    'bible_studies',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    year,
    month,
    isAuxiliaryPioneer,
    isActive,
    sharedInMinistry,
    bibleStudies,
    hours,
    note,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('is_auxiliary_pioneer')) {
      context.handle(
        _isAuxiliaryPioneerMeta,
        isAuxiliaryPioneer.isAcceptableOrUnknown(
          data['is_auxiliary_pioneer']!,
          _isAuxiliaryPioneerMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('shared_in_ministry')) {
      context.handle(
        _sharedInMinistryMeta,
        sharedInMinistry.isAcceptableOrUnknown(
          data['shared_in_ministry']!,
          _sharedInMinistryMeta,
        ),
      );
    }
    if (data.containsKey('bible_studies')) {
      context.handle(
        _bibleStudiesMeta,
        bibleStudies.isAcceptableOrUnknown(
          data['bible_studies']!,
          _bibleStudiesMeta,
        ),
      );
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServiceReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceReport(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      isAuxiliaryPioneer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_auxiliary_pioneer'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      sharedInMinistry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shared_in_ministry'],
      )!,
      bibleStudies: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bible_studies'],
      )!,
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $ServiceReportsTable createAlias(String alias) {
    return $ServiceReportsTable(attachedDatabase, alias);
  }
}

class ServiceReport extends DataClass implements Insertable<ServiceReport> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final int year;
  final int month;
  final bool isAuxiliaryPioneer;
  final bool isActive;
  final bool sharedInMinistry;
  final int bibleStudies;
  final double hours;
  final String note;
  final int personId;
  const ServiceReport({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.year,
    required this.month,
    required this.isAuxiliaryPioneer,
    required this.isActive,
    required this.sharedInMinistry,
    required this.bibleStudies,
    required this.hours,
    required this.note,
    required this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['is_auxiliary_pioneer'] = Variable<bool>(isAuxiliaryPioneer);
    map['is_active'] = Variable<bool>(isActive);
    map['shared_in_ministry'] = Variable<bool>(sharedInMinistry);
    map['bible_studies'] = Variable<int>(bibleStudies);
    map['hours'] = Variable<double>(hours);
    map['note'] = Variable<String>(note);
    map['person_id'] = Variable<int>(personId);
    return map;
  }

  ServiceReportsCompanion toCompanion(bool nullToAbsent) {
    return ServiceReportsCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      year: Value(year),
      month: Value(month),
      isAuxiliaryPioneer: Value(isAuxiliaryPioneer),
      isActive: Value(isActive),
      sharedInMinistry: Value(sharedInMinistry),
      bibleStudies: Value(bibleStudies),
      hours: Value(hours),
      note: Value(note),
      personId: Value(personId),
    );
  }

  factory ServiceReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceReport(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      isAuxiliaryPioneer: serializer.fromJson<bool>(json['isAuxiliaryPioneer']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sharedInMinistry: serializer.fromJson<bool>(json['sharedInMinistry']),
      bibleStudies: serializer.fromJson<int>(json['bibleStudies']),
      hours: serializer.fromJson<double>(json['hours']),
      note: serializer.fromJson<String>(json['note']),
      personId: serializer.fromJson<int>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'isAuxiliaryPioneer': serializer.toJson<bool>(isAuxiliaryPioneer),
      'isActive': serializer.toJson<bool>(isActive),
      'sharedInMinistry': serializer.toJson<bool>(sharedInMinistry),
      'bibleStudies': serializer.toJson<int>(bibleStudies),
      'hours': serializer.toJson<double>(hours),
      'note': serializer.toJson<String>(note),
      'personId': serializer.toJson<int>(personId),
    };
  }

  ServiceReport copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    int? year,
    int? month,
    bool? isAuxiliaryPioneer,
    bool? isActive,
    bool? sharedInMinistry,
    int? bibleStudies,
    double? hours,
    String? note,
    int? personId,
  }) => ServiceReport(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    year: year ?? this.year,
    month: month ?? this.month,
    isAuxiliaryPioneer: isAuxiliaryPioneer ?? this.isAuxiliaryPioneer,
    isActive: isActive ?? this.isActive,
    sharedInMinistry: sharedInMinistry ?? this.sharedInMinistry,
    bibleStudies: bibleStudies ?? this.bibleStudies,
    hours: hours ?? this.hours,
    note: note ?? this.note,
    personId: personId ?? this.personId,
  );
  ServiceReport copyWithCompanion(ServiceReportsCompanion data) {
    return ServiceReport(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      isAuxiliaryPioneer: data.isAuxiliaryPioneer.present
          ? data.isAuxiliaryPioneer.value
          : this.isAuxiliaryPioneer,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sharedInMinistry: data.sharedInMinistry.present
          ? data.sharedInMinistry.value
          : this.sharedInMinistry,
      bibleStudies: data.bibleStudies.present
          ? data.bibleStudies.value
          : this.bibleStudies,
      hours: data.hours.present ? data.hours.value : this.hours,
      note: data.note.present ? data.note.value : this.note,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceReport(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('isAuxiliaryPioneer: $isAuxiliaryPioneer, ')
          ..write('isActive: $isActive, ')
          ..write('sharedInMinistry: $sharedInMinistry, ')
          ..write('bibleStudies: $bibleStudies, ')
          ..write('hours: $hours, ')
          ..write('note: $note, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    year,
    month,
    isAuxiliaryPioneer,
    isActive,
    sharedInMinistry,
    bibleStudies,
    hours,
    note,
    personId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceReport &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.isAuxiliaryPioneer == this.isAuxiliaryPioneer &&
          other.isActive == this.isActive &&
          other.sharedInMinistry == this.sharedInMinistry &&
          other.bibleStudies == this.bibleStudies &&
          other.hours == this.hours &&
          other.note == this.note &&
          other.personId == this.personId);
}

class ServiceReportsCompanion extends UpdateCompanion<ServiceReport> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<int> year;
  final Value<int> month;
  final Value<bool> isAuxiliaryPioneer;
  final Value<bool> isActive;
  final Value<bool> sharedInMinistry;
  final Value<int> bibleStudies;
  final Value<double> hours;
  final Value<String> note;
  final Value<int> personId;
  const ServiceReportsCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.isAuxiliaryPioneer = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sharedInMinistry = const Value.absent(),
    this.bibleStudies = const Value.absent(),
    this.hours = const Value.absent(),
    this.note = const Value.absent(),
    this.personId = const Value.absent(),
  });
  ServiceReportsCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int year,
    required int month,
    this.isAuxiliaryPioneer = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sharedInMinistry = const Value.absent(),
    this.bibleStudies = const Value.absent(),
    this.hours = const Value.absent(),
    this.note = const Value.absent(),
    required int personId,
  }) : year = Value(year),
       month = Value(month),
       personId = Value(personId);
  static Insertable<ServiceReport> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<bool>? isAuxiliaryPioneer,
    Expression<bool>? isActive,
    Expression<bool>? sharedInMinistry,
    Expression<int>? bibleStudies,
    Expression<double>? hours,
    Expression<String>? note,
    Expression<int>? personId,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (isAuxiliaryPioneer != null)
        'is_auxiliary_pioneer': isAuxiliaryPioneer,
      if (isActive != null) 'is_active': isActive,
      if (sharedInMinistry != null) 'shared_in_ministry': sharedInMinistry,
      if (bibleStudies != null) 'bible_studies': bibleStudies,
      if (hours != null) 'hours': hours,
      if (note != null) 'note': note,
      if (personId != null) 'person_id': personId,
    });
  }

  ServiceReportsCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<int>? year,
    Value<int>? month,
    Value<bool>? isAuxiliaryPioneer,
    Value<bool>? isActive,
    Value<bool>? sharedInMinistry,
    Value<int>? bibleStudies,
    Value<double>? hours,
    Value<String>? note,
    Value<int>? personId,
  }) {
    return ServiceReportsCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      isAuxiliaryPioneer: isAuxiliaryPioneer ?? this.isAuxiliaryPioneer,
      isActive: isActive ?? this.isActive,
      sharedInMinistry: sharedInMinistry ?? this.sharedInMinistry,
      bibleStudies: bibleStudies ?? this.bibleStudies,
      hours: hours ?? this.hours,
      note: note ?? this.note,
      personId: personId ?? this.personId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (isAuxiliaryPioneer.present) {
      map['is_auxiliary_pioneer'] = Variable<bool>(isAuxiliaryPioneer.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sharedInMinistry.present) {
      map['shared_in_ministry'] = Variable<bool>(sharedInMinistry.value);
    }
    if (bibleStudies.present) {
      map['bible_studies'] = Variable<int>(bibleStudies.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceReportsCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('isAuxiliaryPioneer: $isAuxiliaryPioneer, ')
          ..write('isActive: $isActive, ')
          ..write('sharedInMinistry: $sharedInMinistry, ')
          ..write('bibleStudies: $bibleStudies, ')
          ..write('hours: $hours, ')
          ..write('note: $note, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }
}

class $AuxiliaryPioneerPeriodsTable extends AuxiliaryPioneerPeriods
    with TableInfo<$AuxiliaryPioneerPeriodsTable, AuxiliaryPioneerPeriod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuxiliaryPioneerPeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta(
    'startMonth',
  );
  @override
  late final GeneratedColumn<int> startMonth = GeneratedColumn<int>(
    'start_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startYearMeta = const VerificationMeta(
    'startYear',
  );
  @override
  late final GeneratedColumn<int> startYear = GeneratedColumn<int>(
    'start_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMonthMeta = const VerificationMeta(
    'endMonth',
  );
  @override
  late final GeneratedColumn<int> endMonth = GeneratedColumn<int>(
    'end_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endYearMeta = const VerificationMeta(
    'endYear',
  );
  @override
  late final GeneratedColumn<int> endYear = GeneratedColumn<int>(
    'end_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    startMonth,
    startYear,
    endMonth,
    endYear,
    personId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auxiliary_pioneer_periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuxiliaryPioneerPeriod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_month')) {
      context.handle(
        _startMonthMeta,
        startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_startMonthMeta);
    }
    if (data.containsKey('start_year')) {
      context.handle(
        _startYearMeta,
        startYear.isAcceptableOrUnknown(data['start_year']!, _startYearMeta),
      );
    } else if (isInserting) {
      context.missing(_startYearMeta);
    }
    if (data.containsKey('end_month')) {
      context.handle(
        _endMonthMeta,
        endMonth.isAcceptableOrUnknown(data['end_month']!, _endMonthMeta),
      );
    }
    if (data.containsKey('end_year')) {
      context.handle(
        _endYearMeta,
        endYear.isAcceptableOrUnknown(data['end_year']!, _endYearMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuxiliaryPioneerPeriod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuxiliaryPioneerPeriod(
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_month'],
      )!,
      startYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_year'],
      )!,
      endMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_month'],
      ),
      endYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_year'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
    );
  }

  @override
  $AuxiliaryPioneerPeriodsTable createAlias(String alias) {
    return $AuxiliaryPioneerPeriodsTable(attachedDatabase, alias);
  }
}

class AuxiliaryPioneerPeriod extends DataClass
    implements Insertable<AuxiliaryPioneerPeriod> {
  final String? syncId;
  final int serverVersion;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final int id;
  final int startMonth;
  final int startYear;
  final int? endMonth;
  final int? endYear;
  final int personId;
  const AuxiliaryPioneerPeriod({
    this.syncId,
    required this.serverVersion,
    this.deletedAt,
    this.lastSyncedAt,
    required this.id,
    required this.startMonth,
    required this.startYear,
    this.endMonth,
    this.endYear,
    required this.personId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['server_version'] = Variable<int>(serverVersion);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['id'] = Variable<int>(id);
    map['start_month'] = Variable<int>(startMonth);
    map['start_year'] = Variable<int>(startYear);
    if (!nullToAbsent || endMonth != null) {
      map['end_month'] = Variable<int>(endMonth);
    }
    if (!nullToAbsent || endYear != null) {
      map['end_year'] = Variable<int>(endYear);
    }
    map['person_id'] = Variable<int>(personId);
    return map;
  }

  AuxiliaryPioneerPeriodsCompanion toCompanion(bool nullToAbsent) {
    return AuxiliaryPioneerPeriodsCompanion(
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      serverVersion: Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      id: Value(id),
      startMonth: Value(startMonth),
      startYear: Value(startYear),
      endMonth: endMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(endMonth),
      endYear: endYear == null && nullToAbsent
          ? const Value.absent()
          : Value(endYear),
      personId: Value(personId),
    );
  }

  factory AuxiliaryPioneerPeriod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuxiliaryPioneerPeriod(
      syncId: serializer.fromJson<String?>(json['syncId']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      id: serializer.fromJson<int>(json['id']),
      startMonth: serializer.fromJson<int>(json['startMonth']),
      startYear: serializer.fromJson<int>(json['startYear']),
      endMonth: serializer.fromJson<int?>(json['endMonth']),
      endYear: serializer.fromJson<int?>(json['endYear']),
      personId: serializer.fromJson<int>(json['personId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncId': serializer.toJson<String?>(syncId),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'id': serializer.toJson<int>(id),
      'startMonth': serializer.toJson<int>(startMonth),
      'startYear': serializer.toJson<int>(startYear),
      'endMonth': serializer.toJson<int?>(endMonth),
      'endYear': serializer.toJson<int?>(endYear),
      'personId': serializer.toJson<int>(personId),
    };
  }

  AuxiliaryPioneerPeriod copyWith({
    Value<String?> syncId = const Value.absent(),
    int? serverVersion,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? id,
    int? startMonth,
    int? startYear,
    Value<int?> endMonth = const Value.absent(),
    Value<int?> endYear = const Value.absent(),
    int? personId,
  }) => AuxiliaryPioneerPeriod(
    syncId: syncId.present ? syncId.value : this.syncId,
    serverVersion: serverVersion ?? this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    id: id ?? this.id,
    startMonth: startMonth ?? this.startMonth,
    startYear: startYear ?? this.startYear,
    endMonth: endMonth.present ? endMonth.value : this.endMonth,
    endYear: endYear.present ? endYear.value : this.endYear,
    personId: personId ?? this.personId,
  );
  AuxiliaryPioneerPeriod copyWithCompanion(
    AuxiliaryPioneerPeriodsCompanion data,
  ) {
    return AuxiliaryPioneerPeriod(
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      id: data.id.present ? data.id.value : this.id,
      startMonth: data.startMonth.present
          ? data.startMonth.value
          : this.startMonth,
      startYear: data.startYear.present ? data.startYear.value : this.startYear,
      endMonth: data.endMonth.present ? data.endMonth.value : this.endMonth,
      endYear: data.endYear.present ? data.endYear.value : this.endYear,
      personId: data.personId.present ? data.personId.value : this.personId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuxiliaryPioneerPeriod(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('startMonth: $startMonth, ')
          ..write('startYear: $startYear, ')
          ..write('endMonth: $endMonth, ')
          ..write('endYear: $endYear, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    syncId,
    serverVersion,
    deletedAt,
    lastSyncedAt,
    id,
    startMonth,
    startYear,
    endMonth,
    endYear,
    personId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuxiliaryPioneerPeriod &&
          other.syncId == this.syncId &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.id == this.id &&
          other.startMonth == this.startMonth &&
          other.startYear == this.startYear &&
          other.endMonth == this.endMonth &&
          other.endYear == this.endYear &&
          other.personId == this.personId);
}

class AuxiliaryPioneerPeriodsCompanion
    extends UpdateCompanion<AuxiliaryPioneerPeriod> {
  final Value<String?> syncId;
  final Value<int> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> id;
  final Value<int> startMonth;
  final Value<int> startYear;
  final Value<int?> endMonth;
  final Value<int?> endYear;
  final Value<int> personId;
  const AuxiliaryPioneerPeriodsCompanion({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.startYear = const Value.absent(),
    this.endMonth = const Value.absent(),
    this.endYear = const Value.absent(),
    this.personId = const Value.absent(),
  });
  AuxiliaryPioneerPeriodsCompanion.insert({
    this.syncId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.id = const Value.absent(),
    required int startMonth,
    required int startYear,
    this.endMonth = const Value.absent(),
    this.endYear = const Value.absent(),
    required int personId,
  }) : startMonth = Value(startMonth),
       startYear = Value(startYear),
       personId = Value(personId);
  static Insertable<AuxiliaryPioneerPeriod> custom({
    Expression<String>? syncId,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? id,
    Expression<int>? startMonth,
    Expression<int>? startYear,
    Expression<int>? endMonth,
    Expression<int>? endYear,
    Expression<int>? personId,
  }) {
    return RawValuesInsertable({
      if (syncId != null) 'sync_id': syncId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (id != null) 'id': id,
      if (startMonth != null) 'start_month': startMonth,
      if (startYear != null) 'start_year': startYear,
      if (endMonth != null) 'end_month': endMonth,
      if (endYear != null) 'end_year': endYear,
      if (personId != null) 'person_id': personId,
    });
  }

  AuxiliaryPioneerPeriodsCompanion copyWith({
    Value<String?>? syncId,
    Value<int>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? id,
    Value<int>? startMonth,
    Value<int>? startYear,
    Value<int?>? endMonth,
    Value<int?>? endYear,
    Value<int>? personId,
  }) {
    return AuxiliaryPioneerPeriodsCompanion(
      syncId: syncId ?? this.syncId,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      id: id ?? this.id,
      startMonth: startMonth ?? this.startMonth,
      startYear: startYear ?? this.startYear,
      endMonth: endMonth ?? this.endMonth,
      endYear: endYear ?? this.endYear,
      personId: personId ?? this.personId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<int>(startMonth.value);
    }
    if (startYear.present) {
      map['start_year'] = Variable<int>(startYear.value);
    }
    if (endMonth.present) {
      map['end_month'] = Variable<int>(endMonth.value);
    }
    if (endYear.present) {
      map['end_year'] = Variable<int>(endYear.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuxiliaryPioneerPeriodsCompanion(')
          ..write('syncId: $syncId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('id: $id, ')
          ..write('startMonth: $startMonth, ')
          ..write('startYear: $startYear, ')
          ..write('endMonth: $endMonth, ')
          ..write('endYear: $endYear, ')
          ..write('personId: $personId')
          ..write(')'))
        .toString();
  }
}

class $SyncSettingsTable extends SyncSettings
    with TableInfo<$SyncSettingsTable, SyncSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bearerTokenMeta = const VerificationMeta(
    'bearerToken',
  );
  @override
  late final GeneratedColumn<String> bearerToken = GeneratedColumn<String>(
    'bearer_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pullCursorMeta = const VerificationMeta(
    'pullCursor',
  );
  @override
  late final GeneratedColumn<String> pullCursor = GeneratedColumn<String>(
    'pull_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isEnabled,
    serverUrl,
    bearerToken,
    deviceId,
    pullCursor,
    lastSyncAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    }
    if (data.containsKey('bearer_token')) {
      context.handle(
        _bearerTokenMeta,
        bearerToken.isAcceptableOrUnknown(
          data['bearer_token']!,
          _bearerTokenMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('pull_cursor')) {
      context.handle(
        _pullCursorMeta,
        pullCursor.isAcceptableOrUnknown(data['pull_cursor']!, _pullCursorMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      ),
      bearerToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bearer_token'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      pullCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pull_cursor'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncSettingsTable createAlias(String alias) {
    return $SyncSettingsTable(attachedDatabase, alias);
  }
}

class SyncSetting extends DataClass implements Insertable<SyncSetting> {
  final int id;
  final bool isEnabled;
  final String? serverUrl;
  final String? bearerToken;
  final String? deviceId;
  final String? pullCursor;
  final DateTime? lastSyncAt;
  final String? lastError;
  const SyncSetting({
    required this.id,
    required this.isEnabled,
    this.serverUrl,
    this.bearerToken,
    this.deviceId,
    this.pullCursor,
    this.lastSyncAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || serverUrl != null) {
      map['server_url'] = Variable<String>(serverUrl);
    }
    if (!nullToAbsent || bearerToken != null) {
      map['bearer_token'] = Variable<String>(bearerToken);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || pullCursor != null) {
      map['pull_cursor'] = Variable<String>(pullCursor);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncSettingsCompanion toCompanion(bool nullToAbsent) {
    return SyncSettingsCompanion(
      id: Value(id),
      isEnabled: Value(isEnabled),
      serverUrl: serverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUrl),
      bearerToken: bearerToken == null && nullToAbsent
          ? const Value.absent()
          : Value(bearerToken),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      pullCursor: pullCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(pullCursor),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSetting(
      id: serializer.fromJson<int>(json['id']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      serverUrl: serializer.fromJson<String?>(json['serverUrl']),
      bearerToken: serializer.fromJson<String?>(json['bearerToken']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      pullCursor: serializer.fromJson<String?>(json['pullCursor']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'serverUrl': serializer.toJson<String?>(serverUrl),
      'bearerToken': serializer.toJson<String?>(bearerToken),
      'deviceId': serializer.toJson<String?>(deviceId),
      'pullCursor': serializer.toJson<String?>(pullCursor),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncSetting copyWith({
    int? id,
    bool? isEnabled,
    Value<String?> serverUrl = const Value.absent(),
    Value<String?> bearerToken = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> pullCursor = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncSetting(
    id: id ?? this.id,
    isEnabled: isEnabled ?? this.isEnabled,
    serverUrl: serverUrl.present ? serverUrl.value : this.serverUrl,
    bearerToken: bearerToken.present ? bearerToken.value : this.bearerToken,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    pullCursor: pullCursor.present ? pullCursor.value : this.pullCursor,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncSetting copyWithCompanion(SyncSettingsCompanion data) {
    return SyncSetting(
      id: data.id.present ? data.id.value : this.id,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      bearerToken: data.bearerToken.present
          ? data.bearerToken.value
          : this.bearerToken,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      pullCursor: data.pullCursor.present
          ? data.pullCursor.value
          : this.pullCursor,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSetting(')
          ..write('id: $id, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('bearerToken: $bearerToken, ')
          ..write('deviceId: $deviceId, ')
          ..write('pullCursor: $pullCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isEnabled,
    serverUrl,
    bearerToken,
    deviceId,
    pullCursor,
    lastSyncAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSetting &&
          other.id == this.id &&
          other.isEnabled == this.isEnabled &&
          other.serverUrl == this.serverUrl &&
          other.bearerToken == this.bearerToken &&
          other.deviceId == this.deviceId &&
          other.pullCursor == this.pullCursor &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastError == this.lastError);
}

class SyncSettingsCompanion extends UpdateCompanion<SyncSetting> {
  final Value<int> id;
  final Value<bool> isEnabled;
  final Value<String?> serverUrl;
  final Value<String?> bearerToken;
  final Value<String?> deviceId;
  final Value<String?> pullCursor;
  final Value<DateTime?> lastSyncAt;
  final Value<String?> lastError;
  const SyncSettingsCompanion({
    this.id = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.bearerToken = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pullCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.bearerToken = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.pullCursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  static Insertable<SyncSetting> custom({
    Expression<int>? id,
    Expression<bool>? isEnabled,
    Expression<String>? serverUrl,
    Expression<String>? bearerToken,
    Expression<String>? deviceId,
    Expression<String>? pullCursor,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (serverUrl != null) 'server_url': serverUrl,
      if (bearerToken != null) 'bearer_token': bearerToken,
      if (deviceId != null) 'device_id': deviceId,
      if (pullCursor != null) 'pull_cursor': pullCursor,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? isEnabled,
    Value<String?>? serverUrl,
    Value<String?>? bearerToken,
    Value<String?>? deviceId,
    Value<String?>? pullCursor,
    Value<DateTime?>? lastSyncAt,
    Value<String?>? lastError,
  }) {
    return SyncSettingsCompanion(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      bearerToken: bearerToken ?? this.bearerToken,
      deviceId: deviceId ?? this.deviceId,
      pullCursor: pullCursor ?? this.pullCursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (bearerToken.present) {
      map['bearer_token'] = Variable<String>(bearerToken.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (pullCursor.present) {
      map['pull_cursor'] = Variable<String>(pullCursor.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSettingsCompanion(')
          ..write('id: $id, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('bearerToken: $bearerToken, ')
          ..write('deviceId: $deviceId, ')
          ..write('pullCursor: $pullCursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncOperationsTable extends PendingSyncOperations
    with TableInfo<$PendingSyncOperationsTable, PendingSyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entitySyncIdMeta = const VerificationMeta(
    'entitySyncId',
  );
  @override
  late final GeneratedColumn<String> entitySyncId = GeneratedColumn<String>(
    'entity_sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseServerVersionMeta = const VerificationMeta(
    'baseServerVersion',
  );
  @override
  late final GeneratedColumn<int> baseServerVersion = GeneratedColumn<int>(
    'base_server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationId,
    entityType,
    entitySyncId,
    operationType,
    payloadJson,
    baseServerVersion,
    createdAt,
    lastAttemptAt,
    attemptCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_sync_id')) {
      context.handle(
        _entitySyncIdMeta,
        entitySyncId.isAcceptableOrUnknown(
          data['entity_sync_id']!,
          _entitySyncIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entitySyncIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_server_version')) {
      context.handle(
        _baseServerVersionMeta,
        baseServerVersion.isAcceptableOrUnknown(
          data['base_server_version']!,
          _baseServerVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entitySyncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_sync_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      baseServerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_server_version'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $PendingSyncOperationsTable createAlias(String alias) {
    return $PendingSyncOperationsTable(attachedDatabase, alias);
  }
}

class PendingSyncOperation extends DataClass
    implements Insertable<PendingSyncOperation> {
  final int id;
  final String operationId;
  final String entityType;
  final String entitySyncId;
  final String operationType;
  final String payloadJson;
  final int? baseServerVersion;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? lastError;
  const PendingSyncOperation({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.entitySyncId,
    required this.operationType,
    required this.payloadJson,
    this.baseServerVersion,
    required this.createdAt,
    this.lastAttemptAt,
    required this.attemptCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_id'] = Variable<String>(operationId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_sync_id'] = Variable<String>(entitySyncId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || baseServerVersion != null) {
      map['base_server_version'] = Variable<int>(baseServerVersion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingSyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncOperationsCompanion(
      id: Value(id),
      operationId: Value(operationId),
      entityType: Value(entityType),
      entitySyncId: Value(entitySyncId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      baseServerVersion: baseServerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseServerVersion),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingSyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncOperation(
      id: serializer.fromJson<int>(json['id']),
      operationId: serializer.fromJson<String>(json['operationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entitySyncId: serializer.fromJson<String>(json['entitySyncId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseServerVersion: serializer.fromJson<int?>(json['baseServerVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationId': serializer.toJson<String>(operationId),
      'entityType': serializer.toJson<String>(entityType),
      'entitySyncId': serializer.toJson<String>(entitySyncId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseServerVersion': serializer.toJson<int?>(baseServerVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingSyncOperation copyWith({
    int? id,
    String? operationId,
    String? entityType,
    String? entitySyncId,
    String? operationType,
    String? payloadJson,
    Value<int?> baseServerVersion = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
  }) => PendingSyncOperation(
    id: id ?? this.id,
    operationId: operationId ?? this.operationId,
    entityType: entityType ?? this.entityType,
    entitySyncId: entitySyncId ?? this.entitySyncId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    baseServerVersion: baseServerVersion.present
        ? baseServerVersion.value
        : this.baseServerVersion,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  PendingSyncOperation copyWithCompanion(PendingSyncOperationsCompanion data) {
    return PendingSyncOperation(
      id: data.id.present ? data.id.value : this.id,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entitySyncId: data.entitySyncId.present
          ? data.entitySyncId.value
          : this.entitySyncId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      baseServerVersion: data.baseServerVersion.present
          ? data.baseServerVersion.value
          : this.baseServerVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOperation(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('entitySyncId: $entitySyncId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationId,
    entityType,
    entitySyncId,
    operationType,
    payloadJson,
    baseServerVersion,
    createdAt,
    lastAttemptAt,
    attemptCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncOperation &&
          other.id == this.id &&
          other.operationId == this.operationId &&
          other.entityType == this.entityType &&
          other.entitySyncId == this.entitySyncId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.baseServerVersion == this.baseServerVersion &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError);
}

class PendingSyncOperationsCompanion
    extends UpdateCompanion<PendingSyncOperation> {
  final Value<int> id;
  final Value<String> operationId;
  final Value<String> entityType;
  final Value<String> entitySyncId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<int?> baseServerVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  const PendingSyncOperationsCompanion({
    this.id = const Value.absent(),
    this.operationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entitySyncId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseServerVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  PendingSyncOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String operationId,
    required String entityType,
    required String entitySyncId,
    required String operationType,
    required String payloadJson,
    this.baseServerVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : operationId = Value(operationId),
       entityType = Value(entityType),
       entitySyncId = Value(entitySyncId),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson);
  static Insertable<PendingSyncOperation> custom({
    Expression<int>? id,
    Expression<String>? operationId,
    Expression<String>? entityType,
    Expression<String>? entitySyncId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<int>? baseServerVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationId != null) 'operation_id': operationId,
      if (entityType != null) 'entity_type': entityType,
      if (entitySyncId != null) 'entity_sync_id': entitySyncId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseServerVersion != null) 'base_server_version': baseServerVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
    });
  }

  PendingSyncOperationsCompanion copyWith({
    Value<int>? id,
    Value<String>? operationId,
    Value<String>? entityType,
    Value<String>? entitySyncId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<int?>? baseServerVersion,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? attemptCount,
    Value<String?>? lastError,
  }) {
    return PendingSyncOperationsCompanion(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entitySyncId: entitySyncId ?? this.entitySyncId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      baseServerVersion: baseServerVersion ?? this.baseServerVersion,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entitySyncId.present) {
      map['entity_sync_id'] = Variable<String>(entitySyncId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseServerVersion.present) {
      map['base_server_version'] = Variable<int>(baseServerVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('entitySyncId: $entitySyncId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseServerVersion: $baseServerVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entitySyncIdMeta = const VerificationMeta(
    'entitySyncId',
  );
  @override
  late final GeneratedColumn<String> entitySyncId = GeneratedColumn<String>(
    'entity_sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPayloadJsonMeta = const VerificationMeta(
    'localPayloadJson',
  );
  @override
  late final GeneratedColumn<String> localPayloadJson = GeneratedColumn<String>(
    'local_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverPayloadJsonMeta = const VerificationMeta(
    'serverPayloadJson',
  );
  @override
  late final GeneratedColumn<String> serverPayloadJson =
      GeneratedColumn<String>(
        'server_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entitySyncId,
    localPayloadJson,
    serverPayloadJson,
    serverVersion,
    createdAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflict> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_sync_id')) {
      context.handle(
        _entitySyncIdMeta,
        entitySyncId.isAcceptableOrUnknown(
          data['entity_sync_id']!,
          _entitySyncIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entitySyncIdMeta);
    }
    if (data.containsKey('local_payload_json')) {
      context.handle(
        _localPayloadJsonMeta,
        localPayloadJson.isAcceptableOrUnknown(
          data['local_payload_json']!,
          _localPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localPayloadJsonMeta);
    }
    if (data.containsKey('server_payload_json')) {
      context.handle(
        _serverPayloadJsonMeta,
        serverPayloadJson.isAcceptableOrUnknown(
          data['server_payload_json']!,
          _serverPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverPayloadJsonMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflict(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entitySyncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_sync_id'],
      )!,
      localPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_payload_json'],
      )!,
      serverPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_payload_json'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }
}

class SyncConflict extends DataClass implements Insertable<SyncConflict> {
  final int id;
  final String entityType;
  final String entitySyncId;
  final String localPayloadJson;
  final String serverPayloadJson;
  final int serverVersion;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  const SyncConflict({
    required this.id,
    required this.entityType,
    required this.entitySyncId,
    required this.localPayloadJson,
    required this.serverPayloadJson,
    required this.serverVersion,
    required this.createdAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_sync_id'] = Variable<String>(entitySyncId);
    map['local_payload_json'] = Variable<String>(localPayloadJson);
    map['server_payload_json'] = Variable<String>(serverPayloadJson);
    map['server_version'] = Variable<int>(serverVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entitySyncId: Value(entitySyncId),
      localPayloadJson: Value(localPayloadJson),
      serverPayloadJson: Value(serverPayloadJson),
      serverVersion: Value(serverVersion),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory SyncConflict.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflict(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entitySyncId: serializer.fromJson<String>(json['entitySyncId']),
      localPayloadJson: serializer.fromJson<String>(json['localPayloadJson']),
      serverPayloadJson: serializer.fromJson<String>(json['serverPayloadJson']),
      serverVersion: serializer.fromJson<int>(json['serverVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entitySyncId': serializer.toJson<String>(entitySyncId),
      'localPayloadJson': serializer.toJson<String>(localPayloadJson),
      'serverPayloadJson': serializer.toJson<String>(serverPayloadJson),
      'serverVersion': serializer.toJson<int>(serverVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  SyncConflict copyWith({
    int? id,
    String? entityType,
    String? entitySyncId,
    String? localPayloadJson,
    String? serverPayloadJson,
    int? serverVersion,
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => SyncConflict(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entitySyncId: entitySyncId ?? this.entitySyncId,
    localPayloadJson: localPayloadJson ?? this.localPayloadJson,
    serverPayloadJson: serverPayloadJson ?? this.serverPayloadJson,
    serverVersion: serverVersion ?? this.serverVersion,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  SyncConflict copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflict(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entitySyncId: data.entitySyncId.present
          ? data.entitySyncId.value
          : this.entitySyncId,
      localPayloadJson: data.localPayloadJson.present
          ? data.localPayloadJson.value
          : this.localPayloadJson,
      serverPayloadJson: data.serverPayloadJson.present
          ? data.serverPayloadJson.value
          : this.serverPayloadJson,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflict(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entitySyncId: $entitySyncId, ')
          ..write('localPayloadJson: $localPayloadJson, ')
          ..write('serverPayloadJson: $serverPayloadJson, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entitySyncId,
    localPayloadJson,
    serverPayloadJson,
    serverVersion,
    createdAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entitySyncId == this.entitySyncId &&
          other.localPayloadJson == this.localPayloadJson &&
          other.serverPayloadJson == this.serverPayloadJson &&
          other.serverVersion == this.serverVersion &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflict> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entitySyncId;
  final Value<String> localPayloadJson;
  final Value<String> serverPayloadJson;
  final Value<int> serverVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entitySyncId = const Value.absent(),
    this.localPayloadJson = const Value.absent(),
    this.serverPayloadJson = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entitySyncId,
    required String localPayloadJson,
    required String serverPayloadJson,
    required int serverVersion,
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
  }) : entityType = Value(entityType),
       entitySyncId = Value(entitySyncId),
       localPayloadJson = Value(localPayloadJson),
       serverPayloadJson = Value(serverPayloadJson),
       serverVersion = Value(serverVersion);
  static Insertable<SyncConflict> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entitySyncId,
    Expression<String>? localPayloadJson,
    Expression<String>? serverPayloadJson,
    Expression<int>? serverVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entitySyncId != null) 'entity_sync_id': entitySyncId,
      if (localPayloadJson != null) 'local_payload_json': localPayloadJson,
      if (serverPayloadJson != null) 'server_payload_json': serverPayloadJson,
      if (serverVersion != null) 'server_version': serverVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entitySyncId,
    Value<String>? localPayloadJson,
    Value<String>? serverPayloadJson,
    Value<int>? serverVersion,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
  }) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entitySyncId: entitySyncId ?? this.entitySyncId,
      localPayloadJson: localPayloadJson ?? this.localPayloadJson,
      serverPayloadJson: serverPayloadJson ?? this.serverPayloadJson,
      serverVersion: serverVersion ?? this.serverVersion,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entitySyncId.present) {
      map['entity_sync_id'] = Variable<String>(entitySyncId.value);
    }
    if (localPayloadJson.present) {
      map['local_payload_json'] = Variable<String>(localPayloadJson.value);
    }
    if (serverPayloadJson.present) {
      map['server_payload_json'] = Variable<String>(serverPayloadJson.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entitySyncId: $entitySyncId, ')
          ..write('localPayloadJson: $localPayloadJson, ')
          ..write('serverPayloadJson: $serverPayloadJson, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CongregationsTable congregations = $CongregationsTable(this);
  late final $FieldServiceGroupsTable fieldServiceGroups =
      $FieldServiceGroupsTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $PhoneNumbersTable phoneNumbers = $PhoneNumbersTable(this);
  late final $EmergencyContactsTable emergencyContacts =
      $EmergencyContactsTable(this);
  late final $ServiceReportsTable serviceReports = $ServiceReportsTable(this);
  late final $AuxiliaryPioneerPeriodsTable auxiliaryPioneerPeriods =
      $AuxiliaryPioneerPeriodsTable(this);
  late final $SyncSettingsTable syncSettings = $SyncSettingsTable(this);
  late final $PendingSyncOperationsTable pendingSyncOperations =
      $PendingSyncOperationsTable(this);
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    congregations,
    fieldServiceGroups,
    persons,
    phoneNumbers,
    emergencyContacts,
    serviceReports,
    auxiliaryPioneerPeriods,
    syncSettings,
    pendingSyncOperations,
    syncConflicts,
  ];
}

typedef $$CongregationsTableCreateCompanionBuilder =
    CongregationsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> name,
      Value<String> number,
      Value<String> city,
      Value<String> circuitNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CongregationsTableUpdateCompanionBuilder =
    CongregationsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> name,
      Value<String> number,
      Value<String> city,
      Value<String> circuitNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CongregationsTableReferences
    extends BaseReferences<_$AppDatabase, $CongregationsTable, Congregation> {
  $$CongregationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FieldServiceGroupsTable, List<FieldServiceGroup>>
  _fieldServiceGroupsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.fieldServiceGroups,
        aliasName: $_aliasNameGenerator(
          db.congregations.id,
          db.fieldServiceGroups.congregationId,
        ),
      );

  $$FieldServiceGroupsTableProcessedTableManager get fieldServiceGroupsRefs {
    final manager = $$FieldServiceGroupsTableTableManager(
      $_db,
      $_db.fieldServiceGroups,
    ).filter((f) => f.congregationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fieldServiceGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonsTable, List<Person>> _personsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.persons,
    aliasName: $_aliasNameGenerator(
      db.congregations.id,
      db.persons.congregationId,
    ),
  );

  $$PersonsTableProcessedTableManager get personsRefs {
    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.congregationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_personsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CongregationsTableFilterComposer
    extends Composer<_$AppDatabase, $CongregationsTable> {
  $$CongregationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get circuitNumber => $composableBuilder(
    column: $table.circuitNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fieldServiceGroupsRefs(
    Expression<bool> Function($$FieldServiceGroupsTableFilterComposer f) f,
  ) {
    final $$FieldServiceGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fieldServiceGroups,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldServiceGroupsTableFilterComposer(
            $db: $db,
            $table: $db.fieldServiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personsRefs(
    Expression<bool> Function($$PersonsTableFilterComposer f) f,
  ) {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CongregationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CongregationsTable> {
  $$CongregationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get circuitNumber => $composableBuilder(
    column: $table.circuitNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CongregationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CongregationsTable> {
  $$CongregationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get circuitNumber => $composableBuilder(
    column: $table.circuitNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> fieldServiceGroupsRefs<T extends Object>(
    Expression<T> Function($$FieldServiceGroupsTableAnnotationComposer a) f,
  ) {
    final $$FieldServiceGroupsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fieldServiceGroups,
          getReferencedColumn: (t) => t.congregationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FieldServiceGroupsTableAnnotationComposer(
                $db: $db,
                $table: $db.fieldServiceGroups,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> personsRefs<T extends Object>(
    Expression<T> Function($$PersonsTableAnnotationComposer a) f,
  ) {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.congregationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CongregationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CongregationsTable,
          Congregation,
          $$CongregationsTableFilterComposer,
          $$CongregationsTableOrderingComposer,
          $$CongregationsTableAnnotationComposer,
          $$CongregationsTableCreateCompanionBuilder,
          $$CongregationsTableUpdateCompanionBuilder,
          (Congregation, $$CongregationsTableReferences),
          Congregation,
          PrefetchHooks Function({
            bool fieldServiceGroupsRefs,
            bool personsRefs,
          })
        > {
  $$CongregationsTableTableManager(_$AppDatabase db, $CongregationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CongregationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CongregationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CongregationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> circuitNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CongregationsCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                name: name,
                number: number,
                city: city,
                circuitNumber: circuitNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> circuitNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CongregationsCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                name: name,
                number: number,
                city: city,
                circuitNumber: circuitNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CongregationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({fieldServiceGroupsRefs = false, personsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (fieldServiceGroupsRefs) db.fieldServiceGroups,
                    if (personsRefs) db.persons,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (fieldServiceGroupsRefs)
                        await $_getPrefetchedData<
                          Congregation,
                          $CongregationsTable,
                          FieldServiceGroup
                        >(
                          currentTable: table,
                          referencedTable: $$CongregationsTableReferences
                              ._fieldServiceGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CongregationsTableReferences(
                                db,
                                table,
                                p0,
                              ).fieldServiceGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.congregationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personsRefs)
                        await $_getPrefetchedData<
                          Congregation,
                          $CongregationsTable,
                          Person
                        >(
                          currentTable: table,
                          referencedTable: $$CongregationsTableReferences
                              ._personsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CongregationsTableReferences(
                                db,
                                table,
                                p0,
                              ).personsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.congregationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CongregationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CongregationsTable,
      Congregation,
      $$CongregationsTableFilterComposer,
      $$CongregationsTableOrderingComposer,
      $$CongregationsTableAnnotationComposer,
      $$CongregationsTableCreateCompanionBuilder,
      $$CongregationsTableUpdateCompanionBuilder,
      (Congregation, $$CongregationsTableReferences),
      Congregation,
      PrefetchHooks Function({bool fieldServiceGroupsRefs, bool personsRefs})
    >;
typedef $$FieldServiceGroupsTableCreateCompanionBuilder =
    FieldServiceGroupsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> name,
      Value<String> description,
      Value<int?> congregationId,
      Value<int?> groupOverseerId,
      Value<int?> assistantId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$FieldServiceGroupsTableUpdateCompanionBuilder =
    FieldServiceGroupsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> name,
      Value<String> description,
      Value<int?> congregationId,
      Value<int?> groupOverseerId,
      Value<int?> assistantId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$FieldServiceGroupsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FieldServiceGroupsTable,
          FieldServiceGroup
        > {
  $$FieldServiceGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CongregationsTable _congregationIdTable(_$AppDatabase db) =>
      db.congregations.createAlias(
        $_aliasNameGenerator(
          db.fieldServiceGroups.congregationId,
          db.congregations.id,
        ),
      );

  $$CongregationsTableProcessedTableManager? get congregationId {
    final $_column = $_itemColumn<int>('congregation_id');
    if ($_column == null) return null;
    final manager = $$CongregationsTableTableManager(
      $_db,
      $_db.congregations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_congregationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PersonsTable, List<Person>> _personsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.persons,
    aliasName: $_aliasNameGenerator(
      db.fieldServiceGroups.id,
      db.persons.fieldServiceGroupId,
    ),
  );

  $$PersonsTableProcessedTableManager get personsRefs {
    final manager = $$PersonsTableTableManager($_db, $_db.persons).filter(
      (f) => f.fieldServiceGroupId.id.sqlEquals($_itemColumn<int>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_personsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FieldServiceGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $FieldServiceGroupsTable> {
  $$FieldServiceGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupOverseerId => $composableBuilder(
    column: $table.groupOverseerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assistantId => $composableBuilder(
    column: $table.assistantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CongregationsTableFilterComposer get congregationId {
    final $$CongregationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableFilterComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> personsRefs(
    Expression<bool> Function($$PersonsTableFilterComposer f) f,
  ) {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.fieldServiceGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FieldServiceGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $FieldServiceGroupsTable> {
  $$FieldServiceGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupOverseerId => $composableBuilder(
    column: $table.groupOverseerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assistantId => $composableBuilder(
    column: $table.assistantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CongregationsTableOrderingComposer get congregationId {
    final $$CongregationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableOrderingComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FieldServiceGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FieldServiceGroupsTable> {
  $$FieldServiceGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get groupOverseerId => $composableBuilder(
    column: $table.groupOverseerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assistantId => $composableBuilder(
    column: $table.assistantId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CongregationsTableAnnotationComposer get congregationId {
    final $$CongregationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableAnnotationComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> personsRefs<T extends Object>(
    Expression<T> Function($$PersonsTableAnnotationComposer a) f,
  ) {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.fieldServiceGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FieldServiceGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FieldServiceGroupsTable,
          FieldServiceGroup,
          $$FieldServiceGroupsTableFilterComposer,
          $$FieldServiceGroupsTableOrderingComposer,
          $$FieldServiceGroupsTableAnnotationComposer,
          $$FieldServiceGroupsTableCreateCompanionBuilder,
          $$FieldServiceGroupsTableUpdateCompanionBuilder,
          (FieldServiceGroup, $$FieldServiceGroupsTableReferences),
          FieldServiceGroup,
          PrefetchHooks Function({bool congregationId, bool personsRefs})
        > {
  $$FieldServiceGroupsTableTableManager(
    _$AppDatabase db,
    $FieldServiceGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FieldServiceGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FieldServiceGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FieldServiceGroupsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> congregationId = const Value.absent(),
                Value<int?> groupOverseerId = const Value.absent(),
                Value<int?> assistantId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FieldServiceGroupsCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                name: name,
                description: description,
                congregationId: congregationId,
                groupOverseerId: groupOverseerId,
                assistantId: assistantId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> congregationId = const Value.absent(),
                Value<int?> groupOverseerId = const Value.absent(),
                Value<int?> assistantId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FieldServiceGroupsCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                name: name,
                description: description,
                congregationId: congregationId,
                groupOverseerId: groupOverseerId,
                assistantId: assistantId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FieldServiceGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({congregationId = false, personsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (personsRefs) db.persons],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (congregationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.congregationId,
                                    referencedTable:
                                        $$FieldServiceGroupsTableReferences
                                            ._congregationIdTable(db),
                                    referencedColumn:
                                        $$FieldServiceGroupsTableReferences
                                            ._congregationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personsRefs)
                        await $_getPrefetchedData<
                          FieldServiceGroup,
                          $FieldServiceGroupsTable,
                          Person
                        >(
                          currentTable: table,
                          referencedTable: $$FieldServiceGroupsTableReferences
                              ._personsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FieldServiceGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).personsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fieldServiceGroupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FieldServiceGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FieldServiceGroupsTable,
      FieldServiceGroup,
      $$FieldServiceGroupsTableFilterComposer,
      $$FieldServiceGroupsTableOrderingComposer,
      $$FieldServiceGroupsTableAnnotationComposer,
      $$FieldServiceGroupsTableCreateCompanionBuilder,
      $$FieldServiceGroupsTableUpdateCompanionBuilder,
      (FieldServiceGroup, $$FieldServiceGroupsTableReferences),
      FieldServiceGroup,
      PrefetchHooks Function({bool congregationId, bool personsRefs})
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> otherNames,
      Value<DateTime?> birthDate,
      Value<DateTime?> baptismDate,
      Value<Gender> gender,
      Value<HopeClass> hopeClass,
      Value<CongregationRole> congregationRole,
      Value<PioneerType> pioneerType,
      Value<String> address,
      Value<bool> isActive,
      Value<DateTime?> inactiveDate,
      Value<int?> congregationId,
      Value<int?> fieldServiceGroupId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> otherNames,
      Value<DateTime?> birthDate,
      Value<DateTime?> baptismDate,
      Value<Gender> gender,
      Value<HopeClass> hopeClass,
      Value<CongregationRole> congregationRole,
      Value<PioneerType> pioneerType,
      Value<String> address,
      Value<bool> isActive,
      Value<DateTime?> inactiveDate,
      Value<int?> congregationId,
      Value<int?> fieldServiceGroupId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PersonsTableReferences
    extends BaseReferences<_$AppDatabase, $PersonsTable, Person> {
  $$PersonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CongregationsTable _congregationIdTable(_$AppDatabase db) =>
      db.congregations.createAlias(
        $_aliasNameGenerator(db.persons.congregationId, db.congregations.id),
      );

  $$CongregationsTableProcessedTableManager? get congregationId {
    final $_column = $_itemColumn<int>('congregation_id');
    if ($_column == null) return null;
    final manager = $$CongregationsTableTableManager(
      $_db,
      $_db.congregations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_congregationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FieldServiceGroupsTable _fieldServiceGroupIdTable(_$AppDatabase db) =>
      db.fieldServiceGroups.createAlias(
        $_aliasNameGenerator(
          db.persons.fieldServiceGroupId,
          db.fieldServiceGroups.id,
        ),
      );

  $$FieldServiceGroupsTableProcessedTableManager? get fieldServiceGroupId {
    final $_column = $_itemColumn<int>('field_service_group_id');
    if ($_column == null) return null;
    final manager = $$FieldServiceGroupsTableTableManager(
      $_db,
      $_db.fieldServiceGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldServiceGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PhoneNumbersTable, List<PhoneNumber>>
  _phoneNumbersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.phoneNumbers,
    aliasName: $_aliasNameGenerator(db.persons.id, db.phoneNumbers.personId),
  );

  $$PhoneNumbersTableProcessedTableManager get phoneNumbersRefs {
    final manager = $$PhoneNumbersTableTableManager(
      $_db,
      $_db.phoneNumbers,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_phoneNumbersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EmergencyContactsTable, List<EmergencyContact>>
  _emergencyContactsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.emergencyContacts,
        aliasName: $_aliasNameGenerator(
          db.persons.id,
          db.emergencyContacts.personId,
        ),
      );

  $$EmergencyContactsTableProcessedTableManager get emergencyContactsRefs {
    final manager = $$EmergencyContactsTableTableManager(
      $_db,
      $_db.emergencyContacts,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _emergencyContactsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ServiceReportsTable, List<ServiceReport>>
  _serviceReportsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.serviceReports,
    aliasName: $_aliasNameGenerator(db.persons.id, db.serviceReports.personId),
  );

  $$ServiceReportsTableProcessedTableManager get serviceReportsRefs {
    final manager = $$ServiceReportsTableTableManager(
      $_db,
      $_db.serviceReports,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_serviceReportsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AuxiliaryPioneerPeriodsTable,
    List<AuxiliaryPioneerPeriod>
  >
  _auxiliaryPioneerPeriodsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.auxiliaryPioneerPeriods,
        aliasName: $_aliasNameGenerator(
          db.persons.id,
          db.auxiliaryPioneerPeriods.personId,
        ),
      );

  $$AuxiliaryPioneerPeriodsTableProcessedTableManager
  get auxiliaryPioneerPeriodsRefs {
    final manager = $$AuxiliaryPioneerPeriodsTableTableManager(
      $_db,
      $_db.auxiliaryPioneerPeriods,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _auxiliaryPioneerPeriodsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherNames => $composableBuilder(
    column: $table.otherNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get baptismDate => $composableBuilder(
    column: $table.baptismDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Gender, Gender, int> get gender =>
      $composableBuilder(
        column: $table.gender,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<HopeClass, HopeClass, int> get hopeClass =>
      $composableBuilder(
        column: $table.hopeClass,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CongregationRole, CongregationRole, int>
  get congregationRole => $composableBuilder(
    column: $table.congregationRole,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PioneerType, PioneerType, int>
  get pioneerType => $composableBuilder(
    column: $table.pioneerType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get inactiveDate => $composableBuilder(
    column: $table.inactiveDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CongregationsTableFilterComposer get congregationId {
    final $$CongregationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableFilterComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FieldServiceGroupsTableFilterComposer get fieldServiceGroupId {
    final $$FieldServiceGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fieldServiceGroupId,
      referencedTable: $db.fieldServiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldServiceGroupsTableFilterComposer(
            $db: $db,
            $table: $db.fieldServiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> phoneNumbersRefs(
    Expression<bool> Function($$PhoneNumbersTableFilterComposer f) f,
  ) {
    final $$PhoneNumbersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.phoneNumbers,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhoneNumbersTableFilterComposer(
            $db: $db,
            $table: $db.phoneNumbers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> emergencyContactsRefs(
    Expression<bool> Function($$EmergencyContactsTableFilterComposer f) f,
  ) {
    final $$EmergencyContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.emergencyContacts,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmergencyContactsTableFilterComposer(
            $db: $db,
            $table: $db.emergencyContacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> serviceReportsRefs(
    Expression<bool> Function($$ServiceReportsTableFilterComposer f) f,
  ) {
    final $$ServiceReportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.serviceReports,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceReportsTableFilterComposer(
            $db: $db,
            $table: $db.serviceReports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> auxiliaryPioneerPeriodsRefs(
    Expression<bool> Function($$AuxiliaryPioneerPeriodsTableFilterComposer f) f,
  ) {
    final $$AuxiliaryPioneerPeriodsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.auxiliaryPioneerPeriods,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AuxiliaryPioneerPeriodsTableFilterComposer(
                $db: $db,
                $table: $db.auxiliaryPioneerPeriods,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherNames => $composableBuilder(
    column: $table.otherNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get baptismDate => $composableBuilder(
    column: $table.baptismDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hopeClass => $composableBuilder(
    column: $table.hopeClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get congregationRole => $composableBuilder(
    column: $table.congregationRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pioneerType => $composableBuilder(
    column: $table.pioneerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get inactiveDate => $composableBuilder(
    column: $table.inactiveDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CongregationsTableOrderingComposer get congregationId {
    final $$CongregationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableOrderingComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FieldServiceGroupsTableOrderingComposer get fieldServiceGroupId {
    final $$FieldServiceGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fieldServiceGroupId,
      referencedTable: $db.fieldServiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FieldServiceGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.fieldServiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get otherNames => $composableBuilder(
    column: $table.otherNames,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<DateTime> get baptismDate => $composableBuilder(
    column: $table.baptismDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Gender, int> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HopeClass, int> get hopeClass =>
      $composableBuilder(column: $table.hopeClass, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CongregationRole, int>
  get congregationRole => $composableBuilder(
    column: $table.congregationRole,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PioneerType, int> get pioneerType =>
      $composableBuilder(
        column: $table.pioneerType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get inactiveDate => $composableBuilder(
    column: $table.inactiveDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CongregationsTableAnnotationComposer get congregationId {
    final $$CongregationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.congregationId,
      referencedTable: $db.congregations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CongregationsTableAnnotationComposer(
            $db: $db,
            $table: $db.congregations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FieldServiceGroupsTableAnnotationComposer get fieldServiceGroupId {
    final $$FieldServiceGroupsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldServiceGroupId,
          referencedTable: $db.fieldServiceGroups,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FieldServiceGroupsTableAnnotationComposer(
                $db: $db,
                $table: $db.fieldServiceGroups,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> phoneNumbersRefs<T extends Object>(
    Expression<T> Function($$PhoneNumbersTableAnnotationComposer a) f,
  ) {
    final $$PhoneNumbersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.phoneNumbers,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhoneNumbersTableAnnotationComposer(
            $db: $db,
            $table: $db.phoneNumbers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> emergencyContactsRefs<T extends Object>(
    Expression<T> Function($$EmergencyContactsTableAnnotationComposer a) f,
  ) {
    final $$EmergencyContactsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.emergencyContacts,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EmergencyContactsTableAnnotationComposer(
                $db: $db,
                $table: $db.emergencyContacts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> serviceReportsRefs<T extends Object>(
    Expression<T> Function($$ServiceReportsTableAnnotationComposer a) f,
  ) {
    final $$ServiceReportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.serviceReports,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceReportsTableAnnotationComposer(
            $db: $db,
            $table: $db.serviceReports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> auxiliaryPioneerPeriodsRefs<T extends Object>(
    Expression<T> Function($$AuxiliaryPioneerPeriodsTableAnnotationComposer a)
    f,
  ) {
    final $$AuxiliaryPioneerPeriodsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.auxiliaryPioneerPeriods,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AuxiliaryPioneerPeriodsTableAnnotationComposer(
                $db: $db,
                $table: $db.auxiliaryPioneerPeriods,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, $$PersonsTableReferences),
          Person,
          PrefetchHooks Function({
            bool congregationId,
            bool fieldServiceGroupId,
            bool phoneNumbersRefs,
            bool emergencyContactsRefs,
            bool serviceReportsRefs,
            bool auxiliaryPioneerPeriodsRefs,
          })
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> otherNames = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<DateTime?> baptismDate = const Value.absent(),
                Value<Gender> gender = const Value.absent(),
                Value<HopeClass> hopeClass = const Value.absent(),
                Value<CongregationRole> congregationRole = const Value.absent(),
                Value<PioneerType> pioneerType = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> inactiveDate = const Value.absent(),
                Value<int?> congregationId = const Value.absent(),
                Value<int?> fieldServiceGroupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PersonsCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                firstName: firstName,
                lastName: lastName,
                otherNames: otherNames,
                birthDate: birthDate,
                baptismDate: baptismDate,
                gender: gender,
                hopeClass: hopeClass,
                congregationRole: congregationRole,
                pioneerType: pioneerType,
                address: address,
                isActive: isActive,
                inactiveDate: inactiveDate,
                congregationId: congregationId,
                fieldServiceGroupId: fieldServiceGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> otherNames = const Value.absent(),
                Value<DateTime?> birthDate = const Value.absent(),
                Value<DateTime?> baptismDate = const Value.absent(),
                Value<Gender> gender = const Value.absent(),
                Value<HopeClass> hopeClass = const Value.absent(),
                Value<CongregationRole> congregationRole = const Value.absent(),
                Value<PioneerType> pioneerType = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime?> inactiveDate = const Value.absent(),
                Value<int?> congregationId = const Value.absent(),
                Value<int?> fieldServiceGroupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PersonsCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                firstName: firstName,
                lastName: lastName,
                otherNames: otherNames,
                birthDate: birthDate,
                baptismDate: baptismDate,
                gender: gender,
                hopeClass: hopeClass,
                congregationRole: congregationRole,
                pioneerType: pioneerType,
                address: address,
                isActive: isActive,
                inactiveDate: inactiveDate,
                congregationId: congregationId,
                fieldServiceGroupId: fieldServiceGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                congregationId = false,
                fieldServiceGroupId = false,
                phoneNumbersRefs = false,
                emergencyContactsRefs = false,
                serviceReportsRefs = false,
                auxiliaryPioneerPeriodsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (phoneNumbersRefs) db.phoneNumbers,
                    if (emergencyContactsRefs) db.emergencyContacts,
                    if (serviceReportsRefs) db.serviceReports,
                    if (auxiliaryPioneerPeriodsRefs) db.auxiliaryPioneerPeriods,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (congregationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.congregationId,
                                    referencedTable: $$PersonsTableReferences
                                        ._congregationIdTable(db),
                                    referencedColumn: $$PersonsTableReferences
                                        ._congregationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (fieldServiceGroupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fieldServiceGroupId,
                                    referencedTable: $$PersonsTableReferences
                                        ._fieldServiceGroupIdTable(db),
                                    referencedColumn: $$PersonsTableReferences
                                        ._fieldServiceGroupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (phoneNumbersRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          PhoneNumber
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._phoneNumbersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).phoneNumbersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (emergencyContactsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          EmergencyContact
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._emergencyContactsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).emergencyContactsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (serviceReportsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          ServiceReport
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._serviceReportsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).serviceReportsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (auxiliaryPioneerPeriodsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          AuxiliaryPioneerPeriod
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._auxiliaryPioneerPeriodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).auxiliaryPioneerPeriodsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, $$PersonsTableReferences),
      Person,
      PrefetchHooks Function({
        bool congregationId,
        bool fieldServiceGroupId,
        bool phoneNumbersRefs,
        bool emergencyContactsRefs,
        bool serviceReportsRefs,
        bool auxiliaryPioneerPeriodsRefs,
      })
    >;
typedef $$PhoneNumbersTableCreateCompanionBuilder =
    PhoneNumbersCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> number,
      Value<PhoneType> phoneType,
      Value<bool> isPrimary,
      required int personId,
    });
typedef $$PhoneNumbersTableUpdateCompanionBuilder =
    PhoneNumbersCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> number,
      Value<PhoneType> phoneType,
      Value<bool> isPrimary,
      Value<int> personId,
    });

final class $$PhoneNumbersTableReferences
    extends BaseReferences<_$AppDatabase, $PhoneNumbersTable, PhoneNumber> {
  $$PhoneNumbersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.phoneNumbers.personId, db.persons.id),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhoneNumbersTableFilterComposer
    extends Composer<_$AppDatabase, $PhoneNumbersTable> {
  $$PhoneNumbersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PhoneType, PhoneType, int> get phoneType =>
      $composableBuilder(
        column: $table.phoneType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhoneNumbersTableOrderingComposer
    extends Composer<_$AppDatabase, $PhoneNumbersTable> {
  $$PhoneNumbersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phoneType => $composableBuilder(
    column: $table.phoneType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhoneNumbersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhoneNumbersTable> {
  $$PhoneNumbersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PhoneType, int> get phoneType =>
      $composableBuilder(column: $table.phoneType, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhoneNumbersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhoneNumbersTable,
          PhoneNumber,
          $$PhoneNumbersTableFilterComposer,
          $$PhoneNumbersTableOrderingComposer,
          $$PhoneNumbersTableAnnotationComposer,
          $$PhoneNumbersTableCreateCompanionBuilder,
          $$PhoneNumbersTableUpdateCompanionBuilder,
          (PhoneNumber, $$PhoneNumbersTableReferences),
          PhoneNumber,
          PrefetchHooks Function({bool personId})
        > {
  $$PhoneNumbersTableTableManager(_$AppDatabase db, $PhoneNumbersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhoneNumbersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhoneNumbersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhoneNumbersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<PhoneType> phoneType = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> personId = const Value.absent(),
              }) => PhoneNumbersCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                number: number,
                phoneType: phoneType,
                isPrimary: isPrimary,
                personId: personId,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<PhoneType> phoneType = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                required int personId,
              }) => PhoneNumbersCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                number: number,
                phoneType: phoneType,
                isPrimary: isPrimary,
                personId: personId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PhoneNumbersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$PhoneNumbersTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$PhoneNumbersTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PhoneNumbersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhoneNumbersTable,
      PhoneNumber,
      $$PhoneNumbersTableFilterComposer,
      $$PhoneNumbersTableOrderingComposer,
      $$PhoneNumbersTableAnnotationComposer,
      $$PhoneNumbersTableCreateCompanionBuilder,
      $$PhoneNumbersTableUpdateCompanionBuilder,
      (PhoneNumber, $$PhoneNumbersTableReferences),
      PhoneNumber,
      PrefetchHooks Function({bool personId})
    >;
typedef $$EmergencyContactsTableCreateCompanionBuilder =
    EmergencyContactsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> name,
      Value<String> phoneNumber,
      Value<Relationship> relationship,
      Value<bool> isPrimary,
      required int personId,
    });
typedef $$EmergencyContactsTableUpdateCompanionBuilder =
    EmergencyContactsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<String> name,
      Value<String> phoneNumber,
      Value<Relationship> relationship,
      Value<bool> isPrimary,
      Value<int> personId,
    });

final class $$EmergencyContactsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EmergencyContactsTable,
          EmergencyContact
        > {
  $$EmergencyContactsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.emergencyContacts.personId, db.persons.id),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EmergencyContactsTableFilterComposer
    extends Composer<_$AppDatabase, $EmergencyContactsTable> {
  $$EmergencyContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Relationship, Relationship, int>
  get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmergencyContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmergencyContactsTable> {
  $$EmergencyContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmergencyContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmergencyContactsTable> {
  $$EmergencyContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Relationship, int> get relationship =>
      $composableBuilder(
        column: $table.relationship,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmergencyContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmergencyContactsTable,
          EmergencyContact,
          $$EmergencyContactsTableFilterComposer,
          $$EmergencyContactsTableOrderingComposer,
          $$EmergencyContactsTableAnnotationComposer,
          $$EmergencyContactsTableCreateCompanionBuilder,
          $$EmergencyContactsTableUpdateCompanionBuilder,
          (EmergencyContact, $$EmergencyContactsTableReferences),
          EmergencyContact,
          PrefetchHooks Function({bool personId})
        > {
  $$EmergencyContactsTableTableManager(
    _$AppDatabase db,
    $EmergencyContactsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmergencyContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmergencyContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmergencyContactsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phoneNumber = const Value.absent(),
                Value<Relationship> relationship = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> personId = const Value.absent(),
              }) => EmergencyContactsCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                name: name,
                phoneNumber: phoneNumber,
                relationship: relationship,
                isPrimary: isPrimary,
                personId: personId,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phoneNumber = const Value.absent(),
                Value<Relationship> relationship = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                required int personId,
              }) => EmergencyContactsCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                name: name,
                phoneNumber: phoneNumber,
                relationship: relationship,
                isPrimary: isPrimary,
                personId: personId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EmergencyContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$EmergencyContactsTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$EmergencyContactsTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EmergencyContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmergencyContactsTable,
      EmergencyContact,
      $$EmergencyContactsTableFilterComposer,
      $$EmergencyContactsTableOrderingComposer,
      $$EmergencyContactsTableAnnotationComposer,
      $$EmergencyContactsTableCreateCompanionBuilder,
      $$EmergencyContactsTableUpdateCompanionBuilder,
      (EmergencyContact, $$EmergencyContactsTableReferences),
      EmergencyContact,
      PrefetchHooks Function({bool personId})
    >;
typedef $$ServiceReportsTableCreateCompanionBuilder =
    ServiceReportsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      required int year,
      required int month,
      Value<bool> isAuxiliaryPioneer,
      Value<bool> isActive,
      Value<bool> sharedInMinistry,
      Value<int> bibleStudies,
      Value<double> hours,
      Value<String> note,
      required int personId,
    });
typedef $$ServiceReportsTableUpdateCompanionBuilder =
    ServiceReportsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<int> year,
      Value<int> month,
      Value<bool> isAuxiliaryPioneer,
      Value<bool> isActive,
      Value<bool> sharedInMinistry,
      Value<int> bibleStudies,
      Value<double> hours,
      Value<String> note,
      Value<int> personId,
    });

final class $$ServiceReportsTableReferences
    extends BaseReferences<_$AppDatabase, $ServiceReportsTable, ServiceReport> {
  $$ServiceReportsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.serviceReports.personId, db.persons.id),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ServiceReportsTableFilterComposer
    extends Composer<_$AppDatabase, $ServiceReportsTable> {
  $$ServiceReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAuxiliaryPioneer => $composableBuilder(
    column: $table.isAuxiliaryPioneer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sharedInMinistry => $composableBuilder(
    column: $table.sharedInMinistry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bibleStudies => $composableBuilder(
    column: $table.bibleStudies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $ServiceReportsTable> {
  $$ServiceReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAuxiliaryPioneer => $composableBuilder(
    column: $table.isAuxiliaryPioneer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sharedInMinistry => $composableBuilder(
    column: $table.sharedInMinistry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bibleStudies => $composableBuilder(
    column: $table.bibleStudies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServiceReportsTable> {
  $$ServiceReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<bool> get isAuxiliaryPioneer => $composableBuilder(
    column: $table.isAuxiliaryPioneer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get sharedInMinistry => $composableBuilder(
    column: $table.sharedInMinistry,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bibleStudies => $composableBuilder(
    column: $table.bibleStudies,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServiceReportsTable,
          ServiceReport,
          $$ServiceReportsTableFilterComposer,
          $$ServiceReportsTableOrderingComposer,
          $$ServiceReportsTableAnnotationComposer,
          $$ServiceReportsTableCreateCompanionBuilder,
          $$ServiceReportsTableUpdateCompanionBuilder,
          (ServiceReport, $$ServiceReportsTableReferences),
          ServiceReport,
          PrefetchHooks Function({bool personId})
        > {
  $$ServiceReportsTableTableManager(
    _$AppDatabase db,
    $ServiceReportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServiceReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServiceReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<bool> isAuxiliaryPioneer = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> sharedInMinistry = const Value.absent(),
                Value<int> bibleStudies = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> personId = const Value.absent(),
              }) => ServiceReportsCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                year: year,
                month: month,
                isAuxiliaryPioneer: isAuxiliaryPioneer,
                isActive: isActive,
                sharedInMinistry: sharedInMinistry,
                bibleStudies: bibleStudies,
                hours: hours,
                note: note,
                personId: personId,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required int year,
                required int month,
                Value<bool> isAuxiliaryPioneer = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> sharedInMinistry = const Value.absent(),
                Value<int> bibleStudies = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<String> note = const Value.absent(),
                required int personId,
              }) => ServiceReportsCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                year: year,
                month: month,
                isAuxiliaryPioneer: isAuxiliaryPioneer,
                isActive: isActive,
                sharedInMinistry: sharedInMinistry,
                bibleStudies: bibleStudies,
                hours: hours,
                note: note,
                personId: personId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ServiceReportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$ServiceReportsTableReferences
                                    ._personIdTable(db),
                                referencedColumn:
                                    $$ServiceReportsTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ServiceReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServiceReportsTable,
      ServiceReport,
      $$ServiceReportsTableFilterComposer,
      $$ServiceReportsTableOrderingComposer,
      $$ServiceReportsTableAnnotationComposer,
      $$ServiceReportsTableCreateCompanionBuilder,
      $$ServiceReportsTableUpdateCompanionBuilder,
      (ServiceReport, $$ServiceReportsTableReferences),
      ServiceReport,
      PrefetchHooks Function({bool personId})
    >;
typedef $$AuxiliaryPioneerPeriodsTableCreateCompanionBuilder =
    AuxiliaryPioneerPeriodsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      required int startMonth,
      required int startYear,
      Value<int?> endMonth,
      Value<int?> endYear,
      required int personId,
    });
typedef $$AuxiliaryPioneerPeriodsTableUpdateCompanionBuilder =
    AuxiliaryPioneerPeriodsCompanion Function({
      Value<String?> syncId,
      Value<int> serverVersion,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> id,
      Value<int> startMonth,
      Value<int> startYear,
      Value<int?> endMonth,
      Value<int?> endYear,
      Value<int> personId,
    });

final class $$AuxiliaryPioneerPeriodsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AuxiliaryPioneerPeriodsTable,
          AuxiliaryPioneerPeriod
        > {
  $$AuxiliaryPioneerPeriodsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(
          db.auxiliaryPioneerPeriods.personId,
          db.persons.id,
        ),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AuxiliaryPioneerPeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $AuxiliaryPioneerPeriodsTable> {
  $$AuxiliaryPioneerPeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startYear => $composableBuilder(
    column: $table.startYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMonth => $composableBuilder(
    column: $table.endMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endYear => $composableBuilder(
    column: $table.endYear,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuxiliaryPioneerPeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuxiliaryPioneerPeriodsTable> {
  $$AuxiliaryPioneerPeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startYear => $composableBuilder(
    column: $table.startYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMonth => $composableBuilder(
    column: $table.endMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endYear => $composableBuilder(
    column: $table.endYear,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuxiliaryPioneerPeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuxiliaryPioneerPeriodsTable> {
  $$AuxiliaryPioneerPeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startMonth => $composableBuilder(
    column: $table.startMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startYear =>
      $composableBuilder(column: $table.startYear, builder: (column) => column);

  GeneratedColumn<int> get endMonth =>
      $composableBuilder(column: $table.endMonth, builder: (column) => column);

  GeneratedColumn<int> get endYear =>
      $composableBuilder(column: $table.endYear, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuxiliaryPioneerPeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuxiliaryPioneerPeriodsTable,
          AuxiliaryPioneerPeriod,
          $$AuxiliaryPioneerPeriodsTableFilterComposer,
          $$AuxiliaryPioneerPeriodsTableOrderingComposer,
          $$AuxiliaryPioneerPeriodsTableAnnotationComposer,
          $$AuxiliaryPioneerPeriodsTableCreateCompanionBuilder,
          $$AuxiliaryPioneerPeriodsTableUpdateCompanionBuilder,
          (AuxiliaryPioneerPeriod, $$AuxiliaryPioneerPeriodsTableReferences),
          AuxiliaryPioneerPeriod,
          PrefetchHooks Function({bool personId})
        > {
  $$AuxiliaryPioneerPeriodsTableTableManager(
    _$AppDatabase db,
    $AuxiliaryPioneerPeriodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuxiliaryPioneerPeriodsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AuxiliaryPioneerPeriodsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AuxiliaryPioneerPeriodsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                Value<int> startMonth = const Value.absent(),
                Value<int> startYear = const Value.absent(),
                Value<int?> endMonth = const Value.absent(),
                Value<int?> endYear = const Value.absent(),
                Value<int> personId = const Value.absent(),
              }) => AuxiliaryPioneerPeriodsCompanion(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                startMonth: startMonth,
                startYear: startYear,
                endMonth: endMonth,
                endYear: endYear,
                personId: personId,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncId = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> id = const Value.absent(),
                required int startMonth,
                required int startYear,
                Value<int?> endMonth = const Value.absent(),
                Value<int?> endYear = const Value.absent(),
                required int personId,
              }) => AuxiliaryPioneerPeriodsCompanion.insert(
                syncId: syncId,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                id: id,
                startMonth: startMonth,
                startYear: startYear,
                endMonth: endMonth,
                endYear: endYear,
                personId: personId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AuxiliaryPioneerPeriodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$AuxiliaryPioneerPeriodsTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$AuxiliaryPioneerPeriodsTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AuxiliaryPioneerPeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuxiliaryPioneerPeriodsTable,
      AuxiliaryPioneerPeriod,
      $$AuxiliaryPioneerPeriodsTableFilterComposer,
      $$AuxiliaryPioneerPeriodsTableOrderingComposer,
      $$AuxiliaryPioneerPeriodsTableAnnotationComposer,
      $$AuxiliaryPioneerPeriodsTableCreateCompanionBuilder,
      $$AuxiliaryPioneerPeriodsTableUpdateCompanionBuilder,
      (AuxiliaryPioneerPeriod, $$AuxiliaryPioneerPeriodsTableReferences),
      AuxiliaryPioneerPeriod,
      PrefetchHooks Function({bool personId})
    >;
typedef $$SyncSettingsTableCreateCompanionBuilder =
    SyncSettingsCompanion Function({
      Value<int> id,
      Value<bool> isEnabled,
      Value<String?> serverUrl,
      Value<String?> bearerToken,
      Value<String?> deviceId,
      Value<String?> pullCursor,
      Value<DateTime?> lastSyncAt,
      Value<String?> lastError,
    });
typedef $$SyncSettingsTableUpdateCompanionBuilder =
    SyncSettingsCompanion Function({
      Value<int> id,
      Value<bool> isEnabled,
      Value<String?> serverUrl,
      Value<String?> bearerToken,
      Value<String?> deviceId,
      Value<String?> pullCursor,
      Value<DateTime?> lastSyncAt,
      Value<String?> lastError,
    });

class $$SyncSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncSettingsTable> {
  $$SyncSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bearerToken => $composableBuilder(
    column: $table.bearerToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncSettingsTable> {
  $$SyncSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bearerToken => $composableBuilder(
    column: $table.bearerToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncSettingsTable> {
  $$SyncSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get bearerToken => $composableBuilder(
    column: $table.bearerToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get pullCursor => $composableBuilder(
    column: $table.pullCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncSettingsTable,
          SyncSetting,
          $$SyncSettingsTableFilterComposer,
          $$SyncSettingsTableOrderingComposer,
          $$SyncSettingsTableAnnotationComposer,
          $$SyncSettingsTableCreateCompanionBuilder,
          $$SyncSettingsTableUpdateCompanionBuilder,
          (
            SyncSetting,
            BaseReferences<_$AppDatabase, $SyncSettingsTable, SyncSetting>,
          ),
          SyncSetting,
          PrefetchHooks Function()
        > {
  $$SyncSettingsTableTableManager(_$AppDatabase db, $SyncSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String?> serverUrl = const Value.absent(),
                Value<String?> bearerToken = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> pullCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncSettingsCompanion(
                id: id,
                isEnabled: isEnabled,
                serverUrl: serverUrl,
                bearerToken: bearerToken,
                deviceId: deviceId,
                pullCursor: pullCursor,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String?> serverUrl = const Value.absent(),
                Value<String?> bearerToken = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> pullCursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncSettingsCompanion.insert(
                id: id,
                isEnabled: isEnabled,
                serverUrl: serverUrl,
                bearerToken: bearerToken,
                deviceId: deviceId,
                pullCursor: pullCursor,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncSettingsTable,
      SyncSetting,
      $$SyncSettingsTableFilterComposer,
      $$SyncSettingsTableOrderingComposer,
      $$SyncSettingsTableAnnotationComposer,
      $$SyncSettingsTableCreateCompanionBuilder,
      $$SyncSettingsTableUpdateCompanionBuilder,
      (
        SyncSetting,
        BaseReferences<_$AppDatabase, $SyncSettingsTable, SyncSetting>,
      ),
      SyncSetting,
      PrefetchHooks Function()
    >;
typedef $$PendingSyncOperationsTableCreateCompanionBuilder =
    PendingSyncOperationsCompanion Function({
      Value<int> id,
      required String operationId,
      required String entityType,
      required String entitySyncId,
      required String operationType,
      required String payloadJson,
      Value<int?> baseServerVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> attemptCount,
      Value<String?> lastError,
    });
typedef $$PendingSyncOperationsTableUpdateCompanionBuilder =
    PendingSyncOperationsCompanion Function({
      Value<int> id,
      Value<String> operationId,
      Value<String> entityType,
      Value<String> entitySyncId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<int?> baseServerVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> attemptCount,
      Value<String?> lastError,
    });

class $$PendingSyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseServerVersion => $composableBuilder(
    column: $table.baseServerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$PendingSyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSyncOperationsTable,
          PendingSyncOperation,
          $$PendingSyncOperationsTableFilterComposer,
          $$PendingSyncOperationsTableOrderingComposer,
          $$PendingSyncOperationsTableAnnotationComposer,
          $$PendingSyncOperationsTableCreateCompanionBuilder,
          $$PendingSyncOperationsTableUpdateCompanionBuilder,
          (
            PendingSyncOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingSyncOperationsTable,
              PendingSyncOperation
            >,
          ),
          PendingSyncOperation,
          PrefetchHooks Function()
        > {
  $$PendingSyncOperationsTableTableManager(
    _$AppDatabase db,
    $PendingSyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncOperationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PendingSyncOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingSyncOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entitySyncId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int?> baseServerVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingSyncOperationsCompanion(
                id: id,
                operationId: operationId,
                entityType: entityType,
                entitySyncId: entitySyncId,
                operationType: operationType,
                payloadJson: payloadJson,
                baseServerVersion: baseServerVersion,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attemptCount: attemptCount,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationId,
                required String entityType,
                required String entitySyncId,
                required String operationType,
                required String payloadJson,
                Value<int?> baseServerVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => PendingSyncOperationsCompanion.insert(
                id: id,
                operationId: operationId,
                entityType: entityType,
                entitySyncId: entitySyncId,
                operationType: operationType,
                payloadJson: payloadJson,
                baseServerVersion: baseServerVersion,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attemptCount: attemptCount,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSyncOperationsTable,
      PendingSyncOperation,
      $$PendingSyncOperationsTableFilterComposer,
      $$PendingSyncOperationsTableOrderingComposer,
      $$PendingSyncOperationsTableAnnotationComposer,
      $$PendingSyncOperationsTableCreateCompanionBuilder,
      $$PendingSyncOperationsTableUpdateCompanionBuilder,
      (
        PendingSyncOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingSyncOperationsTable,
          PendingSyncOperation
        >,
      ),
      PendingSyncOperation,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictsTableCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<int> id,
      required String entityType,
      required String entitySyncId,
      required String localPayloadJson,
      required String serverPayloadJson,
      required int serverVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> resolvedAt,
    });
typedef $$SyncConflictsTableUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entitySyncId,
      Value<String> localPayloadJson,
      Value<String> serverPayloadJson,
      Value<int> serverVersion,
      Value<DateTime> createdAt,
      Value<DateTime?> resolvedAt,
    });

class $$SyncConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entitySyncId => $composableBuilder(
    column: $table.entitySyncId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverPayloadJson => $composableBuilder(
    column: $table.serverPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$SyncConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictsTable,
          SyncConflict,
          $$SyncConflictsTableFilterComposer,
          $$SyncConflictsTableOrderingComposer,
          $$SyncConflictsTableAnnotationComposer,
          $$SyncConflictsTableCreateCompanionBuilder,
          $$SyncConflictsTableUpdateCompanionBuilder,
          (
            SyncConflict,
            BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflict>,
          ),
          SyncConflict,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableManager(_$AppDatabase db, $SyncConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entitySyncId = const Value.absent(),
                Value<String> localPayloadJson = const Value.absent(),
                Value<String> serverPayloadJson = const Value.absent(),
                Value<int> serverVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
              }) => SyncConflictsCompanion(
                id: id,
                entityType: entityType,
                entitySyncId: entitySyncId,
                localPayloadJson: localPayloadJson,
                serverPayloadJson: serverPayloadJson,
                serverVersion: serverVersion,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entitySyncId,
                required String localPayloadJson,
                required String serverPayloadJson,
                required int serverVersion,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
              }) => SyncConflictsCompanion.insert(
                id: id,
                entityType: entityType,
                entitySyncId: entitySyncId,
                localPayloadJson: localPayloadJson,
                serverPayloadJson: serverPayloadJson,
                serverVersion: serverVersion,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictsTable,
      SyncConflict,
      $$SyncConflictsTableFilterComposer,
      $$SyncConflictsTableOrderingComposer,
      $$SyncConflictsTableAnnotationComposer,
      $$SyncConflictsTableCreateCompanionBuilder,
      $$SyncConflictsTableUpdateCompanionBuilder,
      (
        SyncConflict,
        BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflict>,
      ),
      SyncConflict,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CongregationsTableTableManager get congregations =>
      $$CongregationsTableTableManager(_db, _db.congregations);
  $$FieldServiceGroupsTableTableManager get fieldServiceGroups =>
      $$FieldServiceGroupsTableTableManager(_db, _db.fieldServiceGroups);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$PhoneNumbersTableTableManager get phoneNumbers =>
      $$PhoneNumbersTableTableManager(_db, _db.phoneNumbers);
  $$EmergencyContactsTableTableManager get emergencyContacts =>
      $$EmergencyContactsTableTableManager(_db, _db.emergencyContacts);
  $$ServiceReportsTableTableManager get serviceReports =>
      $$ServiceReportsTableTableManager(_db, _db.serviceReports);
  $$AuxiliaryPioneerPeriodsTableTableManager get auxiliaryPioneerPeriods =>
      $$AuxiliaryPioneerPeriodsTableTableManager(
        _db,
        _db.auxiliaryPioneerPeriods,
      );
  $$SyncSettingsTableTableManager get syncSettings =>
      $$SyncSettingsTableTableManager(_db, _db.syncSettings);
  $$PendingSyncOperationsTableTableManager get pendingSyncOperations =>
      $$PendingSyncOperationsTableTableManager(_db, _db.pendingSyncOperations);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
}
