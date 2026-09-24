import 'package:flutter/material.dart';
import 'package:congregation_manager/services/publisher_record_writer.dart';

/// Result returned from the export records options dialog.
class ExportRecordsOptions {
  final int serviceYear;
  final bool groupByRole;
  final bool groupByFieldServiceGroup;
  final bool flattenPdf;
  final bool twoYearsPerPage;
  final bool onlyUpToPreviousMonth;
  final bool includeInactive;
  final String fileNameTemplate;

  const ExportRecordsOptions({
    required this.serviceYear,
    required this.groupByRole,
    required this.groupByFieldServiceGroup,
    required this.flattenPdf,
    required this.twoYearsPerPage,
    required this.onlyUpToPreviousMonth,
    required this.includeInactive,
    required this.fileNameTemplate,
  });
}

/// Dialog that lets the user configure options before exporting S-21 records.
class ExportRecordsDialog extends StatefulWidget {
  const ExportRecordsDialog({super.key, this.selectionCount});

  /// Number of publishers picked in the list, or null when exporting everyone.
  final int? selectionCount;

  /// Show the dialog and return the selected options, or null if cancelled.
  static Future<ExportRecordsOptions?> show(
    BuildContext context, {
    int? selectionCount,
  }) {
    return showDialog<ExportRecordsOptions>(
      context: context,
      builder: (_) => ExportRecordsDialog(selectionCount: selectionCount),
    );
  }

  @override
  State<ExportRecordsDialog> createState() => _ExportRecordsDialogState();
}

class _ExportRecordsDialogState extends State<ExportRecordsDialog> {
  static const _defaultTemplate = '{LastName}, {FirstName}';

  late final List<int> _serviceYears;
  int? _selectedYear;
  bool _groupByRole = true;
  bool _groupByFieldServiceGroup = false;
  bool _flattenPdf = false;
  bool _twoYearsPerPage = false;
  bool _onlyUpToPreviousMonth = true;
  bool _includeInactive = false;
  late final TextEditingController _templateController;

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController(text: _defaultTemplate);

    // Build list of service years (current + 4 previous).
    final currentYear = PublisherRecordWriter.getCurrentServiceYear();
    _serviceYears = List.generate(5, (i) => currentYear - i);
    _selectedYear = currentYear;
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectionCount = widget.selectionCount;
    return AlertDialog(
      scrollable: true,
      title: const Text('Export Publisher Records'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectionCount != null) ...[
              Text(
                'Exporting $selectionCount selected publisher(s).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            // Service year dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Service Year',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedYear,
              items: _serviceYears
                  .map(
                    (y) => DropdownMenuItem(value: y, child: Text('$y')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedYear = v),
            ),
            const SizedBox(height: 16),

            // Checkboxes
            CheckboxListTile(
              title: const Text('Group by role'),
              subtitle: const Text(
                'Creates subfolders: Elders, MS, RP, SP, Publishers',
              ),
              value: _groupByRole,
              onChanged: (v) => setState(() {
                _groupByRole = v ?? true;
                if (_groupByRole) {
                  _groupByFieldServiceGroup = false;
                }
              }),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Group by field service group'),
              subtitle: const Text(
                'Creates subfolders for each field service group',
              ),
              value: _groupByFieldServiceGroup,
              onChanged: (v) => setState(() {
                _groupByFieldServiceGroup = v ?? false;
                if (_groupByFieldServiceGroup) {
                  _groupByRole = false;
                }
              }),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Flatten (non-editable)'),
              subtitle: const Text('PDF form fields become static text'),
              value: _flattenPdf,
              onChanged: (v) => setState(() => _flattenPdf = v ?? false),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Two service years per page'),
              subtitle: const Text(
                'Places the selected and previous service years on one PDF',
              ),
              value: _twoYearsPerPage,
              onChanged: (v) => setState(() => _twoYearsPerPage = v ?? false),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Only up to previous month'),
              subtitle: const Text('Excludes current and future months'),
              value: _onlyUpToPreviousMonth,
              onChanged: (v) =>
                  setState(() => _onlyUpToPreviousMonth = v ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            // A selection already names who to export, active or not.
            if (selectionCount == null)
              CheckboxListTile(
                title: const Text('Include inactive publishers'),
                subtitle: const Text(
                  'Exports their records into a separate Inactive folder',
                ),
                value: _includeInactive,
                onChanged: (v) => setState(() => _includeInactive = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            const SizedBox(height: 12),

            // Record name template
            TextField(
              controller: _templateController,
              decoration: const InputDecoration(
                labelText: 'Record name template',
                border: OutlineInputBorder(),
                helperText: '{FirstName}, {LastName}, {FullName}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedYear == null
              ? null
              : () {
                  final template = _templateController.text.trim().isEmpty
                      ? _defaultTemplate
                      : _templateController.text.trim();
                  Navigator.of(context).pop(
                    ExportRecordsOptions(
                      serviceYear: _selectedYear!,
                      groupByRole: _groupByRole,
                      groupByFieldServiceGroup: _groupByFieldServiceGroup,
                      flattenPdf: _flattenPdf,
                      twoYearsPerPage: _twoYearsPerPage,
                      onlyUpToPreviousMonth: _onlyUpToPreviousMonth,
                      includeInactive: _includeInactive,
                      fileNameTemplate: template,
                    ),
                  );
                },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
