import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// =============================================================================
// Keyboard Shortcuts — горячие клавиши для Desktop Dashboard
// =============================================================================

/// Горячая клавиша: Escape — вернуться назад.
const SingleActivator kShortcutGoBack = SingleActivator(
  LogicalKeyboardKey.escape,
);

/// Горячая клавиша: Ctrl+N — создать новую сущность
/// текущего типа (password, note и т.д.).
const SingleActivator kShortcutCreateEntity = SingleActivator(
  LogicalKeyboardKey.keyN,
  control: true,
);

/// Горячая клавиша: Ctrl+T — открыть теги.
const SingleActivator kShortcutOpenTags = SingleActivator(
  LogicalKeyboardKey.keyT,
  control: true,
);

/// Горячая клавиша: Ctrl+K — открыть категории.
const SingleActivator kShortcutOpenCategories = SingleActivator(
  LogicalKeyboardKey.keyK,
  control: true,
);

/// Горячая клавиша: Ctrl+I — открыть иконки.
const SingleActivator kShortcutOpenIcons = SingleActivator(
  LogicalKeyboardKey.keyI,
  control: true,
);
