/// Entity type names carried inside encrypted sync envelopes.
abstract final class SyncEntityTypes {
  static const congregation = 'congregation';
  static const fieldServiceGroup = 'fieldServiceGroup';
  static const person = 'person';
  static const phoneNumber = 'phoneNumber';
  static const emergencyContact = 'emergencyContact';
  static const serviceReport = 'serviceReport';
  static const auxiliaryPioneerPeriod = 'auxiliaryPioneerPeriod';

  static const all = {
    congregation,
    fieldServiceGroup,
    person,
    phoneNumber,
    emergencyContact,
    serviceReport,
    auxiliaryPioneerPeriod,
  };
}

/// A decrypted record from the server's change feed.
class RemoteChange {
  const RemoteChange({
    required this.entityType,
    required this.syncId,
    required this.version,
    this.deleted = false,
    this.payload = const {},
  });

  final String entityType;
  final String syncId;
  final int version;
  final bool deleted;

  /// The full entity state as the pushing device saw it; empty for deletes.
  final Map<String, dynamic> payload;
}
