import 'package:flutter/material.dart';

class AppPopupMenuItem<T> extends PopupMenuItem<T> {
  AppPopupMenuItem({
    super.key,
    required super.value,
    required IconData icon,
    required String label,
    Color? color,
    super.enabled,
  }) : super(
         height: 48,
         padding: const EdgeInsets.symmetric(horizontal: 16),
         child: _AppPopupMenuItemContent(
           icon: icon,
           label: label,
           color: color,
         ),
       );
}

class _AppPopupMenuItemContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _AppPopupMenuItemContent({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).popupMenuTheme.textStyle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 24, child: Icon(icon, size: 20, color: color)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: color == null
                ? textStyle
                : textStyle?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
