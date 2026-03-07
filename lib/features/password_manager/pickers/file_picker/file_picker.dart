/// File Picker Module
///
/// Модуль для выбора файлов из хранилища с поддержкой одиночного
/// и множественного выбора.
///
/// Использование:
///
/// ```dart
/// // Одиночный выбор через модальное окно
/// final result = await showFilePickerModal(context, ref);
/// if (result != null) {
///   print('Выбран файл: ${result.name} (${result.id})');
/// }
///
/// // Множественный выбор
/// final multiResult = await showFilePickerMultiModal(context, ref);
/// if (multiResult != null && multiResult.isNotEmpty) {
///   print('Выбрано файлов: ${multiResult.length}');
/// }
///
/// // Поле формы
/// FilePickerField(
///   onFileSelected: (id, name) => setState(() { ... }),
///   selectedFileId: _fileId,
///   selectedFileName: _fileName,
/// )
/// ```
library;

// Модели
export 'models/file_picker_models.dart';

// Поле формы
export 'file_picker_field.dart' show FilePickerField;

// Модальные окна
export 'file_picker_modal.dart' show showFilePickerModal;
export 'file_picker_multi_modal.dart' show showFilePickerMultiModal;

// Провайдеры (для внутреннего использования или продвинутых сценариев)
export 'providers/file_picker_providers.dart';

// Виджеты (для переиспользования)
export 'widgets/file_list_tile.dart';
