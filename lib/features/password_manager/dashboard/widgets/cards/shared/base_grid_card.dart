import 'package:flutter/material.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

class BaseGridCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final CategoryInCardDto? category;
  final List<TagInCardDto>? tags;
  final int usedCount;

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

  final List<CardActionItem> copyActions;

  const BaseGridCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.category,
    this.tags,
    required this.usedCount,
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
    required this.copyActions,
  });

  @override
  State<BaseGridCard> createState() => _BaseGridCardState();
}

class _BaseGridCardState extends State<BaseGridCard>
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
                              widget.icon,
                              size: isMobile ? 16 : 20,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isMobile) const Spacer(),
                          if (!widget.isDeleted)
                            FadeTransition(
                              opacity: _iconsAnimation,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.isArchived)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.archive,
                                        size: isMobile ? 14 : 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  if (widget.usedCount >=
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

                      if (widget.category != null) ...[
                        CardCategoryBadge(
                          name: widget.category!.name,
                          color: widget.category!.color,
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                      ],

                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: isMobile ? 4 : 6),

                      if (widget.tags != null && widget.tags!.isNotEmpty) ...[
                        CardTagsList(tags: widget.tags!, showTitle: false),
                        SizedBox(height: isMobile ? 3 : 4),
                      ],

                      if (!widget.isDeleted) ...[
                        if (widget.copyActions.isNotEmpty) ...[
                          SizedBox(height: isMobile ? 4 : 6),
                          FadeTransition(
                            opacity: _iconsAnimation,
                            child: Row(
                              children: widget.copyActions.map((action) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: action == widget.copyActions.last
                                          ? 0
                                          : 8,
                                    ),
                                    child: OutlinedButton.icon(
                                      onPressed: action.onPressed,
                                      icon: Icon(
                                        action.isSuccess
                                            ? action.successIcon
                                            : action.icon,
                                        size: 16,
                                      ),
                                      label: Text(
                                        action.label,
                                        style: const TextStyle(fontSize: 12),
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
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        SizedBox(height: isMobile ? 3 : 4),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  widget.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: widget.isPinned ? Colors.orange : null,
                                ),
                                onPressed: widget.onTogglePin,
                                tooltip: 'Закрепить',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  widget.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: widget.isFavorite
                                      ? Colors.amber
                                      : null,
                                ),
                                onPressed: widget.onToggleFavorite,
                                tooltip: 'Избранное',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              if (widget.onEdit != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: widget.onEdit,
                                  tooltip: 'Редактировать',
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
            isPinned: widget.isPinned,
            isFavorite: widget.isFavorite,
            isArchived: widget.isArchived,
            isExpired: widget.isExpired,
            isExpiringSoon: widget.isExpiringSoon,
          ).buildPositionedWidgets(),
        ],
      ),
    );
  }
}
