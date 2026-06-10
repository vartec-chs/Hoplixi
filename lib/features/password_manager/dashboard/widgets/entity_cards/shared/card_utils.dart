import 'package:flutter/material.dart';

/// Утилиты для работы с карточками
class CardUtils {
  CardUtils._();

  /// Парсит цвет (HEX-строка или ARGB int) в Color
  static Color parseColor(Object? color) {
    if (color == null) return Colors.grey;

    int? value;

    if (color is int) {
      value = color;
    } else if (color is String) {
      if (color.isEmpty) return Colors.grey;

      // Если это HEX с решеткой
      if (color.startsWith('#')) {
        final hex = color.substring(1);
        if (hex.length == 6) {
          value = int.tryParse('FF$hex', radix: 16);
        } else {
          value = int.tryParse(hex, radix: 16);
        }
      } else {
        // Пробуем как десятичное число
        value = int.tryParse(color);
        // Если не вышло, пробуем как HEX
        value ??= int.tryParse(color, radix: 16);
      }
    }

    if (value == null || value == 0) return Colors.grey;

    // Если это 24-битный цвет (RRGGBB), добавляем альфа-канал FF
    if (value > 0 && value <= 0xFFFFFF) {
      value |= 0xFF000000;
    }

    return Color(value);
  }

  /// Форматирует дату в человекочитаемый формат
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} мин назад';
      }
      return '${diff.inHours} ч назад';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} д назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  /// Извлекает хост из URL
  static String extractHost(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (e) {
      return url;
    }
  }
}
