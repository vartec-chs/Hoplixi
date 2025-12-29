// ---------- Карточки для заметок ----------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Карточка заметки для режима сетки
class NoteGridCard extends ConsumerStatefulWidget {
  final NoteCardDto note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const NoteGridCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<NoteGridCard> createState() => _NoteGridCardState();
}

class _NoteGridCardState extends ConsumerState<NoteGridCard>
    with TickerProviderStateMixin {
  bool _isHovered = false;
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
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _iconsController.forward();
    } else {
      _iconsController.reverse();
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.note,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Spacer(),
                        if (!widget.note.isDeleted) ...[
                          // Иконки состояния с анимацией
                          AnimatedBuilder(
                            animation: _iconsAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _iconsAnimation.value,
                                child: Transform.scale(
                                  scale: 0.8 + (_iconsAnimation.value * 0.2),
                                  alignment: Alignment.centerRight,
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.note.isArchived)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.archive,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                if (widget.note.usedCount >=
                                    MainConstants.popularItemThreshold)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.local_fire_department,
                                      size: 12,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Кнопки действия с анимацией
                          AnimatedBuilder(
                            animation: _iconsAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _iconsAnimation.value,
                                child: Transform.scale(
                                  scale: 0.8 + (_iconsAnimation.value * 0.2),
                                  alignment: Alignment.centerRight,
                                  child: child,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    widget.note.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 14,
                                    color: widget.note.isPinned
                                        ? Colors.orange
                                        : null,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onTogglePin,
                                ),
                                IconButton(
                                  icon: Icon(
                                    widget.note.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: widget.note.isFavorite
                                        ? Colors.amber
                                        : null,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onToggleFavorite,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    context.push(
                                      AppRoutesPaths.dashboardEntityEdit(
                                        EntityType.note,
                                        widget.note.id,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Для удалённых записей показываем кнопки восстановления и удаления
                          IconButton(
                            icon: const Icon(Icons.restore, size: 12),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onRestore,
                            tooltip: 'Восстановить',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 12,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onDelete,
                            tooltip: 'Удалить навсегда',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Категория
                    if (widget.note.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(
                            widget.note.category!.color,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.note.category!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _parseColor(widget.note.category!.color),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Название
                    Text(
                      widget.note.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Описание
                    if (widget.note.description != null &&
                        widget.note.description!.isNotEmpty)
                      Text(
                        widget.note.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Теги (горизонтальная прокрутка)
                    if (widget.note.tags != null &&
                        widget.note.tags!.isNotEmpty) ...[
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.note.tags!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tag = widget.note.tags![index];
                            final tagColor = _parseColor(tag.color);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tagColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tag.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tagColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Кнопка открытия заметки
                    SizedBox(
                      width: double.infinity,
                      child: SmoothButton(
                        label: 'Открыть',
                        onPressed: () {
                          context.push(
                            AppRoutesPaths.dashboardEntityEdit(
                              EntityType.note,
                              widget.note.id,
                            ),
                          );
                        },
                        type: SmoothButtonType.outlined,
                        variant: SmoothButtonVariant.normal,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        iconPosition: SmoothButtonIconPosition.start,
                        size: SmoothButtonSize.small,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.note.isPinned)
          Positioned(
            top: 6,
            left: 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.push_pin, size: 16, color: Colors.orange),
            ),
          ),
        if (widget.note.isFavorite)
          Positioned(
            top: 6,
            left: widget.note.isPinned ? 30 : 8,
            child: Transform.rotate(
              angle: -0.52,
              child: const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}
