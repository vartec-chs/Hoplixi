import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class LicenseKeyGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<LicenseKeyCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const LicenseKeyGridCard({
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
  ConsumerState<LicenseKeyGridCard> createState() => _LicenseKeyGridCardState();
}

class _LicenseKeyGridCardState extends ConsumerState<LicenseKeyGridCard> {
  bool _keyCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  LicenseKeyCardDataDto get _license => widget.data.card.data;

  Future<void> _copyKey() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Лицензионный ключ недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _keyCopied = true);
    Toaster.success(title: 'Лицензионный ключ скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _keyCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if ((_license.vendor ?? '').isNotEmpty) _license.vendor!,
      if (_license.productName.isNotEmpty) _license.productName,
      if (_license.licenseType != null) _license.licenseType!.name,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.licenseKey, _itemId),
        );
      },
      copyActions: [
        if (_license.hasKey)
          CardActionItem(
            label: 'Ключ',
            onPressed: _copyKey,
            icon: Icons.copy,
            successIcon: Icons.check,
            isSuccess: _keyCopied,
          ),
      ],
    );
  }
}
