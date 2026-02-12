import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/card_utils.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

/// Универсальный компонент для отображения списка тегов в карточке
class CardTagsList extends StatelessWidget {
  /// Список тегов для отображения
  final List<TagInCardDto>? tags;

  /// Высота контейнера
  final double height;

  /// Показывать заголовок "Теги:"
  final bool showTitle;

  const CardTagsList({
    super.key,
    required this.tags,
    this.height = 32,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (tags == null || tags!.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Теги:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags!.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final tag = tags![index];
              return _TagChip(tag: tag);
            },
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final TagInCardDto tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = CardUtils.parseColor(tag.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tagColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label, size: 12, color: tagColor),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tagColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
