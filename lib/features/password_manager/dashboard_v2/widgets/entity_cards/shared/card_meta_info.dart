import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/card_utils.dart';

/// Универсальный компонент для отображения метаинформации карточки
class CardMetaInfo extends StatelessWidget {
  /// Количество использований
  final int usedCount;

  /// Дата последнего изменения
  final DateTime modifiedAt;

  /// Текст для количества использований (например: "Использован", "Использована")
  final String usedLabel;

  /// Текст для даты изменения (например: "Изменён", "Изменена")
  final String modifiedLabel;

  const CardMetaInfo({
    super.key,
    required this.usedCount,
    required this.modifiedAt,
    this.usedLabel = 'Использован',
    this.modifiedLabel = 'Изменён',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.grey,
      fontSize: 11,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$usedLabel: $usedCount раз', style: textStyle),
        Text(
          '$modifiedLabel: ${CardUtils.formatDate(modifiedAt)}',
          style: textStyle,
        ),
      ],
    );
  }
}
