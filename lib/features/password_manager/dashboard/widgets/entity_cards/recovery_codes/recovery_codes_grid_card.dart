import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class RecoveryCodesGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<RecoveryCodesCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const RecoveryCodesGridCard({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenView,
  });

  @override
  ConsumerState<RecoveryCodesGridCard> createState() =>
      _RecoveryCodesGridCardState();
}

class _RecoveryCodesGridCardState extends ConsumerState<RecoveryCodesGridCard> {
  String get _itemId => widget.data.card.item.itemId;
  RecoveryCodesCardDataDto get _codes => widget.data.card.data;

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_codes.oneTime) 'Одноразовые',
      if (_codes.hasCodes) 'Коды сохранены',
    ];

    return BaseGridCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.vpn_key,
      category: widget.data.meta.category,
      tags: widget.data.meta.tags,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.recoveryCodes, _itemId),
        );
      },
    );
  }
}
