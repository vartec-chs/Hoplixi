import 'dart:convert';

/// Валидатор имен файлов и папок для обеспечения кроссплатформенной совместимости.
///
/// Проверяет один сегмент пути (имя папки или файла) на соответствие ограничениям
/// различных файловых систем (Windows, Linux, macOS).
class FileNameValidator {
  FileNameValidator._();

  static final RegExp _forbiddenChars = RegExp(r'[<>:"/\\|?*\s\x00-\x1F]');
  static final RegExp _reservedWindowsNames = RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$',
    caseSensitive: false,
  );

  /// Валидирует [value] и возвращает сообщение об ошибке на русском языке,
  /// если имя недопустимо. Если имя валидно, возвращает null.
  static String? validate(String? value) {
    if (value == null) {
      return 'Название обязательно';
    }

    if (value.isEmpty) {
      return 'Название не может быть пустым';
    }

    if (value.trim().isEmpty) {
      return 'Название не может состоять только из пробелов';
    }

    final name = value.trim();

    if (name == '.' || name == '..') {
      return 'Недопустимое название';
    }

    if (value.contains(' ')) {
      return 'Название не может содержать пробелы';
    }

    if (value.endsWith('.')) {
      return 'Название не может заканчиваться точкой';
    }

    // Лимит в 255 байт (а не символов) для совместимости с большинством ФС (ext4, NTFS)
    if (utf8.encode(name).length > 255) {
      return 'Название слишком длинное';
    }

    if (_forbiddenChars.hasMatch(name)) {
      return 'Название содержит запрещённые символы (<>:"/\\|?*)';
    }

    if (_reservedWindowsNames.hasMatch(name)) {
      return 'Это системное зарезервированное имя Windows';
    }

    return null;
  }

  /// Возвращает true, если [value] является допустимым именем сегмента пути.
  static bool isValid(String? value) => validate(value) == null;
}
