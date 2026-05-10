import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Универсальный компонент для отображения индикаторов статуса карточки
/// (закреплено, избранное, архив, истекает срок)
class CardStatusIndicators extends StatelessWidget {
  /// Флаг закрепления
  final bool isPinned;

  /// Флаг избранного
  final bool isFavorite;

  /// Флаг архивации
  final bool isArchived;

  /// Флаг истекшего срока
  final bool isExpired;

  /// Флаг скорого истечения срока
  final bool isExpiringSoon;

  /// Смещение сверху
  final double top;

  /// Начальное смещение слева
  final double left;

  /// Расстояние между индикаторами
  final double spacing;

  const CardStatusIndicators({
    super.key,
    required this.isPinned,
    required this.isFavorite,
    required this.isArchived,
    this.isExpired = false,
    this.isExpiringSoon = false,
    this.top = 0,
    this.left = 0,
    this.spacing = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: buildPositionedWidgets());
  }

  /// Строит список Positioned виджетов для использования в Stack
  List<Widget> buildPositionedWidgets() {
    final List<Widget> indicators = [];
    double currentLeft = left;

    if (isPinned) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.push_pin, size: 20, color: Colors.orange),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isFavorite) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.star, size: 18, color: Colors.amber),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isArchived) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.archive, size: 18, color: Colors.blueGrey),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isExpired) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(
              LucideIcons.clockAlert,
              size: 18,
              color: Colors.red,
            ),
          ),
        ),
      );
      currentLeft += spacing;
    } else if (isExpiringSoon) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(
              LucideIcons.clock,
              size: 18,
              color: Colors.orange,
            ),
          ),
        ),
      );
      currentLeft += spacing;
    }

    return indicators;
  }
}
