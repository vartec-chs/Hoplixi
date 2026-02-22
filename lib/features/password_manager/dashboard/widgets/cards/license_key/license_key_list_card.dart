import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class LicenseKeyListCard extends ConsumerStatefulWidget {
  const LicenseKeyListCard({
    super.key,
    required this.license,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final LicenseKeyCardDto license;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<LicenseKeyListCard> createState() => _LicenseKeyListCardState();
}

class _LicenseKeyListCardState extends ConsumerState<LicenseKeyListCard> {
  bool _productCopied = false;

  Future<void> _copyProduct() async {
    await Clipboard.setData(ClipboardData(text: widget.license.product));
    setState(() => _productCopied = true);
    Toaster.success(title: 'Продукт скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _productCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.license.id);
  }

  @override
  Widget build(BuildContext context) {
    final license = widget.license;
    final now = DateTime.now();
    final isExpired =
        license.expiresAt != null && license.expiresAt!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        license.expiresAt != null &&
        license.expiresAt!.difference(now).inDays <= 30;

    final subtitleParts = [
      license.product,
      if (license.licenseType?.isNotEmpty == true) license.licenseType!,
    ];

    return ExpandableListCard(
      title: license.name,
      subtitle: subtitleParts.join(' • '),
      trailingSubtitle: license.orderId,
      icon: Icons.workspace_premium,
      category: license.category,
      description: license.description,
      tags: license.tags,
      usedCount: license.usedCount,
      modifiedAt: license.modifiedAt,
      isFavorite: license.isFavorite,
      isPinned: license.isPinned,
      isArchived: license.isArchived,
      isDeleted: license.isDeleted,
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
          label: 'Product',
          onPressed: _copyProduct,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _productCopied,
        ),
      ],
    );
  }
}
