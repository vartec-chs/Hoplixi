import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/db_core/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';

class LoyaltyCardGridCard extends ConsumerStatefulWidget {
  const LoyaltyCardGridCard({
    super.key,
    required this.loyaltyCard,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenView,
  });

  final LoyaltyCardCardDto loyaltyCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  @override
  ConsumerState<LoyaltyCardGridCard> createState() =>
      _LoyaltyCardGridCardState();
}

class _LoyaltyCardGridCardState extends ConsumerState<LoyaltyCardGridCard> {
  bool _numberCopied = false;

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

  Future<void> _copyNumber() async {
    if (widget.loyaltyCard.cardNumber == null) {
      Toaster.warning(title: 'Номер карты отсутствует');
      return;
    }
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.loyaltyCard.id,
      text: widget.loyaltyCard.cardNumber,
    );
    if (!copied) return;
    setState(() => _numberCopied = true);
    Toaster.success(title: 'Номер карты скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _numberCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.loyaltyCard;

    return BaseGridCard(
      title: card.name,
      subtitle: card.cardNumber?.isNotEmpty == true
          ? '${card.programName}  •  ${_maskCardNumber(card.cardNumber!)}'
          : card.programName,
      fallbackIcon: Icons.loyalty,
      iconSource: card.iconSource,
      iconValue: card.iconValue,
      category: card.category,
      tags: card.tags,
      usedCount: card.usedCount,
      isFavorite: card.isFavorite,
      isPinned: card.isPinned,
      isArchived: card.isArchived,
      isDeleted: card.isDeleted,
      isExpired: _isExpired(),
      isExpiringSoon: _isExpiringSoon(),
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      copyActions: [
        CardActionItem(
          label: 'Номер',
          icon: Icons.credit_card_outlined,
          successIcon: Icons.check,
          isSuccess: _numberCopied,
          onPressed: _copyNumber,
        ),
      ],
    );
  }
}
