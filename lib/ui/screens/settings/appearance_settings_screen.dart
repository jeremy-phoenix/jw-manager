import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:congregation_manager/providers/settings_providers.dart';
import 'package:congregation_manager/ui/theme/app_theme.dart';
import 'package:congregation_manager/ui/theme/layout.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final nameOrder = ref.watch(nameOrderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ReadableWidth(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= AppBreakpoints.medium &&
                MediaQuery.textScalerOf(context).scale(14) <= 18;
            return ListView(
              padding: AppSpacing.page,
              children: [
                const _PreferenceHeading(title: 'Theme'),
                _ChoiceGroup(
                  horizontal: wide,
                  children: [
                    for (final mode in ThemeMode.values)
                      _PreferenceChoice(
                        key: ValueKey('theme-${mode.name}'),
                        title: switch (mode) {
                          ThemeMode.system => 'System',
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                        },
                        subtitle: switch (mode) {
                          ThemeMode.system => 'Follow device',
                          ThemeMode.light => 'Always light',
                          ThemeMode.dark => 'Always dark',
                        },
                        selected: themeMode == mode,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(mode),
                        preview: _ThemePreview(mode: mode, compact: !wide),
                        vertical: wide,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _PreferenceHeading(title: 'Name display order'),
                _ChoiceGroup(
                  horizontal: wide,
                  children: [
                    for (final order in NameOrder.values)
                      _PreferenceChoice(
                        key: ValueKey('name-order-${order.name}'),
                        title: order == NameOrder.lastFirst
                            ? 'Last name first'
                            : 'First name first',
                        subtitle: formatPersonName('Alex', 'Rivera', order),
                        selected: nameOrder == order,
                        onTap: () =>
                            ref.read(nameOrderProvider.notifier).set(order),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Changes are saved automatically.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreferenceHeading extends StatelessWidget {
  const _PreferenceHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.horizontal, required this.children});
  final bool horizontal;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => horizontal
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
            ],
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              child,
            ],
          ],
        );
}

class _PreferenceChoice extends StatelessWidget {
  const _PreferenceChoice({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.preview,
    this.vertical = false,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? preview;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selected ? foreground : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    final selection = Icon(
      selected ? Icons.check_circle : Icons.radio_button_unchecked,
      size: 22,
      color: selected ? colors.primary : colors.outline,
    );
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? colors.secondaryContainer
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: vertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (preview != null) ExcludeSemantics(child: preview!),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: label),
                          const SizedBox(width: AppSpacing.sm),
                          selection,
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (preview != null) ...[
                        SizedBox(
                          width: 64,
                          child: ExcludeSemantics(child: preview!),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(child: label),
                      const SizedBox(width: AppSpacing.sm),
                      selection,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A decorative miniature of the app, independent of the current theme.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode, required this.compact});
  final ThemeMode mode;
  final bool compact;
  static final _light = AppTheme.light().colorScheme;
  static final _dark = AppTheme.dark().colorScheme;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      height: compact ? 48 : 72,
      child: mode == ThemeMode.system
          ? Row(
              children: [
                Expanded(child: _pane(_light)),
                Expanded(child: _pane(_dark)),
              ],
            )
          : _pane(mode == ThemeMode.light ? _light : _dark),
    ),
  );

  Widget _pane(ColorScheme colors) => ColoredBox(
    color: colors.surface,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 5,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          SizedBox(height: compact ? 4 : 5),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    ),
  );
}
