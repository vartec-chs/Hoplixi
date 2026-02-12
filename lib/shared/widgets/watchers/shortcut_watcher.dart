import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:universal_platform/universal_platform.dart';

/// Виджет-обёртка для глобальных горячих клавиш приложения.
///
/// Все шорткаты определяются в [_shortcuts], а их обработчики — в [_actions].
/// Для добавления нового шортката:
/// 1. Создайте класс-наследник [Intent] (например, `_MyNewIntent`).
/// 2. Добавьте маппинг клавиш → Intent в [_shortcuts].
/// 3. Добавьте обработчик Intent → Action в [_actions].
class ShortcutWatcher extends StatelessWidget {
  const ShortcutWatcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions(context),
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shortcuts
// ---------------------------------------------------------------------------

final Map<ShortcutActivator, Intent> _shortcuts = {
  // Ctrl+Q — выход из приложения (Windows / Linux)
  if (UniversalPlatform.isWindows || UniversalPlatform.isLinux)
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ):
        const _ExitAppIntent(),

  // Cmd+Q — выход из приложения (macOS)
  if (UniversalPlatform.isMacOS)
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyQ):
        const _ExitAppIntent(),

  // Cmd+W — закрыть окно (macOS)
  if (UniversalPlatform.isMacOS)
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyW):
        const _CloseWindowIntent(),

  // Escape — pop навигации
  const SingleActivator(LogicalKeyboardKey.escape): const _PopPageIntent(),
};

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

Map<Type, Action<Intent>> _actions(BuildContext context) {
  return {
    _ExitAppIntent: CallbackAction<_ExitAppIntent>(
      onInvoke: (_) async {
        await WindowManager.close();
        return null;
      },
    ),
    _CloseWindowIntent: CallbackAction<_CloseWindowIntent>(
      onInvoke: (_) async {
        await WindowManager.close();
        return null;
      },
    ),
    _PopPageIntent: CallbackAction<_PopPageIntent>(
      onInvoke: (_) {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        }
        return null;
      },
    ),
  };
}

// ---------------------------------------------------------------------------
// Intents
// ---------------------------------------------------------------------------

class _ExitAppIntent extends Intent {
  const _ExitAppIntent();
}

class _CloseWindowIntent extends Intent {
  const _CloseWindowIntent();
}

class _PopPageIntent extends Intent {
  const _PopPageIntent();
}
