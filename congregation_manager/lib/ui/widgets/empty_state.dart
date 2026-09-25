import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:congregation_manager/ui/theme/layout.dart';

/// Centered message for empty lists and failed loads: an icon, a title, an
/// optional explanation and an optional action (gallery_cloud's empty panel).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  }) : error = null;

  /// A failed load: a plain-language [title] with the error's text in small
  /// print, which is still useful when someone asks for help.
  const EmptyState.error({
    super.key,
    required this.title,
    required Object this.error,
    this.action,
  }) : icon = Icons.error_outline,
       message = null;

  final IconData icon;
  final String title;
  final String? message;
  final Object? error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppContentWidth.message),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: error == null ? colors.primary : colors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: content),
          );
        }
        // Scrolls instead of overflowing when the space is short.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0,
                constraints.maxHeight - 2 * AppSpacing.xxl,
              ),
            ),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
