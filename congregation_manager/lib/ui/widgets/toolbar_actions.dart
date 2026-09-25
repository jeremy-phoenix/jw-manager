import 'package:flutter/material.dart';

import 'package:congregation_manager/ui/theme/layout.dart';

/// Whether the window is wide enough for labeled app-bar actions.
bool showToolbarLabels(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppBreakpoints.large;

/// An app-bar action: a labeled button on wide windows, an icon button
/// otherwise. [tooltip] defaults to [label].
class ToolbarAction extends StatelessWidget {
  const ToolbarAction({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    required this.onPressed,
  }) : primary = false;

  /// The screen's main action, drawn as a filled button when labeled.
  const ToolbarAction.primary({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    required this.onPressed,
  }) : primary = true;

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip ?? label;
    if (!showToolbarLabels(context)) {
      return IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    final Widget button = primary
        ? FilledButton.icon(
            icon: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          )
        : TextButton.icon(
            icon: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          );
    return _ToolbarItem(
      tooltip: tooltip == label ? null : tooltip,
      primary: primary,
      child: button,
    );
  }
}

/// An app-bar menu that follows the same rule as [ToolbarAction].
class ToolbarMenu<T> extends StatelessWidget {
  const ToolbarMenu({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    required this.itemBuilder,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip ?? label;
    if (!showToolbarLabels(context)) {
      return PopupMenuButton<T>(
        icon: Icon(icon),
        tooltip: tooltip,
        itemBuilder: itemBuilder,
        onSelected: onSelected,
      );
    }

    return _ToolbarItem(
      tooltip: tooltip == label ? null : tooltip,
      child: Builder(
        builder: (buttonContext) => TextButton.icon(
          icon: Icon(icon),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          onPressed: () => _openMenu(buttonContext),
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext buttonContext) async {
    final button = buttonContext.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()!
            as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final value = await showMenu<T>(
      context: buttonContext,
      position: position,
      items: itemBuilder(buttonContext),
    );
    if (value != null) onSelected(value);
  }
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({this.tooltip, this.primary = false, required this.child});

  final String? tooltip;
  final bool primary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final item = Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xs,
        right: primary ? AppSpacing.sm : AppSpacing.xs,
      ),
      child: child,
    );
    return tooltip == null ? item : Tooltip(message: tooltip, child: item);
  }
}
