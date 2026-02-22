import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class IdentityListCard extends ConsumerStatefulWidget {
  const IdentityListCard({
    super.key,
    required this.identity,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final IdentityCardDto identity;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<IdentityListCard> createState() => _IdentityListCardState();
}

class _IdentityListCardState extends ConsumerState<IdentityListCard> {
  bool _idCopied = false;

  Future<void> _copyIdNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.identity.idNumber));
    setState(() => _idCopied = true);
    Toaster.success(title: 'Номер документа скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _idCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.identity.id);
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

    final subtitleParts = [
      identity.idType,
      identity.idNumber,
      if (identity.verified) 'verified',
    ];

    return ExpandableListCard(
      title: identity.name,
      subtitle: subtitleParts.join(' • '),
      trailingSubtitle: identity.fullName,
      icon: Icons.badge,
      category: identity.category,
      description: identity.description,
      tags: identity.tags,
      usedCount: identity.usedCount,
      modifiedAt: identity.modifiedAt,
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
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        CardActionItem(
          label: 'ID',
          onPressed: _copyIdNumber,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _idCopied,
        ),
      ],
    );
  }
}
