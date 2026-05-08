import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:congregation_manager/services/export_progress.dart';

class ExportProgressDialog extends StatelessWidget {
  final String title;
  final ValueListenable<ExportProgress> progressListenable;

  const ExportProgressDialog({
    super.key,
    required this.title,
    required this.progressListenable,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: ValueListenableBuilder<ExportProgress>(
          valueListenable: progressListenable,
          builder: (context, progress, child) {
            final countLabel = progress.countLabel;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: progress.value),
                const SizedBox(height: 16),
                Text(
                  progress.message,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (progress.detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    progress.detail!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (countLabel != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    countLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
