import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/routing/paths.dart';

/// Карточка файла для режима сетки
/// Минимальная ширина: 240px для предотвращения чрезмерного сжатия
class FileGridCard extends ConsumerStatefulWidget {
  final FileCardDto file;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;

  const FileGridCard({
    super.key,
    required this.file,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
  });

  @override
  ConsumerState<FileGridCard> createState() => _FileGridCardState();
}

class _FileGridCardState extends ConsumerState<FileGridCard>
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240),
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.insert_drive_file,
                              size: 20,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Spacer(),
                          if (!file.isDeleted)
                            FadeTransition(
                              opacity: _iconsAnimation,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (file.isArchived)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.archive,
                                        size: 16,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  if (file.usedCount >=
                                      MainConstants.popularItemThreshold)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.local_fire_department,
                                        size: 16,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (file.category != null) ...[
                        CardCategoryBadge(
                          name: file.category!.name,
                          color: file.category!.color,
                        ),
                        const SizedBox(height: 8),
                      ],

                      Text(
                        file.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),
                      Text(
                        '${file.fileName} • ${_formatFileSize(file.fileSize)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      if (file.tags != null && file.tags!.isNotEmpty)
                        CardTagsList(tags: file.tags!, showTitle: false),

                      if (!file.isDeleted) ...[
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onDecrypt,
                                  icon: const Icon(
                                    Icons.file_download,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Скачать',
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
                                        EntityType.file,
                                        file.id,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text(
                                    'Открыть',
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
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _iconsAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  file.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                  color: file.isPinned ? Colors.orange : null,
                                ),
                                onPressed: widget.onTogglePin,
                                tooltip: 'Закрепить',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  file.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: file.isFavorite ? Colors.amber : null,
                                ),
                                onPressed: widget.onToggleFavorite,
                                tooltip: 'Избранное',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  context.push(
                                    AppRoutesPaths.dashboardEntityEdit(
                                      EntityType.file,
                                      file.id,
                                    ),
                                  );
                                },
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
            isPinned: file.isPinned,
            isFavorite: file.isFavorite,
            isArchived: file.isArchived,
          ).buildPositionedWidgets(),
        ],
      ),
    );
  }
}
