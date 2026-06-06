import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class CryptoWalletListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<CryptoWalletCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const CryptoWalletListCard({
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
  ConsumerState<CryptoWalletListCard> createState() =>
      _CryptoWalletListCardState();
}

class _CryptoWalletListCardState extends ConsumerState<CryptoWalletListCard> {
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

    return ExpandableListCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.account_balance_wallet,
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
