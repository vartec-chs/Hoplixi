import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/shared/ui/button.dart';

class FileListCard extends ConsumerStatefulWidget {
  final FileCardDto file;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;
  final VoidCallback? onOpenHistory;

  const FileListCard({
    super.key,
    required this.file,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
    this.onOpenHistory,
  });

  @override
  ConsumerState<FileListCard> createState() => _FileListCardState();
}

class _FileListCardState extends ConsumerState<FileListCard>
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

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = widget.file;

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            children: [_buildHeader(theme), _buildExpandedContent(theme)],
          ),
        ),
        ...CardStatusIndicators(
          isPinned: file.isPinned,
          isFavorite: file.isFavorite,
          isArchived: file.isArchived,
        ).buildPositionedWidgets(),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final file = widget.file;

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
                  Icons.insert_drive_file,
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
                      file.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${file.fileName} • ${_formatFileSize(file.fileSize)}',
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
              if (file.tags != null && file.tags!.isNotEmpty) ...[
                const SizedBox(width: 16),
                SizedBox(width: 150, child: CardTagsList(tags: file.tags!)),
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
    final file = widget.file;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!file.isDeleted) ...[
          AnimatedBuilder(
            animation: _iconsAnimation,
            builder: (context, child) {
              return Opacity(opacity: _iconsAnimation.value, child: child);
            },
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    file.isFavorite ? Icons.star : Icons.star_border,
                    color: file.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: widget.onToggleFavorite,
                  tooltip: file.isFavorite
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
                    file.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: file.isPinned ? Colors.orange : null,
                  ),
                  onPressed: widget.onTogglePin,
                  tooltip: file.isPinned ? 'Открепить' : 'Закрепить',
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
    final file = widget.file;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(
                  theme,
                  label: 'Имя файла',
                  value: file.fileName,
                  icon: Icons.description,
                ),
                const SizedBox(height: 8),
                _buildMetaRow(
                  theme,
                  label: 'Размер',
                  value: _formatFileSize(file.fileSize),
                  icon: Icons.data_usage,
                ),
              ],
            ),

            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardMetaInfo(
                  usedCount: file.usedCount,
                  modifiedAt: file.modifiedAt,
                ),
                const SizedBox(height: 8),
                if (file.category != null)
                  Row(
                    children: [
                      const Icon(Icons.folder, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      CardCategoryBadge(
                        name: file.category!.name,
                        color: file.category!.color,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!file.isDeleted) ...[
              SmoothButton(
                isFullWidth: true,
                size: SmoothButtonSize.small,
                label: 'Расшифровать',
                onPressed: widget.onDecrypt,
                variant: SmoothButtonVariant.normal,
                type: SmoothButtonType.outlined,
              ),
              const SizedBox(height: 8),
            ],

            CardActionButtons(
              isDeleted: file.isDeleted,
              isArchived: file.isArchived,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
