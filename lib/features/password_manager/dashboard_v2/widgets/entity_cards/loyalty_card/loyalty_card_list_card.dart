import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/core/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';

class LoyaltyCardListCard extends ConsumerStatefulWidget {
  const LoyaltyCardListCard({
    super.key,
    required this.loyaltyCard,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    this.onOpenView,
  });

  final LoyaltyCardCardDto loyaltyCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  @override
  ConsumerState<LoyaltyCardListCard> createState() =>
      _LoyaltyCardListCardState();
}

class _LoyaltyCardListCardState extends ConsumerState<LoyaltyCardListCard> {
  bool _numberCopied = false;
  bool _barcodeCopied = false;

  String _maskCardNumber(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }

  bool _isExpired() {
    final expiryDate = widget.loyaltyCard.expiryDate;
    return expiryDate != null && expiryDate.isBefore(DateTime.now());
  }

  bool _isExpiringSoon() {
    final expiryDate = widget.loyaltyCard.expiryDate;
    if (expiryDate == null || _isExpired()) return false;
    return expiryDate.isBefore(DateTime.now().add(const Duration(days: 90)));
  }

  Future<void> _copy(
    String value,
    String title,
    void Function() markSuccess,
  ) async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.loyaltyCard.id,
      text: value,
    );
    if (!copied) return;
    markSuccess();
    Toaster.success(title: title);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.loyaltyCard;
    final trailingSubtitle =
        card.tier ??
        (card.expiryDate != null
            ? '${card.expiryDate!.day.toString().padLeft(2, '0')}.${card.expiryDate!.month.toString().padLeft(2, '0')}.${card.expiryDate!.year}'
            : null);

    return ExpandableListCard(
      title: card.name,
      subtitle: card.cardNumber?.isNotEmpty == true
          ? '${card.programName}  •  ${_maskCardNumber(card.cardNumber!)}'
          : card.programName,
      trailingSubtitle: trailingSubtitle,
      fallbackIcon: Icons.loyalty,
      iconSource: card.iconSource,
      iconValue: card.iconValue,
      category: card.category,
      tags: card.tags,
      usedCount: card.usedCount,
      modifiedAt: card.modifiedAt,
      isFavorite: card.isFavorite,
      isPinned: card.isPinned,
      isArchived: card.isArchived,
      isDeleted: card.isDeleted,
      isExpired: _isExpired(),
      isExpiringSoon: _isExpiringSoon(),
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        CardActionItem(
          label: 'Номер',
          icon: Icons.credit_card_outlined,
          successIcon: Icons.check,
          isSuccess: _numberCopied,
          onPressed: () =>
              _copy(card.cardNumber ?? '', 'Номер карты скопирован', () {
                setState(() => _numberCopied = true);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _numberCopied = false);
                });
              }),
        ),
        if (card.barcodeValue?.isNotEmpty == true)
          CardActionItem(
            label: 'Штрихкод',
            icon: Icons.qr_code,
            successIcon: Icons.check,
            isSuccess: _barcodeCopied,
            onPressed: () =>
                _copy(card.barcodeValue!, 'Штрихкод скопирован', () {
                  setState(() => _barcodeCopied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _barcodeCopied = false);
                  });
                }),
          ),
      ],
    );
  }
}
