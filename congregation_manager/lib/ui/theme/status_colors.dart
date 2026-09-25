import 'package:flutter/material.dart';

/// Semantic colors the Material color scheme has no slot for. They come from
/// fixed seed colors, so they follow Material's tones in light and dark mode.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  factory StatusColors.fromBrightness(Brightness brightness) {
    final green = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: brightness,
    );
    final amber = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB26A00),
      brightness: brightness,
    );
    return StatusColors(
      success: green.primary,
      successContainer: green.primaryContainer,
      onSuccessContainer: green.onPrimaryContainer,
      warning: amber.primary,
      warningContainer: amber.primaryContainer,
      onWarningContainer: amber.onPrimaryContainer,
    );
  }

  static final _light = StatusColors.fromBrightness(Brightness.light);
  static final _dark = StatusColors.fromBrightness(Brightness.dark);

  /// The theme's status colors, or defaults for its brightness when the theme
  /// was not built by [AppTheme] (for example in widget tests).
  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ??
        (theme.brightness == Brightness.dark ? _dark : _light);
  }

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  @override
  StatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return StatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}
