import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class RecoveryCodesListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<RecoveryCodesCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const RecoveryCodesListCard({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    this.onOpenView,
  });

  @override
  ConsumerState<RecoveryCodesListCard> createState() =>
      _RecoveryCodesListCardState();
}

class _RecoveryCodesListCardState extends ConsumerState<RecoveryCodesListCard> {
  RecoveryCodesCardDataDto get _codes => widget.data.card.data;

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_codes.oneTime) 'Одноразовые',
      if (_codes.hasCodes) 'Коды сохранены',
    ];

    return ExpandableListCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.vpn_key,
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
    );
  }
}
