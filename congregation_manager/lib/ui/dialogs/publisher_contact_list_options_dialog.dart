import 'package:flutter/material.dart';

/// Options shown before previewing the Publisher Contact List.
class PublisherContactListOptionsDialog extends StatefulWidget {
  const PublisherContactListOptionsDialog({super.key});

  /// Returns whether inactive publishers should start on a new page, or null
  /// when the dialog is cancelled.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const PublisherContactListOptionsDialog(),
    );
  }

  @override
  State<PublisherContactListOptionsDialog> createState() =>
      _PublisherContactListOptionsDialogState();
}

class _PublisherContactListOptionsDialogState
    extends State<PublisherContactListOptionsDialog> {
  bool _startInactiveOnNewPage = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Publisher Contact List'),
      content: SizedBox(
        width: 360,
        child: CheckboxListTile(
          title: const Text('Start inactive publishers on a new page'),
          subtitle: const Text(
            'Keeps the active and inactive sections on separate pages.',
          ),
          value: _startInactiveOnNewPage,
          onChanged: (value) =>
              setState(() => _startInactiveOnNewPage = value ?? false),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_startInactiveOnNewPage),
          child: const Text('Preview'),
        ),
      ],
    );
  }
}
