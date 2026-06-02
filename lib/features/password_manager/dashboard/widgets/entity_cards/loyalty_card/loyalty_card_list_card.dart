import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class LoyaltyCardListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<LoyaltyCardCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const LoyaltyCardListCard({
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
  ConsumerState<LoyaltyCardListCard> createState() =>
      _LoyaltyCardListCardState();
}

class _LoyaltyCardListCardState extends ConsumerState<LoyaltyCardListCard> {
  bool _cardNumberCopied = false;
  bool _barcodeCopied = false;
  bool _passwordCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  LoyaltyCardCardDataDto get _loyalty => widget.data.card.data;

  Future<void> _copyCardNumber() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Номер карты недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _cardNumberCopied = true);
    Toaster.success(title: 'Номер карты скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cardNumberCopied = false);
    });
  }

  Future<void> _copyBarcode() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Штрих-код недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _barcodeCopied = true);
    Toaster.success(title: 'Штрих-код скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _barcodeCopied = false);
    });
  }

  Future<void> _copyPassword() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Пароль недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_loyalty.programName.isNotEmpty) _loyalty.programName,
      if (_loyalty.barcodeType != null) _loyalty.barcodeType!.name,
    ];

    return ExpandableListCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.card_giftcard,
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
        if (_loyalty.hasCardNumber)
          CardActionItem(
            label: 'Номер',
            onPressed: _copyCardNumber,
            icon: Icons.credit_card,
            successIcon: Icons.check,
            isSuccess: _cardNumberCopied,
          ),
        if (_loyalty.hasBarcodeValue)
          CardActionItem(
            label: 'Штрих-код',
            onPressed: _copyBarcode,
            icon: Icons.qr_code,
            successIcon: Icons.check,
            isSuccess: _barcodeCopied,
          ),
        if (_loyalty.hasPassword)
          CardActionItem(
            label: 'Пароль',
            onPressed: _copyPassword,
            icon: Icons.lock,
            successIcon: Icons.check,
            isSuccess: _passwordCopied,
          ),
      ],
    );
  }
}
