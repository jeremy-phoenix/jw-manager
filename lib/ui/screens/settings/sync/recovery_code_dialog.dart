import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shows a recovery code and returns true once the person confirms they
/// saved it. The code is never stored by the app, so this is the only time
/// it can be copied or printed.
Future<bool> showRecoveryCodeDialog(
  BuildContext context, {
  required String code,
  required String serverUrl,
  String title = 'Save your recovery code',
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _RecoveryCodeDialog(code: code, serverUrl: serverUrl, title: title),
    ) ??
    false;

class _RecoveryCodeDialog extends StatefulWidget {
  const _RecoveryCodeDialog({
    required this.code,
    required this.serverUrl,
    required this.title,
  });

  final String code;
  final String serverUrl;
  final String title;

  @override
  State<_RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<_RecoveryCodeDialog> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'You need this code to add a device without an invite, to '
                'unlock devices after the encryption key changes, and to get '
                'your data back if every device is lost. Nobody can reset it, '
                'not even the server administrator.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  widget.code,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: widget.code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Copied. Paste it into your password manager, '
                            'then clear the clipboard.',
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print or save as PDF'),
                    onPressed: () => printRecoveryCode(
                      code: widget.code,
                      serverUrl: widget.serverUrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Keep it on paper or in a password manager, not on the same '
                'devices. Anyone with this code and access to your server '
                'can read the congregation data.',
                style: theme.textTheme.bodySmall,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _saved,
                onChanged: (value) => setState(() => _saved = value ?? false),
                title: const Text('I have saved the recovery code'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saved ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

Future<void> printRecoveryCode({
  required String code,
  required String serverUrl,
}) async {
  final document = pw.Document();
  final created = DateFormat.yMMMMd().format(DateTime.now());
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Congregation Manager - Sync Recovery Code',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Created $created'),
          pw.Text('Server: $serverUrl'),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text(
              code,
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 15),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Keep this page somewhere safe, away from your devices.',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Bullet(
            text:
                'Needed to add a device without an invite, or after '
                'losing every device.',
          ),
          pw.Bullet(
            text: 'Needed on each device after the encryption key is changed.',
          ),
          pw.Bullet(text: 'Needed to delete the vault from the server.'),
          pw.Bullet(
            text:
                'Anyone with this code and access to the server can read '
                'the congregation data. Nobody can reset it.',
          ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'Congregation Manager recovery code',
    onLayout: (_) => document.save(),
  );
}

/// A default name for this device, shown in the device list of the vault.
/// It is encrypted before upload.
String defaultDeviceLabel() {
  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.windows => 'Windows PC',
    TargetPlatform.macOS => 'Mac',
    TargetPlatform.linux => 'Linux PC',
    TargetPlatform.android => 'Android device',
    TargetPlatform.iOS => 'iPhone or iPad',
    _ => 'Device',
  };
  if (kIsWeb) return platform;
  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  return isDesktop ? '$platform (${Platform.localHostname})' : platform;
}
