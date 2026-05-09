import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import '../shared/shared.dart';

class BankCardListCard extends ConsumerStatefulWidget {
  final BankCardCardDto bankCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const BankCardListCard({
    super.key,
    required this.bankCard,
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
  ConsumerState<BankCardListCard> createState() => _BankCardListCardState();
}

class _BankCardListCardState extends ConsumerState<BankCardListCard> {
  bool _cardNumberCopied = false;
  bool _holderNameCopied = false;
  bool _expiryCopied = false;

  String _maskCardNumber(String cardNumber) {
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 4) return '•••• ••••';
    return digitsOnly.substring(digitsOnly.length - 4);
  }

  bool _isExpired() {
    final now = DateTime.now();
    final expiryYear = int.tryParse(widget.bankCard.expiryYear) ?? 0;
    final expiryMonth = int.tryParse(widget.bankCard.expiryMonth) ?? 0;
    if (expiryYear < now.year) return true;
    if (expiryYear == now.year && expiryMonth < now.month) return true;
    return false;
  }

  bool _isExpiringSoon() {
    if (_isExpired()) return false;
    final now = DateTime.now();
    final expiryYear = int.tryParse(widget.bankCard.expiryYear) ?? 0;
    final expiryMonth = int.tryParse(widget.bankCard.expiryMonth) ?? 0;
    final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0);
    return expiryDate.isBefore(now.add(const Duration(days: 90)));
  }

  Future<void> _copyCardNumber() async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.bankCard.id,
      text: widget.bankCard.cardNumber.replaceAll(RegExp(r'\D'), ''),
    );
    if (!copied) return;
    setState(() => _cardNumberCopied = true);
    Toaster.success(title: 'Номер карты скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cardNumberCopied = false);
    });
  }

  Future<void> _copyHolderName() async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.bankCard.id,
      text: widget.bankCard.cardholderName,
    );
    if (!copied) return;
    setState(() => _holderNameCopied = true);
    Toaster.success(title: 'Имя держателя скопировано');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _holderNameCopied = false);
    });
  }

  Future<void> _copyExpiry() async {
    final expiry =
        '${widget.bankCard.expiryMonth}/${widget.bankCard.expiryYear}';
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.bankCard.id,
      text: expiry,
    );
    if (!copied) return;
    setState(() => _expiryCopied = true);
    Toaster.success(title: 'Срок действия скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _expiryCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.bankCard;

    return ExpandableListCard(
      title: card.name,
      subtitle: '${_maskCardNumber(card.cardNumber)} • ${card.cardholderName}',
      trailingSubtitle: '${card.expiryMonth}/${card.expiryYear}',
      fallbackIcon: Icons.credit_card,
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
          onPressed: _copyCardNumber,
          icon: Icons.credit_card,
          successIcon: Icons.check,
          isSuccess: _cardNumberCopied,
        ),
        CardActionItem(
          label: 'Держатель',
          onPressed: _copyHolderName,
          icon: Icons.person,
          successIcon: Icons.check,
          isSuccess: _holderNameCopied,
        ),
        CardActionItem(
          label: 'Срок',
          onPressed: _copyExpiry,
          icon: Icons.calendar_today,
          successIcon: Icons.check,
          isSuccess: _expiryCopied,
        ),
      ],
    );
  }
}
