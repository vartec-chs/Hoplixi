import 'package:flutter/material.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

enum EntityType {
  password('passwords', 'Пароли', Icons.lock),
  note('notes', 'Заметки', Icons.note),
  bankCard('bank_cards', 'Банковские карты', Icons.credit_card),
  file('files', 'Файлы', Icons.attach_file),
  otp('otps', 'OTP/2FA', Icons.security);

  const EntityType(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static const List<EntityType> allTypes = EntityType.values;

  /// allTypesString
  static final List<String> allTypesString = EntityType.values
      .map((e) => e.id)
      .toList();

  /// Получить тип по идентификатору
  static EntityType? fromId(String id) {
    try {
      return EntityType.values.firstWhere((type) => type.id == id);
    } catch (e) {
      logError('Неизвестный тип сущности', error: e, data: {'id': id});
      return null;
    }
  }

  /// Получить тип по индексу
  static EntityType? fromIndex(int index) {
    try {
      return EntityType.values[index];
    } catch (e) {
      logError(
        'Неизвестный индекс типа сущности',
        error: e,
        data: {'index': index},
      );
      return null;
    }
  }

  @override
  String toString() => 'EntityType(id: $id, label: $label, icon: $icon)';
}
