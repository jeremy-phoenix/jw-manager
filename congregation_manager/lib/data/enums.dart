/// Congregation role for a person.
enum CongregationRole {
  none('None'),
  elder('Elder'),
  ministerialServant('Ministerial Servant');

  const CongregationRole(this.displayName);
  final String displayName;
}

/// Pioneer type for a person.
enum PioneerType {
  none('None'),
  regularPioneer('Regular Pioneer'),
  specialPioneer('Special Pioneer'),
  fieldMissionary('Field Missionary');

  const PioneerType(this.displayName);
  final String displayName;
}

/// Hope class for a person.
enum HopeClass {
  unknown('Unknown'),
  otherSheep('Other Sheep'),
  anointed('Anointed');

  const HopeClass(this.displayName);
  final String displayName;
}

/// Gender.
enum Gender {
  unknown('Unknown'),
  male('Male'),
  female('Female');

  const Gender(this.displayName);
  final String displayName;
}

/// Phone number type.
enum PhoneType {
  mobile('Mobile'),
  home('Home'),
  work('Work'),
  other('Other');

  const PhoneType(this.displayName);
  final String displayName;
}

/// Relationship for emergency contacts.
enum Relationship {
  spouse('Spouse'),
  parent('Parent'),
  child('Child'),
  sibling('Sibling'),
  grandparent('Grandparent'),
  grandchild('Grandchild'),
  friend('Friend'),
  other('Other');

  const Relationship(this.displayName);
  final String displayName;
}

/// Service year months (September-August).
enum ServiceMonth {
  september(9, 'September'),
  october(10, 'October'),
  november(11, 'November'),
  december(12, 'December'),
  january(1, 'January'),
  february(2, 'February'),
  march(3, 'March'),
  april(4, 'April'),
  may(5, 'May'),
  june(6, 'June'),
  july(7, 'July'),
  august(8, 'August');

  const ServiceMonth(this.monthNumber, this.displayName);
  final int monthNumber;
  final String displayName;

  /// Returns the service year for a given calendar year and this month.
  int serviceYear(int calendarYear) {
    return monthNumber >= 9 ? calendarYear + 1 : calendarYear;
  }
}

/// Entity status.
enum EntityStatus {
  active('Active'),
  inactive('Inactive'),
  archived('Archived'),
  deleted('Deleted');

  const EntityStatus(this.displayName);
  final String displayName;
}
