import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/data/sync_models.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/sync_providers.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';
import 'package:congregation_manager/ui/screens/settings/sync/recovery_code_dialog.dart';

final _dateTime = DateFormat.yMMMd().add_jm();

Future<void> showInviteDeviceDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _InviteDialog());

Future<void> showDevicesDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _DevicesDialog());

Future<void> showRotateKeyDialog(
  BuildContext context, {
  required String serverUrl,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _RotateKeyDialog(serverUrl: serverUrl),
);

Future<void> showUnlockDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      const _RecoveryCodeActionDialog(action: _RecoveryAction.unlock),
);

Future<void> showDeleteVaultDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      const _RecoveryCodeActionDialog(action: _RecoveryAction.deleteVault),
);

Future<void> showConflictsDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _ConflictsDialog(),
);

/// Returns true when the device was disconnected.
Future<bool> showDisconnectDialog(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(syncServiceProvider);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Stop syncing on this device?'),
      content: const Text(
        'This device is removed from the vault and its sync keys are deleted. '
        'Congregation data on this device stays. To sync again you will need '
        'a new invite or the recovery code.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Disconnect'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await service.disconnect();
    return true;
  } on Object catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not disconnect: $error')),
    );
    return false;
  }
}

class _InviteDialog extends ConsumerStatefulWidget {
  const _InviteDialog();

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  Duration _lifetime = const Duration(minutes: 30);
  CreatedSyncInvite? _invite;
  bool _busy = false;
  String? _error;

  static const _lifetimes = [
    (Duration(minutes: 30), '30 minutes'),
    (Duration(hours: 24), '24 hours'),
    (Duration(days: 7), '7 days'),
  ];

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Invite a device'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'The invite contains the encryption key. Anyone who has it '
                'before it expires can join and read all data. Show the QR '
                'code in person, or send the text through a private channel; '
                'never post it in a group chat.',
              ),
              const SizedBox(height: 16),
              if (invite == null) ...[
                Text('Valid for', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<Duration>(
                  segments: [
                    for (final (lifetime, label) in _lifetimes)
                      ButtonSegment(value: lifetime, label: Text(label)),
                  ],
                  selected: {_lifetime},
                  onSelectionChanged: _busy
                      ? null
                      : (selection) =>
                            setState(() => _lifetime = selection.first),
                ),
              ] else ...[
                Center(
                  child: QrImageView(
                    data: invite.invite,
                    size: 260,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  invite.invite,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Single use. Expires ${_dateTime.format(invite.expiresAt.toLocal())}.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (invite != null)
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy invite'),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: invite.invite)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(invite == null ? 'Cancel' : 'Done'),
        ),
        if (invite == null)
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('Create invite'),
          ),
      ],
    );
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final invite = await ref
          .read(syncServiceProvider)
          .createInvite(lifetime: _lifetime);
      if (mounted) setState(() => _invite = invite);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DevicesDialog extends ConsumerStatefulWidget {
  const _DevicesDialog();

  @override
  ConsumerState<_DevicesDialog> createState() => _DevicesDialogState();
}

class _DevicesDialogState extends ConsumerState<_DevicesDialog> {
  late Future<List<SyncDevice>> _devices = _load();

