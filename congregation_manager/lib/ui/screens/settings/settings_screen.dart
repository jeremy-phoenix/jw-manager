import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/providers/sync_providers.dart';
import 'package:congregation_manager/ui/screens/import/csv_sync_preview_screen.dart';
import 'package:congregation_manager/ui/screens/import/import_persons_screen.dart';
import 'package:congregation_manager/services/publisher_record_reader.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme and name display order',
                  route: '/settings/appearance',
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Data Management',
                  subtitle: 'Import, export, and database location',
                  route: '/settings/data',
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Online Sync',
                  subtitle: 'Cloud server, token, and sync status',
                  route: '/settings/sync',
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.church_outlined,
                  title: 'Congregations',
                  subtitle: 'Select, edit, or add congregations',
                  route: '/settings/congregations',
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version',
                  route: '/settings/about',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Theme'),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.settings_brightness),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(value.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Name Display Order'),
                  SegmentedButton<NameOrder>(
                    segments: NameOrder.values
                        .map(
                          (order) => ButtonSegment(
                            value: order,
                            label: Text(order.label),
                          ),
                        )
                        .toList(),
                    selected: {ref.watch(nameOrderProvider)},
                    onSelectionChanged: (value) {
                      ref.read(nameOrderProvider.notifier).set(value.first);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataManagementSettingsScreen extends ConsumerWidget {
  const DataManagementSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _DatabaseLocationCard(),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Export all data as a JSON backup file'),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    onPressed: () => _exportData(context, ref),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore data from a JSON backup'),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Import'),
                    onPressed: () => _importData(context, ref),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Import CSV'),
                  subtitle: const Text('Sync publisher data from CSV export'),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Import'),
                    onPressed: () => _importCsv(context, ref),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Import S-21 Forms'),
                  subtitle: const Text(
                    'Import publisher records from S-21 PDFs',
                  ),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Import'),
                    onPressed: () => _importS21(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final data = await db.exportAllDataAsJson();
      final json = jsonEncode(data);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final result = await FilePicker.saveFile(
        dialogTitle: 'Export Backup',
        fileName: 'congregation_manager_backup_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        await File(result).writeAsString(json);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data exported successfully.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will replace all current data with the imported backup. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final json = await file.readAsString();
        final data = jsonDecode(json) as Map<String, dynamic>;

        final db = ref.read(databaseProvider);
        await db.importFromJson(data);

        // Set current congregation to the first imported congregation
        final allCongs = await db.getAllCongregations();
        if (allCongs.isNotEmpty) {
          await ref
              .read(currentCongregationIdProvider.notifier)
              .set(allCongs.first.id);
        }
        ref.invalidate(congregationsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CsvSyncPreviewScreen(csvFilePath: result.files.single.path!),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _importS21(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final importedPersons = <ImportedPerson>[];

        for (final file in result.files) {
          if (file.path == null) continue;
          final imported = await PublisherRecordReader.readFromFile(file.path!);
          if (imported != null) {
            importedPersons.add(imported);
          }
        }

        if (importedPersons.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No valid publisher records found in the selected files.',
                ),
              ),
            );
          }
          return;
        }

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ImportPersonsScreen(importedPersons: importedPersons),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}

class _DatabaseLocationCard extends ConsumerStatefulWidget {
  const _DatabaseLocationCard();

  @override
  ConsumerState<_DatabaseLocationCard> createState() =>
      _DatabaseLocationCardState();
}

class _DatabaseLocationCardState extends ConsumerState<_DatabaseLocationCard> {
  late Future<DatabaseLocationInfo> _locationFuture;

  @override
  void initState() {
    super.initState();
    _locationFuture = AppDatabase.getDatabaseLocationInfo();
  }

  void _refreshLocation() {
    setState(() {
      _locationFuture = AppDatabase.getDatabaseLocationInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DatabaseLocationInfo>(
      future: _locationFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Database Location'),
              subtitle: Text('${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final location = snapshot.data!;
        final theme = Theme.of(context);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Database Location'),
                  subtitle: Text(
                    location.isCustom
                        ? 'Custom folder'
                        : 'Application support folder',
                  ),
                ),
                SelectableText(
                  location.currentPath,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.drive_folder_upload_outlined),
                      label: const Text('Change Folder'),
                      onPressed: () => _chooseFolder(location),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Use Default'),
                      onPressed: location.isCustom
                          ? () => _useDefaultLocation(location)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _chooseFolder(DatabaseLocationInfo location) async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Choose Database Folder',
        initialDirectory: File(location.currentPath).parent.path,
        lockParentWindow: true,
      );
      if (selectedDirectory == null) return;

      final targetPath = AppDatabase.databasePathInDirectory(selectedDirectory);
      final overwrite = await _confirmOverwriteIfNeeded(
        targetPath: targetPath,
        currentPath: location.currentPath,
      );
      if (overwrite == null) return;

      final newPath = await AppDatabase.changeDatabaseDirectory(
        openDatabase: ref.read(databaseProvider),
        directoryPath: selectedDirectory,
        overwrite: overwrite,
      );

      if (!mounted) return;
      _refreshLocation();
      await _showRestartDialog(newPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database location update failed: $error')),
      );
    }
  }

  Future<void> _useDefaultLocation(DatabaseLocationInfo location) async {
    try {
      final overwrite = await _confirmOverwriteIfNeeded(
        targetPath: location.defaultPath,
        currentPath: location.currentPath,
      );
      if (overwrite == null) return;

      final newPath = await AppDatabase.resetDatabaseDirectory(
        openDatabase: ref.read(databaseProvider),
        overwrite: overwrite,
      );

      if (!mounted) return;
      _refreshLocation();
      await _showRestartDialog(newPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database location reset failed: $error')),
      );
    }
  }

  Future<bool?> _confirmOverwriteIfNeeded({
    required String targetPath,
    required String currentPath,
  }) async {
    if (targetPath == currentPath || !await File(targetPath).exists()) {
      return false;
    }

    if (!mounted) return null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace Database File?'),
        content: const Text(
          'A database file already exists in that folder. Replace it with the current database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    return confirmed == true ? true : null;
  }

  Future<void> _showRestartDialog(String newPath) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Database Location Updated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restart the app before making more data changes. The app will use this database file after restart.',
            ),
            const SizedBox(height: 12),
            SelectableText(newPath),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class OnlineSyncSettingsScreen extends StatelessWidget {
  const OnlineSyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [_OnlineSyncCard()],
      ),
    );
  }
}

