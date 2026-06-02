import 'package:flutter/material.dart';

/// Утилиты для работы с карточками
class CardUtils {
  CardUtils._();

  /// Парсит цвет (HEX-строка или ARGB int) в Color
  static Color parseColor(Object? color) {
    if (color == null) return Colors.grey;
    if (color is int) {
      return Color(color);
    }
    if (color is String) {
      if (color.isEmpty) return Colors.grey;
      try {
        final hex = color.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
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
