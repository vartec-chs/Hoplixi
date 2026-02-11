import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';

class DocumentListCard extends ConsumerStatefulWidget {
  final DocumentCardDto document;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onDecrypt;

  const DocumentListCard({
    super.key,
    required this.document,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    this.onDecrypt,
  });

  @override
  ConsumerState<DocumentListCard> createState() => _DocumentListCardState();
}

class _DocumentListCardState extends ConsumerState<DocumentListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final AnimationController _iconsController;
  late final Animation<double> _iconsAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _iconsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconsAnimation = CurvedAnimation(
      parent: _iconsController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _iconsController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
      _iconsController.forward();
    } else {
      _expandController.reverse();
      if (!_isHovered) {
        _iconsController.reverse();
      }
    }
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else if (!_isExpanded) {
      _iconsController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = widget.document;

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [_buildHeader(theme), _buildExpandedContent(theme)],
          ),
        ),
        ...CardStatusIndicators(
          isPinned: document.isPinned,
          isFavorite: document.isFavorite,
          isArchived: document.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final document = widget.document;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: InkWell(
        onTap: _toggleExpanded,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),

              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title ?? 'Без названия',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${document.documentType ?? 'Документ'} • ${document.pageCount} ${_getPageWord(document.pageCount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Теги (если есть место)
              if (document.tags != null && document.tags!.isNotEmpty) ...[
                const SizedBox(width: 16),
                SizedBox(width: 150, child: CardTagsList(tags: document.tags!)),
              ],

              // Заметка (если есть)
              if (document.noteName != null) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        document.noteName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(width: 8),
              _buildHeaderActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(ThemeData theme) {
    final document = widget.document;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!document.isDeleted) ...[
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: _iconsAnimation.value == 0,
                child: Opacity(opacity: _iconsAnimation.value, child: child),
              );
            },
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    document.isFavorite ? Icons.star : Icons.star_border,
                    color: document.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: document.isFavorite
                      ? 'Убрать из избранного'
                      : 'В избранное',
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: _iconsAnimation.value == 0,
                child: SizeTransition(
                  sizeFactor: _iconsAnimation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    document.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    color: document.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: document.isPinned ? 'Открепить' : 'Закрепить',
                ),
                if (widget.onOpenHistory != null)
                  IconButton(
                    icon: const Icon(Icons.history, size: 18),
                    onPressed: widget.onOpenHistory,
                    tooltip: 'История',
                  ),
              ],
            ),
          ),
        ] else
          const SizedBox.shrink(),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          onPressed: _toggleExpanded,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    final document = widget.document;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(heightFactor: _expandAnimation.value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),

            // Описание документа
            if (document.description != null &&
                document.description!.isNotEmpty) ...[
              _buildMetaRow(
                theme,
                label: 'Описание',
                value: document.description!,
                icon: Icons.notes,
              ),
              const SizedBox(height: 8),
            ],

            // Тип документа и количество страниц
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(
                  theme,
                  label: 'Тип',
                  value: document.documentType ?? 'Не указан',
                  icon: Icons.category,
                ),
                const SizedBox(height: 8),
                _buildMetaRow(
                  theme,
                  label: 'Страниц',
                  value: '${document.pageCount}',
                  icon: Icons.pages,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Мета-информация и категория
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardMetaInfo(
                  usedCount: document.usedCount,
                  modifiedAt: document.modifiedAt,
                ),
                const SizedBox(height: 8),
                if (document.category != null)
                  Row(
                    children: [
                      const Icon(Icons.folder, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      CardCategoryBadge(
                        name: document.category!.name,
                        color: document.category!.color,
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Кнопка расшифровки
            if (!document.isDeleted && widget.onDecrypt != null) ...[
              SizedBox(
                width: double.infinity,
                child: SmoothButton(
                  onPressed: widget.onDecrypt,
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: 'Расшифровать страницы',
                  size: .small,
                  type: .outlined,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Кнопки действий
            CardActionButtons(
              isDeleted: document.isDeleted,
              isArchived: document.isArchived,
              onRestore: widget.onRestore,
              onDelete: widget.onDelete,
              onToggleArchive: widget.onToggleArchive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
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
}
