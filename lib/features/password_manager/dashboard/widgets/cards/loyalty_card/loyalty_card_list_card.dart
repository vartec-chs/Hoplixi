import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

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
  });

  final LoyaltyCardCardDto loyaltyCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

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
    await Clipboard.setData(ClipboardData(text: value));
    markSuccess();
    Toaster.success(title: title);
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.loyaltyCard.id);
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
      subtitle: '${card.programName} • ${_maskCardNumber(card.cardNumber)}',
      trailingSubtitle: trailingSubtitle,
      icon: Icons.loyalty,
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
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        CardActionItem(
          label: 'Номер',
          icon: Icons.credit_card_outlined,
          successIcon: Icons.check,
          isSuccess: _numberCopied,
          onPressed: () => _copy(card.cardNumber, 'Номер карты скопирован', () {
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
