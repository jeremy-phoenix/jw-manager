import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:congregation_manager/data/database.dart';
import 'package:congregation_manager/providers/database_provider.dart';
import 'package:congregation_manager/providers/congregation_providers.dart';
import 'package:congregation_manager/providers/group_providers.dart';
import 'package:congregation_manager/providers/person_providers.dart';
import 'package:congregation_manager/providers/service_report_providers.dart';
import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/screens/import/csv_sync_preview_screen.dart';
import 'package:congregation_manager/ui/screens/settings/sync/online_sync_card.dart';
import 'package:congregation_manager/ui/screens/import/import_persons_screen.dart';
import 'package:congregation_manager/services/publisher_record_reader.dart';
import 'package:congregation_manager/ui/theme/layout.dart';
import 'package:congregation_manager/ui/widgets/section_label.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

export 'appearance_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeLabel = switch (ref.watch(themeModeProvider)) {
      ThemeMode.system => 'System theme',
      ThemeMode.light => 'Light theme',
      ThemeMode.dark => 'Dark theme',
    };
    final nameLabel = ref.watch(nameOrderProvider) == NameOrder.lastFirst
        ? 'Last name first'
        : 'First name first';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ReadableWidth(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: '$themeLabel · $nameLabel',
                route: '/settings/appearance',
              ),
            ),
            const SectionLabel(
              'Congregation and data',
              padding: SectionLabel.formPadding,
            ),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.church_outlined,
                    title: 'Congregations',
                    subtitle: 'Manage congregations and their details',
                    route: '/settings/congregations',
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.cloud_sync_outlined,
                    title: 'Online Sync',
                    subtitle: 'End-to-end encrypted sync between devices',
                    route: '/settings/sync',
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'Data Management',
                    subtitle: 'Back up, restore, and import records',
                    route: '/settings/data',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              margin: EdgeInsets.zero,
              child: _SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App information and version',
                route: '/settings/about',
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.push(route),
    );
  }
}

class DataManagementSettingsScreen extends ConsumerWidget {
  const DataManagementSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: ReadableWidth(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const _DatabaseLocationCard(),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Back Up Data'),
                    subtitle: const Text('Save all data to a JSON backup file'),
                    onTap: () => _backupData(context, ref),
                    trailing:
                        MediaQuery.sizeOf(context).width <
                            AppBreakpoints.expanded
                        ? IconButton(
                            tooltip: 'Back Up',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _backupData(context, ref),
                          )
                        : FilledButton.tonalIcon(
                            icon: const Icon(Icons.backup_outlined),
                            label: const Text('Back Up'),
                            onPressed: () => _backupData(context, ref),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_page_outlined),
                    title: const Text('Restore Data'),
                    subtitle: const Text(
                      'Replace current data from a JSON backup',
                    ),
                    onTap: () => _restoreData(context, ref),
                    trailing:
                        MediaQuery.sizeOf(context).width <
                            AppBreakpoints.expanded
                        ? IconButton(
                            tooltip: 'Restore',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _restoreData(context, ref),
                          )
                        : FilledButton.tonalIcon(
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore'),
                            onPressed: () => _restoreData(context, ref),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Import CSV'),
                    subtitle: const Text('Sync publisher data from CSV export'),
                    onTap: () => _importCsv(context, ref),
                    trailing:
                        MediaQuery.sizeOf(context).width <
                            AppBreakpoints.expanded
                        ? IconButton(
                            tooltip: 'Import',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _importCsv(context, ref),
                          )
                        : FilledButton.tonalIcon(
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
                    onTap: () => _importS21(context, ref),
                    trailing:
                        MediaQuery.sizeOf(context).width <
                            AppBreakpoints.expanded
                        ? IconButton(
                            tooltip: 'Import',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _importS21(context, ref),
                          )
                        : FilledButton.tonalIcon(
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
      ),
    );
  }

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final data = await db.exportAllDataAsJson();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(json));

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final result = await FilePicker.saveFile(
        dialogTitle: 'Back Up Data',
        fileName: 'congregation_manager_backup_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (result != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup saved successfully.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'This will replace all current data with the selected backup. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null) {
        final selectedFile = result.files.single;
        if (selectedFile.bytes == null && selectedFile.path == null) return;
        final json = selectedFile.bytes != null
            ? utf8.decode(selectedFile.bytes!)
            : await File(selectedFile.path!).readAsString();
        final decoded = jsonDecode(json);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException(
            'Backup file must contain a JSON object.',
          );
        }

        final db = ref.read(databaseProvider);
        await db.importFromJson(decoded);

        final allCongs = await db.getAllCongregations();
        if (allCongs.isNotEmpty) {
          await ref
              .read(currentCongregationIdProvider.notifier)
              .set(allCongs.first.id);
        } else {
          await ref.read(currentCongregationIdProvider.notifier).clear();
        }

        ref.invalidate(congregationsProvider);
        ref.invalidate(currentCongregationProvider);
        ref.invalidate(fieldServiceGroupsProvider);
        ref.invalidate(personsProvider);
        ref.invalidate(serviceReportsProvider);
        ref.invalidate(serviceYearsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
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
                const SizedBox(height: 8),
                Text(
                  'The database file is not encrypted. Keep it out of '
                  'cloud-synced folders such as OneDrive, Dropbox or Google '
                  'Drive; use Online Sync to share data between devices.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
      body: ReadableWidth(
        child: ListView(
          padding: AppSpacing.page,
          children: const [OnlineSyncCard()],
        ),
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
      body: ReadableWidth(
        child: ListView(
          padding: AppSpacing.page,
          children: [_CongregationListCard()],
        ),
      ),
    );
  }
}

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});
  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  late final _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ReadableWidth(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Congregation Manager'),
                subtitle: FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) => Text(
                    snapshot.hasData
                        ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                        : snapshot.hasError
                        ? 'Version unavailable'
                        : 'Loading version...',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        scrollable: true,
        title: const Text('Delete Congregation'),
        content: Text(
          'Are you sure you want to delete "${cong.name}"?\n\n'
          'This will not delete publishers or groups associated with it, '
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
              foregroundColor: Theme.of(ctx).colorScheme.onError,
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