class CongregationSettingsScreen extends StatelessWidget {
  const CongregationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Congregations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [_CongregationListCard()],
      ),
    );
  }
}

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Congregation Manager'),
              subtitle: Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineSyncCard extends ConsumerStatefulWidget {
  const _OnlineSyncCard();

  @override
  ConsumerState<_OnlineSyncCard> createState() => _OnlineSyncCardState();
}

class _OnlineSyncCardState extends ConsumerState<_OnlineSyncCard> {
  final _serverUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _enabled = false;
  bool _syncing = false;
  String? _loadedDeviceId;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(syncSettingsProvider);
    final pendingCount =
        ref.watch(pendingSyncOperationCountProvider).value ?? 0;
    final conflictCount = ref.watch(openSyncConflictCountProvider).value ?? 0;

    return settingsAsync.when(
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
      data: (settings) {
        if (_loadedDeviceId != settings.deviceId) {
          _enabled = settings.isEnabled;
          _serverUrlController.text = settings.serverUrl ?? '';
          _tokenController.text = settings.bearerToken ?? '';
          _loadedDeviceId = settings.deviceId;
        }

        final lastSync = settings.lastSyncAt == null
            ? 'Never'
            : DateFormat.yMMMd().add_jm().format(
                settings.lastSyncAt!.toLocal(),
              );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    _enabled ? Icons.cloud_done : Icons.cloud_off,
                  ),
                  title: const Text('Cloud Sync'),
                  subtitle: Text('Last sync: $lastSync'),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _serverUrlController,
                  enabled: _enabled,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  enabled: _enabled,
                  decoration: const InputDecoration(
                    labelText: 'Sync Token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.pending_actions),
                      label: Text('$pendingCount pending'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.report_problem_outlined),
                      label: Text('$conflictCount conflicts'),
                    ),
                    if (settings.lastError != null)
                      Chip(
                        avatar: Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        label: Text(settings.lastError!),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      onPressed: _saveSettings,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sync Now'),
                      onPressed: !_enabled || _syncing ? null : _syncNow,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    await ref
        .read(databaseProvider)
        .saveSyncSettings(
          isEnabled: _enabled,
          serverUrl: _serverUrlController.text,
          bearerToken: _tokenController.text,
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sync settings saved.')));
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await _saveSettings();
      final result = await ref.read(syncServiceProvider).syncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync complete: ${result.pushed} pushed, ${result.pulled} pulled, ${result.conflicts} conflicts.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _CongregationListCard extends ConsumerWidget {
  const _CongregationListCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final congregationsAsync = ref.watch(congregationsProvider);
    final currentId = ref.watch(currentCongregationIdProvider);

    return congregationsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text('Error loading congregations: $e'),
        ),
      ),
      data: (congregations) => Card(
        child: Column(
          children: [
            ...congregations.map(
              (cong) => ListTile(
                leading: Icon(
                  cong.id == currentId ? Icons.church : Icons.church_outlined,
                  color: cong.id == currentId
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  cong.name.isEmpty ? '(Unnamed)' : cong.name,
                  style: cong.id == currentId
                      ? TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                subtitle:
                    [cong.number, cong.city].where((s) => s.isNotEmpty).isEmpty
                    ? null
                    : Text(
                        [
                          cong.number,
                          cong.city,
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () =>
                          context.push('/congregations/edit/${cong.id}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: cong.id == currentId
                          ? null
                          : () => _deleteCongregation(context, ref, cong),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Congregation'),
              onTap: () => context.push('/congregations/new'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCongregation(
    BuildContext context,
    WidgetRef ref,
    Congregation cong,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Congregation'),
        content: Text(
          'Are you sure you want to delete "${cong.name}"?\n\n'
          'This will not delete persons or groups associated with it, '
          'but they will no longer be linked to a congregation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    await db.deleteCongregation(cong.id);
    ref.invalidate(congregationsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${cong.name}" deleted.')));
    }
  }
}
