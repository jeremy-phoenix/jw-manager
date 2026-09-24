import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/sync_providers.dart';
import 'package:congregation_manager/ui/screens/settings/sync/sync_manage_dialogs.dart';
import 'package:congregation_manager/ui/screens/settings/sync/sync_setup_dialogs.dart';

/// Online Sync settings: set up, join, or manage the encrypted vault.
class OnlineSyncCard extends ConsumerWidget {
  const OnlineSyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(syncSettingsProvider)
        .when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off),
              title: const Text('Sync unavailable'),
              subtitle: Text('$error'),
            ),
          ),
          data: (settings) => settings.isEnabled
              ? _EnrolledCard(settings: settings)
              : _SetupCard(settings: settings),
        );
  }
}

class _SetupCard extends ConsumerWidget {
  const _SetupCard({required this.settings});

  final SyncSetting settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.lock_outline,
                color: theme.colorScheme.primary,
              ),
              title: const Text('End-to-end encrypted sync'),
              subtitle: const Text(
                'Records are encrypted on this device before upload. The '
                'server stores only ciphertext and cannot read names, '
                'addresses, reports or notes.',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Enrolling replaces this card, so the dialogs do their own
                // follow-up work instead of this widget.
                FilledButton.icon(
                  icon: const Icon(Icons.add_moderator_outlined),
                  label: const Text('Create a new vault'),
                  onPressed: () => showCreateVaultDialog(
                    context,
                    serverUrl: settings.serverUrl,
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Join with an invite'),
                  onPressed: () => showJoinWithInviteDialog(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Use the recovery code'),
                  onPressed: () => showRecoverWithCodeDialog(
                    context,
                    serverUrl: settings.serverUrl,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrolledCard extends ConsumerWidget {
  const _EnrolledCard({required this.settings});

  final SyncSetting settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pending = ref.watch(pendingSyncOperationCountProvider).value ?? 0;
    final conflicts = ref.watch(openSyncConflictCountProvider).value ?? 0;
    final syncing = ref.watch(syncInProgressProvider).value ?? false;
    final lastSync = settings.lastSyncAt == null
        ? 'Never'
        : DateFormat.yMMMd().add_jm().format(settings.lastSyncAt!.toLocal());
    final host =
        Uri.tryParse(settings.serverUrl ?? '')?.host ??
        settings.serverUrl ??
        '';
    final hasProblem = settings.needsKey || settings.lastError != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                hasProblem ? Icons.sync_problem : Icons.cloud_done_outlined,
                color: hasProblem
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              title: const Text('Encrypted sync is on'),
              subtitle: Text(host),
              trailing: PopupMenuButton<_MenuAction>(
                tooltip: 'More',
                onSelected: (action) => _onMenu(context, ref, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _MenuAction.rotateKey,
                    child: Text('Change encryption key'),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.disconnect,
                    child: Text('Disconnect this device'),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.deleteVault,
                    child: Text('Delete vault from server'),
                  ),
                ],
              ),
            ),
            _InfoRow(label: 'This device', value: settings.deviceLabel ?? ''),
            _InfoRow(label: 'Last sync', value: lastSync),
            _InfoRow(label: 'Changes waiting to upload', value: '$pending'),
            if (conflicts > 0)
              _InfoRow(
                label: 'Conflicts',
                value: '$conflicts',
                action: TextButton(
                  onPressed: () => showConflictsDialog(context),
                  child: const Text('Review'),
                ),
              ),
            if (settings.needsKey)
              _Notice(
                message:
                    'The encryption key was changed on another device. Enter '
                    'the recovery code to keep syncing on this device.',
                action: FilledButton(
                  onPressed: () => showUnlockDialog(context),
                  child: const Text('Enter recovery code'),
                ),
              )
            else if (settings.lastError != null)
              _Notice(message: settings.lastError!),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.devices_outlined),
                  label: const Text('Devices'),
                  onPressed: () => showDevicesDialog(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Invite a device'),
                  onPressed: settings.needsKey
                      ? null
                      : () => showInviteDeviceDialog(context),
                ),
                FilledButton.icon(
                  icon: syncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Sync now'),
                  onPressed: syncing || settings.needsKey
                      ? null
                      : () => _runSync(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.rotateKey:
        await showRotateKeyDialog(context, serverUrl: settings.serverUrl ?? '');
      case _MenuAction.disconnect:
        await showDisconnectDialog(context, ref);
      case _MenuAction.deleteVault:
        await showDeleteVaultDialog(context);
    }
  }
}

enum _MenuAction { rotateKey, disconnect, deleteVault }

void _runSync(BuildContext context, WidgetRef ref) {
  final messenger = ScaffoldMessenger.of(context);
  unawaited(
    ref
        .read(syncServiceProvider)
        .syncNow()
        .then(
          (result) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Sync complete: ${result.pushed} uploaded, ${result.pulled} '
                  'downloaded${result.conflicts > 0 ? ', ${result.conflicts} conflicts' : ''}.',
                ),
              ),
            );
          },
          onError: (Object error) {
            messenger.showSnackBar(
              SnackBar(content: Text('Sync failed: $error')),
            );
          },
        ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.action});

  final String label;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ?action,
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: TextStyle(color: colors.onErrorContainer)),
          if (action != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: action),
          ],
        ],
      ),
    );
  }
}
