import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class CryptoWalletGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<CryptoWalletCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const CryptoWalletGridCard({
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
  ConsumerState<CryptoWalletGridCard> createState() =>
      _CryptoWalletGridCardState();
}

class _CryptoWalletGridCardState extends ConsumerState<CryptoWalletGridCard> {
  bool _addressCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  CryptoWalletCardDataDto get _wallet => widget.data.card.data;

  Future<void> _copyAddress() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Адрес недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _addressCopied = true);
    Toaster.success(title: 'Адрес скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _addressCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_wallet.walletType != null) _wallet.walletType!.name,
      if (_wallet.network != null) _wallet.network!.name,
      if (_wallet.watchOnly) 'Только просмотр',
    ];

    return BaseGridCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.account_balance_wallet,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.cryptoWallet, _itemId),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'Адрес',
          onPressed: _copyAddress,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _addressCopied,
        ),
      ],
    );
  }
}
