import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/sync_providers.dart';
import 'package:congregation_manager/services/sync/server_url.dart';
import 'package:congregation_manager/services/sync/sync_crypto.dart';
import 'package:congregation_manager/services/sync/sync_service.dart';
import 'package:congregation_manager/ui/screens/settings/sync/recovery_code_dialog.dart';

/// Creates a new vault. Returns true when this device is enrolled.
Future<bool> showCreateVaultDialog(
  BuildContext context, {
  String? serverUrl,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateVaultDialog(initialServerUrl: serverUrl),
    ) ??
    false;

/// Joins with an invite from another device. Returns true on success.
Future<bool> showJoinWithInviteDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _JoinDialog(useRecoveryCode: false),
    ) ??
    false;

/// Joins with the recovery code. Returns true on success.
Future<bool> showRecoverWithCodeDialog(
  BuildContext context, {
  String? serverUrl,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _JoinDialog(useRecoveryCode: true, initialServerUrl: serverUrl),
    ) ??
    false;

class _CreateVaultDialog extends ConsumerStatefulWidget {
  const _CreateVaultDialog({this.initialServerUrl});

  final String? initialServerUrl;

  @override
  ConsumerState<_CreateVaultDialog> createState() => _CreateVaultDialogState();
}

class _CreateVaultDialogState extends ConsumerState<_CreateVaultDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _serverUrl = TextEditingController(text: widget.initialServerUrl);
  final _secret = TextEditingController();
  final _deviceLabel = TextEditingController(text: defaultDeviceLabel());
  RecoveryCode? _recoveryCode;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _serverUrl.dispose();
    _secret.dispose();
    _deviceLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create an encrypted vault'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'A new encryption key is created on this device and all '
                  'congregation data here is uploaded, encrypted. The server '
                  'never receives the key.',
                ),
                const SizedBox(height: 16),
                _ServerUrlField(controller: _serverUrl, enabled: !_busy),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secret,
                  enabled: !_busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Registration secret',
                    helperText: 'Set by the server administrator.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter the registration secret.'
                      : null,
                ),
                const SizedBox(height: 12),
                _DeviceLabelField(controller: _deviceLabel, enabled: !_busy),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorText(_error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy ? const _ButtonProgress() : const Text('Create vault'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // The code is shown and confirmed before the vault exists, so it can
    // never be lost to a crash halfway through. A retry reuses it.
    final firstAttempt = _recoveryCode == null;
    final code = _recoveryCode ??= RecoveryCode.generate();
    if (firstAttempt) {
      final saved = await showRecoveryCodeDialog(
        context,
        code: code.formatted,
        serverUrl: _serverUrl.text.trim(),
      );
      if (!saved) {
        _recoveryCode = null;
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(syncServiceProvider);
      await service.createVault(
        serverUrl: _serverUrl.text,
        registrationSecret: _secret.text,
        deviceLabel: _deviceLabel.text.trim(),
        recoveryCode: code,
      );
      // Upload in the background; the Online Sync card shows progress and
      // any error, and the scheduler retries.
      unawaited(service.syncNow().then<void>((_) {}, onError: (_) {}));
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _JoinDialog extends ConsumerStatefulWidget {
  const _JoinDialog({required this.useRecoveryCode, this.initialServerUrl});

  final bool useRecoveryCode;
  final String? initialServerUrl;

  @override
  ConsumerState<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends ConsumerState<_JoinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _serverUrl = TextEditingController(text: widget.initialServerUrl);
  final _secretInput = TextEditingController();
  final _deviceLabel = TextEditingController(text: defaultDeviceLabel());
  bool? _hasLocalData;
  LocalDataChoice? _localData;
  bool _busy = false;
  String? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).hasLocalCongregationData().then((hasData) {
      if (mounted) setState(() => _hasLocalData = hasData);
    });
  }

  @override
  void dispose() {
    _serverUrl.dispose();
    _secretInput.dispose();
    _deviceLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recovery = widget.useRecoveryCode;
    final needsChoice = _hasLocalData ?? false;
    return AlertDialog(
      title: Text(
        recovery ? 'Join with the recovery code' : 'Join with an invite',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  recovery
                      ? 'Use this when no other device is available to create '
                            'an invite. The recovery code unlocks the vault key.'
                      : 'On a device that already syncs, open Settings > '
                            'Online Sync > Invite a device, then scan or paste '
                            'the invite here.',
                ),
                const SizedBox(height: 16),
                if (recovery) ...[
                  _ServerUrlField(controller: _serverUrl, enabled: !_busy),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _secretInput,
                  enabled: !_busy,
                  minLines: recovery ? 2 : 3,
                  maxLines: recovery ? 3 : 5,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    labelText: recovery ? 'Recovery code' : 'Invite',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    suffixIcon: IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.content_paste),
                      onPressed: _busy ? null : _paste,
                    ),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? (recovery
                            ? 'Enter the recovery code.'
                            : 'Paste the invite.')
                      : null,
                ),
                const SizedBox(height: 12),
                _DeviceLabelField(controller: _deviceLabel, enabled: !_busy),
                if (needsChoice) ...[
                  const SizedBox(height: 16),
                  Text(
                    'This device already has congregation data.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  RadioGroup<LocalDataChoice>(
                    groupValue: _localData,
                    onChanged: (value) {
                      if (!_busy) setState(() => _localData = value);
                    },
                    child: const Column(
                      children: [
                        RadioListTile<LocalDataChoice>(
                          contentPadding: EdgeInsets.zero,
                          value: LocalDataChoice.replace,
                          title: Text('Replace it with the synced data'),
                          subtitle: Text(
                            'Recommended for a new device. A backup copy of '
                            'the current database is saved first.',
                          ),
                        ),
                        RadioListTile<LocalDataChoice>(
                          contentPadding: EdgeInsets.zero,
                          value: LocalDataChoice.merge,
                          title: Text('Add it to the synced data'),
                          subtitle: Text(
                            'Uploads records the vault does not have. '
                            'Publishers entered on both devices will appear twice.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_progress != null) ...[
                  const SizedBox(height: 12),
                  Text(_progress!),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorText(_error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _busy ||
                  _hasLocalData == null ||
                  (needsChoice && _localData == null)
              ? null
              : _submit,
          child: _busy ? const _ButtonProgress() : const Text('Join'),
        ),
      ],
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _secretInput.text = data!.text!.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final choice = _localData ?? LocalDataChoice.merge;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 'Joining the vault and downloading its data...';
    });
    final service = ref.read(syncServiceProvider);
    try {
      if (widget.useRecoveryCode) {
        await service.recoverWithCode(
          serverUrl: _serverUrl.text,
          recoveryCode: _secretInput.text,
          deviceLabel: _deviceLabel.text.trim(),
          localData: choice,
        );
      } else {
        await service.joinWithInvite(
          invite: _secretInput.text,
          deviceLabel: _deviceLabel.text.trim(),
          localData: choice,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      // Enrolled but the first download failed: keep the result, the
      // background sync retries.
      final settings = await ref.read(databaseProvider).getSyncSettings();
      if (settings.isEnabled && mounted) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _error = '$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }
}

class _ServerUrlField extends StatelessWidget {
  const _ServerUrlField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.url,
    autocorrect: false,
    decoration: const InputDecoration(
      labelText: 'Server address',
      hintText: 'https://sync.example.org',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.link),
    ),
    validator: (value) {
      try {
        parseSyncServerUrl(value ?? '');
        return null;
      } on FormatException catch (error) {
        return error.message;
      }
    },
  );
}

class _DeviceLabelField extends StatelessWidget {
  const _DeviceLabelField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    maxLength: 60,
    decoration: const InputDecoration(
      labelText: 'Name for this device',
      helperText: 'Shown in the device list. Stored encrypted.',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.devices_outlined),
    ),
    validator: (value) =>
        (value ?? '').trim().isEmpty ? 'Enter a name for this device.' : null,
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: TextStyle(color: Theme.of(context).colorScheme.error),
  );
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
