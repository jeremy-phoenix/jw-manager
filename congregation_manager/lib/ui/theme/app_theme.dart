import 'package:flutter/material.dart';

import 'package:congregation_manager/ui/theme/status_colors.dart';

/// App-wide Material 3 theme, modeled on gallery_cloud: flat tonal surfaces,
/// rounded containers, and filled inputs.
abstract final class AppTheme {
  static const seedColor = Colors.indigo;

  static const double cardRadius = 24;
  static const double controlRadius = 18;
  static const double dialogRadius = 28;

  static ThemeData light() => _build(
    ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
  );

  static ThemeData _build(ColorScheme scheme) {
    // Keep the platform font. Use consistent control geometry on desktop
    // and mobile; dense table editors opt out locally.
    final base = ThemeData(colorScheme: scheme);
    // A raw ThemeData text theme has no font sizes until Theme.of localizes
    // it, so component styles built from it need the geometry merged in.
    final textTheme = ThemeData.localize(
      base,
      base.typography.englishLike,
    ).textTheme;
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 8 : null,
        barrierColor: isDark ? Colors.black.withValues(alpha: 0.64) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? scheme.surfaceContainerHigh : null,
        surfaceTintColor: isDark ? Colors.transparent : null,
        elevation: isDark ? 8 : 3,
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(color: scheme.onSurface, fontSize: 14),
      ),
      // gallery_cloud uses an outline border here; an underline-type base
      // border keeps floating labels inside the fill instead of across its
      // top edge. Grids opt out through StickyDataTable.
      inputDecorationTheme: InputDecorationTheme(
        helperMaxLines: 3,
        errorMaxLines: 3,
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        disabledBorder: _fieldBorder(),
        focusedBorder: _fieldOutline(scheme.primary, 2),
        errorBorder: _fieldOutline(scheme.error, 1),
        focusedErrorBorder: _fieldOutline(scheme.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(48, 48),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(48, 48),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: controlShape,
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(48)),
          shape: WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        headingTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.65),
        space: 1,
      ),
      extensions: [StatusColors.fromBrightness(scheme.brightness)],
    );
  }

  static InputBorder _fieldBorder() => const UnderlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(controlRadius)),
    borderSide: BorderSide.none,
  );

  static InputBorder _fieldOutline(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(controlRadius),
        borderSide: BorderSide(color: color, width: width),
      );
}
