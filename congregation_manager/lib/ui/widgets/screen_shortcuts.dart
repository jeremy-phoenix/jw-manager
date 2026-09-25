import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ctrl+[key], or Cmd+[key] on Apple platforms.
SingleActivator commandKey(LogicalKeyboardKey key) {
  final apple =
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  return SingleActivator(key, control: !apple, meta: apple);
}

/// A callback bound to a key combination by [ScreenShortcuts].
class ScreenShortcut {
  const ScreenShortcut(this.onInvoke, {this.whileEditing = false});

  final VoidCallback onInvoke;

  /// Whether the shortcut also runs while a text field has focus. Leave it
  /// off for keys that mean something while typing, such as Ctrl+A or Esc.
  final bool whileEditing;
}

/// Keyboard shortcuts for a screen, active wherever focus is inside it.
///
/// Unlike [CallbackShortcuts], a binding that is not [ScreenShortcut.whileEditing]
/// steps aside while a text field has focus, so the field keeps its own
/// meaning for the key.
class ScreenShortcuts extends StatelessWidget {
  const ScreenShortcuts({
    super.key,
    required this.bindings,
    required this.child,
  });

  final Map<ShortcutActivator, ScreenShortcut> bindings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        for (final MapEntry(:key, :value) in bindings.entries)
          key: _ScreenShortcutIntent(value),
      },
      child: Actions(
        actions: {_ScreenShortcutIntent: _ScreenShortcutAction()},
        // Focuses the screen when it opens, so shortcuts work before the
        // user clicks into it.
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _ScreenShortcutIntent extends Intent {
  const _ScreenShortcutIntent(this.shortcut);

  final ScreenShortcut shortcut;
}

class _ScreenShortcutAction extends Action<_ScreenShortcutIntent> {
  @override
  bool isEnabled(_ScreenShortcutIntent intent) =>
      intent.shortcut.whileEditing || !_isEditingText;

  @override
  Object? invoke(_ScreenShortcutIntent intent) {
    intent.shortcut.onInvoke();
    return null;
  }

  static bool get _isEditingText {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}
