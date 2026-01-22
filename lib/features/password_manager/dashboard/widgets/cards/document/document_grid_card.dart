import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/routing/paths.dart';

/// Карточка документа для режима сетки
/// Минимальная ширина: 240px для предотвращения чрезмерного сжатия
class DocumentGridCard extends ConsumerStatefulWidget {
  final DocumentCardDto document;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;

  const DocumentGridCard({
    super.key,
    required this.document,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
  });

  @override
  ConsumerState<DocumentGridCard> createState() => _DocumentGridCardState();
}

class _DocumentGridCardState extends ConsumerState<DocumentGridCard>
    with TickerProviderStateMixin {
  late AnimationController _iconsController;
  late Animation<double> _iconsAnimation;

  @override
  void initState() {
    super.initState();
    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconsController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  String _getPageWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'страница';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'страницы';
    } else {
      return 'страниц';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = widget.document;
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
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок
                      Row(
                        children: [
                          Container(
                            width: isMobile ? 32 : 40,
                            height: isMobile ? 32 : 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              size: isMobile ? 16 : 20,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              document.title ?? 'Без названия',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isMobile) const Spacer(),
                          if (!document.isDeleted)
                            FadeTransition(
                              opacity: _iconsAnimation,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (document.isArchived)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.archive,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  if (document.usedCount >=
                                      MainConstants.popularItemThreshold)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.local_fire_department,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 4 : 6),

                      if (document.category != null) ...[
                        CardCategoryBadge(
                          name: document.category!.name,
                          color: document.category!.color,
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                      ],

                      const SizedBox(height: 4),
                      Text(
                        '${document.documentType ?? 'Документ'} • ${document.pageCount} ${_getPageWord(document.pageCount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Описание (если есть)
                      if (document.description != null &&
                          document.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          document.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),

                      if (document.tags != null && document.tags!.isNotEmpty)
                        CardTagsList(tags: document.tags!, showTitle: false),

                      if (!document.isDeleted) ...[
                        const SizedBox(height: 8),
                        // Кнопка расшифровки
                        if (widget.onDecrypt != null)
                          FadeTransition(
                            opacity: _iconsAnimation,
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.onDecrypt,
                                icon: const Icon(Icons.lock_open, size: 16),
                                label: const Text(
                                  'Расшифровать',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: isMobile ? 3 : 4),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.push(
                                      AppRoutesPaths.dashboardEntityEdit(
                                        EntityType.document,
                                        document.id,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text(
                                    'Просмотр',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.push(
                                      AppRoutesPaths.dashboardEntityEdit(
                                        EntityType.document,
                                        document.id,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text(
                                    'Изменить',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  document.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: document.isPinned
                                      ? Colors.orange
                                      : null,
                                ),
                                onPressed: widget.onTogglePin,
                                tooltip: 'Закрепить',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  document.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: document.isFavorite
                                      ? Colors.amber
                                      : null,
                                ),
                                onPressed: widget.onToggleFavorite,
                                tooltip: 'Избранное',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  document.isArchived
                                      ? Icons.unarchive
                                      : Icons.archive_outlined,
                                  size: 18,
                                ),
                                onPressed: widget.onToggleArchive,
                                tooltip: document.isArchived
                                    ? 'Разархивировать'
                                    : 'Архивировать',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: widget.onRestore,
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('Восстановить'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: widget.onDelete,
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
          ),
          ...CardStatusIndicators(
            isPinned: document.isPinned,
            isFavorite: document.isFavorite,
            isArchived: document.isArchived,
          ).buildPositionedWidgets(),
        ],
      ),
    );
  }
}
