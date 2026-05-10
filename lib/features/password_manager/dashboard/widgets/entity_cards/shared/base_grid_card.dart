import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_cards/shared/shared.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/core/models/dto/tag_dto.dart';
import 'package:hoplixi/shared/widgets/icon_ref_preview.dart';

class BaseGridCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingSubtitle;
  final IconData fallbackIcon;
  final String? iconSource;
  final String? iconValue;
  final CategoryInCardDto? category;
  final String? description;
  final List<TagInCardDto>? tags;
  final int usedCount;
  final DateTime? modifiedAt;

  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final bool isExpired;
  final bool isExpiringSoon;

  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenView;
  final VoidCallback? onOpenHistory;

  final List<CardActionItem> copyActions;

  const BaseGridCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingSubtitle,
    required this.fallbackIcon,
    this.iconSource,
    this.iconValue,
    this.category,
    this.description,
    this.tags,
    required this.usedCount,
    this.modifiedAt,
    required this.isFavorite,
    required this.isPinned,
    required this.isArchived,
    required this.isDeleted,
    this.isExpired = false,
    this.isExpiringSoon = false,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onEdit,
    this.onOpenView,
    this.onOpenHistory,
    required this.copyActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardPadding = isMobile ? 8.0 : 12.0;
    final minCardWidth = isMobile ? 160.0 : 240.0;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minCardWidth),
      child: Stack(
        children: [
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: isMobile ? 32 : 40,
                          height: isMobile ? 32 : 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconRefPreview(
                            iconRef: IconRefDto.fromFields(
                                  iconSource: iconSource,
                                  iconValue: iconValue,
                                ) ??
                                category?.effectiveIconRef,
                            fallbackIcon: fallbackIcon,
                            size: isMobile ? 16 : 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (trailingSubtitle != null)
                                Text(
                                  trailingSubtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (onOpenView != null && !isDeleted)
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: onOpenView,
                            tooltip: 'Открыть',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 4 : 6),

                    if (category != null) ...[
                      CardCategoryBadge(
                        name: category!.name,
                        color: category!.color,
                      ),
                      SizedBox(height: isMobile ? 3 : 4),
                    ],

                    if (subtitle != null) ...[
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 3 : 4),
                    ],

                    if (description != null && description!.isNotEmpty) ...[
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isMobile ? 3 : 4),
                    ],

                    if (tags != null && tags!.isNotEmpty) ...[
                      CardTagsList(tags: tags!, showTitle: false),
                      SizedBox(height: isMobile ? 3 : 4),
                    ],
                    
                    const Spacer(),

                    if (!isDeleted) ...[
                      if (copyActions.isNotEmpty) ...[
                        HorizontalScrollableActions(
                          actions: copyActions,
                          height: isMobile ? 28 : 32,
                          spacing: 6,
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                      ],
                      if (modifiedAt != null) ...[
                        CardMetaInfo(
                          usedCount: usedCount,
                          modifiedAt: modifiedAt!,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: isPinned ? Colors.orange : null,
                                ),
                                onPressed: onTogglePin,
                                tooltip: 'Закрепить',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: isFavorite
                                      ? Colors.amber
                                      : null,
                                ),
                                onPressed: onToggleFavorite,
                                tooltip: 'Избранное',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onOpenHistory != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.history,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: onOpenHistory,
                                  tooltip: 'История',
                                ),
                              if (onOpenHistory != null) const SizedBox(width: 8),
                              if (onEdit != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: onEdit,
                                  tooltip: 'Редактировать',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: onRestore,
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Восстановить'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ...CardStatusIndicators(
            isPinned: isPinned,
            isFavorite: isFavorite,
            isArchived: isArchived,
            isExpired: isExpired,
            isExpiringSoon: isExpiringSoon,
          ).buildPositionedWidgets(),
        ],
      ),
    );
  }
}
