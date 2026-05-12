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
  final String fileNameTemplate;

  const ExportRecordsOptions({
    required this.serviceYear,
    required this.groupByRole,
    required this.groupByFieldServiceGroup,
    required this.flattenPdf,
    required this.twoYearsPerPage,
    required this.onlyUpToPreviousMonth,
    required this.fileNameTemplate,
  });
}

/// Dialog that lets the user configure options before exporting S-21 records.
class ExportRecordsDialog extends StatefulWidget {
  const ExportRecordsDialog({super.key});

  /// Show the dialog and return the selected options, or null if cancelled.
  static Future<ExportRecordsOptions?> show(BuildContext context) {
    return showDialog<ExportRecordsOptions>(
      context: context,
      builder: (_) => const ExportRecordsDialog(),
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
    return AlertDialog(
      scrollable: true,
      title: const Text('Export Publisher Records'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service year dropdown
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Service Year',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedYear,
              items: _serviceYears
                  .map(
                    (y) =>
                        DropdownMenuItem(value: y, child: Text('${y - 1}–$y')),
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
            const SizedBox(height: 12),

            // File name template
            TextField(
              controller: _templateController,
              decoration: const InputDecoration(
                labelText: 'File name template',
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
