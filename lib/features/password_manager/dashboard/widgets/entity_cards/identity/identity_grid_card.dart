import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';

import '../shared/shared.dart';

class IdentityGridCard extends ConsumerStatefulWidget {
  const IdentityGridCard({
    super.key,
    required this.identity,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenView,
  });

  final IdentityCardDto identity;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  @override
  ConsumerState<IdentityGridCard> createState() => _IdentityGridCardState();
}

class _IdentityGridCardState extends ConsumerState<IdentityGridCard> {
  bool _idCopied = false;

  Future<void> _copyId() async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.identity.id,
      text: widget.identity.idNumber,
    );
    if (!copied) return;
    setState(() => _idCopied = true);
    Toaster.success(title: 'Номер документа скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _idCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.identity;
    final now = DateTime.now();
    final isExpired =
        identity.expiryDate != null && identity.expiryDate!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        identity.expiryDate != null &&
        identity.expiryDate!.difference(now).inDays <= 30;

    return BaseGridCard(
      title: identity.name,
      subtitle: '${identity.idType} • ${identity.idNumber}',
      fallbackIcon: Icons.badge,
      category: identity.category,
      tags: identity.tags,
      usedCount: identity.usedCount,
      isFavorite: identity.isFavorite,
      isPinned: identity.isPinned,
      isArchived: identity.isArchived,
      isDeleted: identity.isDeleted,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.identity, identity.id),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'ID',
          onPressed: _copyId,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _idCopied,
        ),
      ],
    );
  }
}
