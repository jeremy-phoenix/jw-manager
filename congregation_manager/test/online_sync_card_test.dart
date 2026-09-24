import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/sync_providers.dart';
import 'package:congregation_manager/services/sync/sync_api_client.dart';
import 'package:congregation_manager/services/sync/sync_credentials.dart';
import 'package:congregation_manager/services/sync/sync_invite.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';
import 'package:congregation_manager/ui/screens/settings/sync/online_sync_card.dart';

import 'services/sync/fake_sync_server.dart';

void main() {
  late FakeSyncServer server;
  late AppDatabase db;

  Future<void> pumpCard(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final credentials = MemorySyncCredentialStore();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        syncCredentialStoreProvider.overrideWithValue(credentials),
        syncServiceProvider.overrideWith((ref) {
          final service = SyncService(
            db,
            credentials,
            apiFactory: (url, {deviceToken}) => SyncApiClient(
              url,
              deviceToken: deviceToken,
              httpClient: server.client,
            ),
          );
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: OnlineSyncCard())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    server = FakeSyncServer();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertCongregation(
      CongregationsCompanion.insert(name: const drift.Value('Riverside')),
    );
  });

  tearDown(() => db.close());

  Future<void> createVault(WidgetTester tester) async {
    await tester.tap(find.text('Create a new vault'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server address'),
      'https://sync.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Registration secret'),
      server.registrationSecret,
    );
    await tester.tap(find.text('Create vault'));
    await tester.pumpAndSettle();

    // The recovery code must be acknowledged before anything is created.
    expect(find.text('Save your recovery code'), findsOneWidget);
    expect(server.vaults, isEmpty);
    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.tap(find.text('I have saved the recovery code'));
    await tester.pump();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
  }

  testWidgets('creating a vault shows the recovery code first, then uploads', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(find.text('Join with an invite'), findsOneWidget);
    expect(find.text('Use the recovery code'), findsOneWidget);

    await createVault(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Encrypted sync is on'), findsOneWidget);
    expect(find.text('sync.test'), findsOneWidget);
    expect(server.vaults, hasLength(1));
    expect(server.vaults.values.single.records, hasLength(1));
    expect(await tester.runAsync(db.getPendingSyncOperationCount), 0);
  });

  testWidgets('an invite is shown as a QR code and text', (tester) async {
    await pumpCard(tester);
    await createVault(tester);

    await tester.tap(find.text('Invite a device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create invite'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    final text = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((widget) => widget.data ?? '')
        .firstWhere((data) => data.startsWith(SyncInvite.prefix));
    expect(SyncInvite.parse(text).serverUrl.host, 'sync.test');
  });

  testWidgets('a device without the current key asks for the recovery code', (
    tester,
  ) async {
    await tester.runAsync(
      () => db.activateSyncVault(
        serverUrl: 'https://sync.test',
        vaultId: '00000000-0000-4000-8000-000000000001',
        deviceId: '00000000-0000-4000-8000-000000000002',
        deviceLabel: 'Laptop',
        keyId: 2,
        uploadLocalData: false,
        needsKey: true,
      ),
    );

    await pumpCard(tester);

    expect(find.text('Enter recovery code'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sync now'))
          .onPressed,
      isNull,
    );
  });
}
