import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

/// Карточка заметки для режима списка (переписана с shared компонентами)
class NoteListCard extends ConsumerStatefulWidget {
  final NoteCardDto note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const NoteListCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  @override
  ConsumerState<NoteListCard> createState() => _NoteListCardState();
}

class _NoteListCardState extends ConsumerState<NoteListCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  bool _titleCopied = false;

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

  Future<void> _copyTitle() async {
    await Clipboard.setData(ClipboardData(text: widget.note.title));
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Заголовок скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });

    final noteDao = await ref.read(noteDaoProvider.future);
    await noteDao.incrementUsage(widget.note.id);
  }

  List<CardActionItem> _buildCopyActions(BuildContext context) {
    return [
      CardActionItem(
        label: 'Заголовок',
        onPressed: _copyTitle,
        icon: Icons.title,
        successIcon: Icons.check,
        isSuccess: _titleCopied,
      ),
      CardActionItem(
        label: 'Открыть',
        onPressed: () {
          context.push(
            AppRoutesPaths.dashboardEntityEdit(EntityType.note, widget.note.id),
          );
        },
        icon: Icons.open_in_new,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = widget.note;

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [
              // Основная часть карточки
              _buildHeader(theme),
              // Развернутый контент
              _buildExpandedContent(theme, context),
            ],
          ),
        ),
        // Индикаторы статуса
        ...CardStatusIndicators(
          isPinned: note.isPinned,
          isFavorite: note.isFavorite,
          isArchived: note.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final note = widget.note;

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
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 6),
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.category != null)
                      CardCategoryBadge(
                        name: note.category!.name,
                        color: note.category!.color,
                      ),
                    Text(
                      note.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.description != null &&
                        note.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Действия
              _buildHeaderActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(ThemeData theme) {
    final note = widget.note;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!note.isDeleted) ...[
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return Opacity(opacity: _iconsAnimation.value, child: child);
            },
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    note.isFavorite ? Icons.star : Icons.star_border,
                    color: note.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: note.isFavorite
                      ? 'Убрать из избранного'
                      : 'В избранное',
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _iconsAnimation,
                axis: Axis.horizontal,
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: note.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: note.isPinned ? 'Открепить' : 'Закрепить',
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
        ] else ...[
          IconButton(
            icon: const Icon(Icons.restore_from_trash),
            onPressed: widget.onRestore,
            tooltip: 'Восстановить',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: widget.onDelete,
            tooltip: 'Удалить навсегда',
          ),
        ],
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          onPressed: _toggleExpanded,
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme, BuildContext context) {
    final note = widget.note;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _expandAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Категория (расширенная)
            if (note.category != null) ...[
              CardCategoryBadge(
                name: note.category!.name,
                color: note.category!.color,
                showIcon: true,
              ),
              const SizedBox(height: 12),
            ],

            // Описание
            if (note.description != null && note.description!.isNotEmpty) ...[
              Text(
                'Описание:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(note.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],

            // Кнопки копирования (горизонтальный скролл)
            HorizontalScrollableActions(actions: _buildCopyActions(context)),

            // Теги
            if (note.tags != null && note.tags!.isNotEmpty) ...[
              const SizedBox(height: 12),
              CardTagsList(tags: note.tags),
            ],

            // Метаинформация
            const SizedBox(height: 12),
            CardMetaInfo(
              usedCount: note.usedCount,
              modifiedAt: note.modifiedAt,
            ),

            // Кнопки удаления/восстановления/архивации
            const SizedBox(height: 12),
            CardActionButtons(
              isDeleted: note.isDeleted,
              isArchived: note.isArchived,
              onRestore: widget.onRestore,
              onDelete: widget.onDelete,
              onToggleArchive: widget.onToggleArchive,
            ),
          ],
        ),
      ),
    );
  }
}
