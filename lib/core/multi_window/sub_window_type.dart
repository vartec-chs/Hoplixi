import 'dart:convert';

import 'package:flutter/material.dart';

/// Типы суб-окон приложения.
///
/// Каждый тип определяет конфигурацию окна: размер, заголовок
/// и минимальный размер.
enum SubWindowType {
  /// Генератор паролей — компактное окно для создания
  /// безопасных паролей.
  passwordGenerator(
    title: 'Генератор паролей',
    size: Size(420, 560),
    minSize: Size(360, 480),
  ),

  /// Окно авторизации — для входа в хранилище.
  auth(title: 'Авторизация', size: Size(400, 500), minSize: Size(380, 460));

  const SubWindowType({
    required this.title,
    required this.size,
    required this.minSize,
  });

  /// Заголовок окна.
  final String title;

  /// Начальный размер окна.
  final Size size;

  /// Минимально допустимый размер окна.
  final Size minSize;
}

/// Аргументы, передаваемые в суб-окно через
/// [WindowConfiguration.arguments].
///
/// Сериализуются в JSON-строку для передачи через
/// `desktop_multi_window`.
class SubWindowArguments {
  /// Тип окна для определения, какой виджет отображать.
  final SubWindowType type;

  /// Дополнительные данные для окна (например, ID записи).
  final Map<String, dynamic> payload;

  const SubWindowArguments({required this.type, this.payload = const {}});

  /// Сериализация аргументов в JSON-строку.
  String encode() {
    return jsonEncode({'type': type.name, 'payload': payload});
  }

  /// Десериализация аргументов из JSON-строки от
  /// [WindowController.arguments].
  ///
  /// Возвращает `null`, если строка не является валидным JSON
  /// или не содержит поле `type`.
  static SubWindowArguments? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final typeName = map['type'] as String?;
      if (typeName == null) return null;

      final type = SubWindowType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => throw ArgumentError('Неизвестный тип окна: $typeName'),
      );

      final payload = (map['payload'] as Map<String, dynamic>?) ?? {};

      return SubWindowArguments(type: type, payload: payload);
    } catch (_) {
      return null;
    }
  }
}
