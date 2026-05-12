import 'package:flutter_test/flutter_test.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/enums.dart';
import 'package:congregation_manager/reporting/publisher_directory_report.dart';

void main() {
  test(
    'large publisher directory can exceed the default MultiPage limit',
    () async {
      final now = DateTime(2026, 5, 12);
      final groups = {
        for (var i = 1; i <= 5; i++)
          i: FieldServiceGroup(
            id: i,
            name: 'Group $i',
            description: '',
            congregationId: 1,
            serverVersion: 0,
            createdAt: now,
            updatedAt: now,
          ),
      };
      final persons = List.generate(
        800,
        (index) => Person(
          id: index + 1,
          firstName: 'Publisher',
          lastName: 'Number ${index + 1}',
          otherNames: '',
          birthDate: null,
          baptismDate: null,
          gender: Gender.unknown,
          hopeClass: HopeClass.unknown,
          congregationRole: CongregationRole.none,
          pioneerType: PioneerType.none,
          address: '123 Long Address Street, Apartment ${index + 1}',
          isActive: true,
          congregationId: 1,
          fieldServiceGroupId: (index % groups.length) + 1,
          serverVersion: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final phones = {
        for (final person in persons)
          person.id: [
            PhoneNumber(
              id: person.id,
              number: '555-010${person.id % 10}',
              phoneType: PhoneType.mobile,
              isPrimary: true,
              personId: person.id,
              serverVersion: 0,
            ),
          ],
      };

      final document = generatePublisherDirectoryReport(
        persons: persons,
        phonesByPerson: phones,
        groupsById: groups,
      );

      final bytes = await document.save();

      expect(bytes, isNotEmpty);
    },
  );
}
