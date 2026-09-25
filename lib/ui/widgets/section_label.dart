import 'package:flutter/material.dart';

/// A small primary-colored heading that starts a group of settings or fields.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 6),
  });

  /// Padding for a label inside a form, aligned with the fields' edge.
  static const formPadding = EdgeInsets.fromLTRB(4, 24, 4, 8);

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
