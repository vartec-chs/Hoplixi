import 'package:flutter/material.dart';

/// Кастомная форма с квадратным вырезом и скругленными нижними углами
class RoundedSquareNotchedShape extends NotchedShape {
  /// Радиус скругления нижних углов
  final double cornerRadius;

  /// Радиус скругления углов выреза
  final double notchRadius;

  const RoundedSquareNotchedShape({
    this.cornerRadius = 16.0,
    this.notchRadius = 8.0,
  });

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRRect(
        RRect.fromRectAndCorners(
          host,
          bottomLeft: Radius.circular(cornerRadius),
          bottomRight: Radius.circular(cornerRadius),
        ),
      );
    }

    // Параметры выреза
    const notchMargin = 5.0;
    final notchWidth = guest.width + notchMargin * 2;
    final notchHeight = guest.height / 2 + notchMargin;

    // Координаты центра выреза
    final centerX = guest.center.dx;

    // Координаты выреза
    final notchLeft = centerX - notchWidth / 2;
    final notchRight = centerX + notchWidth / 2;
    final notchTop = host.top;
    final notchBottom = host.top + notchHeight;

    return Path()
      // Начинаем с левого верхнего угла
      ..moveTo(host.left, host.top)
      // Линия до начала выреза
      ..lineTo(notchLeft, notchTop)
      // Скругление левого верхнего угла выреза
      ..arcToPoint(
        Offset(notchLeft, notchBottom),
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      // Нижняя линия выреза
      ..lineTo(notchRight, notchBottom)
      // Скругление правого верхнего угла выреза
      ..arcToPoint(
        Offset(notchRight, notchTop),
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      // Линия до правого верхнего угла
      ..lineTo(host.right, host.top)
      // Правая сторона
      ..lineTo(host.right, host.bottom - cornerRadius)
      // Скругление правого нижнего угла
      ..arcToPoint(
        Offset(host.right - cornerRadius, host.bottom),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      )
      // Нижняя линия
      ..lineTo(host.left + cornerRadius, host.bottom)
      // Скругление левого нижнего угла
      ..arcToPoint(
        Offset(host.left, host.bottom - cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      )
      // Левая сторона
      ..lineTo(host.left, host.top)
      ..close();
  }
}
