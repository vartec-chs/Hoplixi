import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/file_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class FileListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<FileCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const FileListCard({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
    this.onOpenHistory,
    this.onOpenView,
  });

  @override
  ConsumerState<FileListCard> createState() => _FileListCardState();
}

class _FileListCardState extends ConsumerState<FileListCard> {
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final index = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, index)).toStringAsFixed(1)} ${suffixes[index]}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final file = widget.data.card.data;

    return ExpandableListCard(
      title: item.name,
      subtitle: file.fileName,
      trailingSubtitle: _formatFileSize(file.fileSize ?? 0),
      fallbackIcon: Icons.insert_drive_file,
      category: widget.data.meta.category,
      description: item.description,
      tags: widget.data.meta.tags,
      modifiedAt: item.modifiedAt,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        if (widget.onDecrypt != null)
          CardActionItem(
            label: 'Скачать',
            onPressed: widget.onDecrypt!,
            icon: Icons.download,
          ),
        CardActionItem(
          label: 'Открыть',
          onPressed: () {
            context.push(
              AppRoutesPaths.dashboardEntityEdit(EntityType.file, item.itemId),
            );
          },
          icon: Icons.open_in_new,
        ),
      ],
    );
  }
}
