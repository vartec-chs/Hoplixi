import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

class ExpandableListCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? trailingSubtitle;
  final IconData icon;
  final CategoryInCardDto? category;
  final String? description;
  final List<TagInCardDto>? tags;
  final int usedCount;
  final DateTime modifiedAt;

  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final bool isExpired;
  final bool isExpiringSoon;

  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  final List<CardActionItem> copyActions;
  final Widget? customExpandedContent;

  const ExpandableListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingSubtitle,
    required this.icon,
    this.category,
    this.description,
    this.tags,
    required this.usedCount,
    required this.modifiedAt,
    required this.isFavorite,
    required this.isPinned,
    required this.isArchived,
    required this.isDeleted,
    this.isExpired = false,
    this.isExpiringSoon = false,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    required this.copyActions,
    this.customExpandedContent,
  });

  @override
  State<ExpandableListCard> createState() => _ExpandableListCardState();
}

class _ExpandableListCardState extends State<ExpandableListCard>
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
            children: [_buildHeader(theme), _buildExpandedContent(theme)],
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: InkWell(
        onTap: _toggleExpanded,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.category != null)
                      CardCategoryBadge(
                        name: widget.category!.name,
                        color: widget.category!.color,
                      ),
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null ||
                        widget.trailingSubtitle != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.subtitle != null) ...[
                            Expanded(
                              child: Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.trailingSubtitle != null)
                              const SizedBox(width: 4),
                          ],
                          if (widget.trailingSubtitle != null)
                            Text(
                              widget.trailingSubtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildHeaderActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActions(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isDeleted) ...[
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
                    widget.isFavorite ? Icons.star : Icons.star_border,
                    color: widget.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: widget.isFavorite
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
                    widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: widget.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: widget.isPinned ? 'Открепить' : 'Закрепить',
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

  Widget _buildExpandedContent(ThemeData theme) {
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

            if (widget.category != null) ...[
              CardCategoryBadge(
                name: widget.category!.name,
                color: widget.category!.color,
                showIcon: true,
              ),
              const SizedBox(height: 12),
            ],

            if (widget.description != null &&
                widget.description!.isNotEmpty) ...[
              Text(
                'Описание:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],

            if (widget.customExpandedContent != null) ...[
              widget.customExpandedContent!,
              const SizedBox(height: 12),
            ],

            if (widget.copyActions.isNotEmpty)
              HorizontalScrollableActions(actions: widget.copyActions),

            if (widget.tags != null && widget.tags!.isNotEmpty) ...[
              const SizedBox(height: 12),
              CardTagsList(tags: widget.tags),
            ],

            const SizedBox(height: 12),
            CardMetaInfo(
              usedCount: widget.usedCount,
              modifiedAt: widget.modifiedAt,
            ),

            const SizedBox(height: 12),
            CardActionButtons(
              isDeleted: widget.isDeleted,
              isArchived: widget.isArchived,
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
