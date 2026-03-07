/// Document Picker Module
///
/// Модуль для выбора документов из хранилища с поддержкой одиночного
/// и множественного выбора.
///
/// Использование:
///
/// ```dart
/// // Одиночный выбор через модальное окно
/// final result = await showDocumentPickerModal(context, ref);
/// if (result != null) {
///   print('Выбран документ: ${result.name} (${result.id})');
/// }
///
/// // Множественный выбор
/// final multiResult = await showDocumentPickerMultiModal(context, ref);
/// if (multiResult != null && multiResult.isNotEmpty) {
///   print('Выбрано документов: ${multiResult.length}');
/// }
///
/// // Поле формы
/// DocumentPickerField(
///   onDocumentSelected: (id, title) => setState(() { ... }),
///   selectedDocumentId: _documentId,
///   selectedDocumentTitle: _documentTitle,
/// )
/// ```
library;

// Модели
export 'models/document_picker_models.dart';

// Поле формы
export 'document_picker_field.dart' show DocumentPickerField;

// Модальные окна
export 'document_picker_modal.dart' show showDocumentPickerModal;
export 'document_picker_multi_modal.dart' show showDocumentPickerMultiModal;

// Провайдеры (для внутреннего использования или продвинутых сценариев)
export 'providers/document_picker_providers.dart';

// Виджеты (для переиспользования)
export 'widgets/document_list_tile.dart';