  Future<List<SyncDevice>> _load() =>
      ref.read(syncServiceProvider).listDevices();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Devices'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<List<SyncDevice>>(
          future: _devices,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('${snapshot.error}');
            final devices = snapshot.data;
            if (devices == null) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final device in devices)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      device.isCurrent ? Icons.smartphone : Icons.devices_other,
                    ),
                    title: Text(device.label ?? 'Unnamed device'),
                    subtitle: Text(
                      'Added ${_dateTime.format(device.createdAt.toLocal())} '
                      '(${_enrolledVia(device.enrolledVia)})\n'
                      'Last seen ${_dateTime.format(device.lastSeenAt.toLocal())}',
                    ),
                    isThreeLine: true,
                    trailing: device.isCurrent
                        ? IconButton(
                            tooltip: 'Rename this device',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _rename(device),
                          )
                        : IconButton(
                            tooltip: 'Remove device',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _revoke(device),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static String _enrolledVia(String method) => switch (method) {
    'create' => 'created the vault',
    'invite' => 'invite',
    'recovery' => 'recovery code',
    _ => method,
  };

  Future<void> _revoke(SyncDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${device.label ?? 'this device'}?'),
        content: const Text(
          'It stops syncing immediately. If the device was lost or stolen, '
          'also change the encryption key afterwards (Online Sync > More > '
          'Change encryption key), so it cannot read anything added later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(syncServiceProvider).revokeDevice(device.deviceId);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
    if (mounted) setState(() => _devices = _load());
  }

  Future<void> _rename(SyncDevice device) async {
    final controller = TextEditingController(text: device.label);
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename this device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty) return;
    try {
      await ref.read(syncServiceProvider).renameThisDevice(label);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
    if (mounted) setState(() => _devices = _load());
  }
}

class _RotateKeyDialog extends ConsumerStatefulWidget {
  const _RotateKeyDialog({required this.serverUrl});

  final String serverUrl;

  @override
  ConsumerState<_RotateKeyDialog> createState() => _RotateKeyDialogState();
}

class _RotateKeyDialogState extends ConsumerState<_RotateKeyDialog> {
  final _code = TextEditingController();
  bool _replaceRecoveryCode = false;
  RecoveryCode? _newRecoveryCode;
  bool _busy = false;
  int _progress = 0;
  String? _error;
  KeyRotationResult? _result;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return AlertDialog(
      title: const Text('Change encryption key'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: result != null
              ? Text(
                  'Done. ${result.reencrypted} records were re-encrypted with '
                  'the new key.'
                  '${result.unreadable > 0 ? ' ${result.unreadable} records were encrypted with a key this device never had and still use it; rotate again from a device that has it.' : ''}'
                  '\n\nEach other device will ask for the recovery code once.',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Use this after removing a lost or stolen device. A new '
                      'key is created and all data on the server is '
                      're-encrypted with it, so the old key becomes useless. '
                      'Other devices ask for the recovery code once.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _code,
                      enabled: !_busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        labelText: 'Current recovery code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _replaceRecoveryCode,
                      onChanged: _busy
                          ? null
                          : (value) => setState(
                              () => _replaceRecoveryCode = value ?? false,
                            ),
                      title: const Text('Also create a new recovery code'),
                      subtitle: const Text(
                        'Do this if someone else may have seen the current code.',
                      ),
                    ),
                    if (_busy)
                      Text(
                        _progress == 0
                            ? 'Changing the key...'
                            : 'Re-encrypted $_progress records...',
                      ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
        ),
      ),
      actions: [
        if (result != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          )
        else ...[
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _busy ? null : _rotate,
            child: const Text('Change key'),
          ),
        ],
      ],
    );
  }

  Future<void> _rotate() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the current recovery code.');
      return;
    }
    RecoveryCode? newCode;
    if (_replaceRecoveryCode) {
      newCode = _newRecoveryCode ??= RecoveryCode.generate();
      final saved = await showRecoveryCodeDialog(
        context,
        code: newCode.formatted,
        serverUrl: widget.serverUrl,
        title: 'Save your new recovery code',
      );
      if (!saved) return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });
    try {
      final result = await ref
          .read(syncServiceProvider)
          .rotateKey(
            recoveryCode: _code.text,
            newRecoveryCode: newCode,
            onProgress: (count) {
              if (mounted) setState(() => _progress = count);
            },
          );
      if (mounted) setState(() => _result = result);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

enum _RecoveryAction { unlock, deleteVault }

class _RecoveryCodeActionDialog extends ConsumerStatefulWidget {
  const _RecoveryCodeActionDialog({required this.action});

  final _RecoveryAction action;

  @override
  ConsumerState<_RecoveryCodeActionDialog> createState() =>
      _RecoveryCodeActionDialogState();
}

class _RecoveryCodeActionDialogState
    extends ConsumerState<_RecoveryCodeActionDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _delete => widget.action == _RecoveryAction.deleteVault;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        _delete ? 'Delete the vault from the server?' : 'Unlock the new key',
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _delete
                  ? 'This permanently erases the encrypted data on the server '
                        'and disconnects every device. Data on each device '
                        'stays. Enter the recovery code to confirm.'
                  : 'The encryption key was changed on another device. Enter '
                        'the recovery code to receive the new key.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'Recovery code',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: _delete
              ? FilledButton.styleFrom(backgroundColor: theme.colorScheme.error)
              : null,
          onPressed: _busy ? null : _submit,
          child: Text(_delete ? 'Delete vault' : 'Unlock'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(syncServiceProvider);
    try {
      if (_delete) {
        await service.deleteVaultFromServer(_code.text);
      } else {
        await service.unlockWithRecoveryCode(_code.text);
      }
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ConflictsDialog extends ConsumerWidget {
  const _ConflictsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts =
        ref.watch(openSyncConflictsProvider).value ?? const <SyncConflict>[];
    return AlertDialog(
      title: const Text('Sync conflicts'),
      content: SizedBox(
        width: 560,
        child: conflicts.isEmpty
            ? const Text('There are no open conflicts.')
            : ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'These records were changed here and on another device '
                    'before syncing. The other device\'s version is in use; '
                    'you can put this device\'s version back instead.',
                  ),
                  const SizedBox(height: 8),
                  for (final conflict in conflicts)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              describeConflict(conflict),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _dateTime.format(conflict.createdAt.toLocal()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => ref
                                      .read(databaseProvider)
                                      .dismissSyncConflict(conflict.id),
                                  child: const Text('Keep other version'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      _restore(context, ref, conflict),
                                  child: const Text(
                                    'Use this device\'s version',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    SyncConflict conflict,
  ) async {
    try {
      await ref
          .read(databaseProvider)
          .restoreLocalVersionFromConflict(conflict.id);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

/// A short, human description of the record a conflict is about.
String describeConflict(SyncConflict conflict) {
  Map<String, dynamic> payloadOf(String json) {
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> && decoded['payload'] is Map
        ? (decoded['payload'] as Map).cast<String, dynamic>()
        : const {};
  }

  final local = payloadOf(conflict.localPayloadJson);
  final payload = local.isNotEmpty
      ? local
      : payloadOf(conflict.serverPayloadJson);
  String text(String key) => '${payload[key] ?? ''}'.trim();

  return switch (conflict.entityType) {
    SyncEntityTypes.congregation => 'Congregation: ${text('name')}',
    SyncEntityTypes.fieldServiceGroup => 'Field service group: ${text('name')}',
    SyncEntityTypes.person =>
      'Publisher: ${[text('firstName'), text('lastName')].where((part) => part.isNotEmpty).join(' ')}',
    SyncEntityTypes.phoneNumber => 'Phone number: ${text('number')}',
    SyncEntityTypes.emergencyContact => 'Emergency contact: ${text('name')}',
    SyncEntityTypes.serviceReport =>
      'Service report for ${text('year')}-${text('month').padLeft(2, '0')}',
    SyncEntityTypes.auxiliaryPioneerPeriod => 'Auxiliary pioneer period',
    _ => conflict.entityType,
  };
}
