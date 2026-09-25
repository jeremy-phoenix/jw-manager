import 'package:flutter/material.dart';

import 'package:congregation_manager/ui/theme/status_colors.dart';

/// Active or inactive status for table cells. The two states differ in shape
/// as well as color, and the tooltip names them.
class ActiveStatusIcon extends StatelessWidget {
  const ActiveStatusIcon({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final label = isActive ? 'Active' : 'Inactive';
    return Tooltip(
      message: label,
      child: Icon(
        isActive ? Icons.check_circle : Icons.remove_circle_outline,
        size: 18,
        color: isActive
            ? StatusColors.of(context).success
            : Theme.of(context).colorScheme.outline,
        semanticLabel: label,
      ),
    );
  }
}

/// A neutral "Inactive" label for list rows, where active is the default and
/// needs no marker.
class InactiveLabel extends StatelessWidget {
  const InactiveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
