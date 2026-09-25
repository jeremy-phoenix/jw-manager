import 'package:flutter/widgets.dart';

/// Spacing scale for padding and gaps, shared with gallery_cloud.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Scrolling page content: a small top inset and a generous bottom one so
  /// the last item clears the window edge.
  static const EdgeInsets page = EdgeInsets.fromLTRB(lg, sm, lg, xxl);

  /// Lists whose tiles already inset their content by 16.
  static const EdgeInsets listPage = EdgeInsets.fromLTRB(sm, sm, sm, 40);
}

/// Window widths where layouts change (Material 3 window size classes).
abstract final class AppBreakpoints {
  /// Navigation rail instead of a bottom bar, tables instead of cards.
  static const double medium = 600;

  /// Room for inline selection actions.
  static const double expanded = 840;

  /// Extended rail and labeled app-bar actions.
  static const double large = 1200;
}

/// Maximum widths that keep forms and text readable on wide windows.
abstract final class AppContentWidth {
  static const double form = 840;
  static const double readable = 720;
  static const double message = 440;
}

/// Centers [child] at the top and caps its width at [maxWidth].
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    this.maxWidth = AppContentWidth.readable,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
