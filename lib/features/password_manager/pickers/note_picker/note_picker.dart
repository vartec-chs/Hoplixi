/// Note Picker Module
///
/// Модуль для выбора заметок с поддержкой одиночного и множественного выбора.
///
/// Использование:
///
/// ```dart
/// // Одиночный выбор
/// final result = await showNotePickerModal(context, ref);
/// if (result != null) {
///   print('Выбрана заметка: ${result.name} (${result.id})');
/// }
///
/// // Множественный выбор
/// final multiResult = await showNotePickerMultiModal(context, ref);
/// if (multiResult != null && multiResult.isNotEmpty) {
///   print('Выбрано заметок: ${multiResult.length}');
/// }
/// ```
library;

// Модели
export 'models/note_picker_models.dart';
// Модальные окна
export 'note_picker_modal.dart' show showNotePickerModal;
export 'note_picker_multi_modal.dart' show showNotePickerMultiModal;
// Провайдеры (для внутреннего использования или продвинутых сценариев)
export 'providers/note_picker_providers.dart';
// Виджеты (для переиспользования)
export 'widgets/note_list_tile.dart';
