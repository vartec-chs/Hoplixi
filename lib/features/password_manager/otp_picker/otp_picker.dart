/// Otp Picker Module
///
/// Модуль для выбора OTP с поддержкой одиночного и множественного выбора.
///
/// Использование:
///
/// ```dart
/// // Одиночный выбор
/// final result = await showOtpPickerModal(context, ref);
/// if (result != null) {
///   print('Выбран OTP: ${result.name} (${result.id})');
/// }
///
/// // Множественный выбор
/// final multiResult = await showOtpPickerMultiModal(context, ref);
/// if (multiResult != null && multiResult.isNotEmpty) {
///   print('Выбрано OTP: ${multiResult.length}');
/// }
/// ```
library;

// Модели
export 'models/otp_picker_models.dart';
export 'otp_picker_field.dart';
// Модальные окна
export 'otp_picker_modal.dart' show showOtpPickerModal;
export 'otp_picker_multi_modal.dart' show showOtpPickerMultiModal;
// Провайдеры (для внутреннего использования или продвинутых сценариев)
export 'providers/otp_picker_providers.dart';
// Виджеты (для переиспользования)
export 'widgets/otp_list_tile.dart';
