import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class BankCardListCard extends ConsumerStatefulWidget {
  final BankCardCardDto bankCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

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
    await Clipboard.setData(
      ClipboardData(
        text: widget.bankCard.cardNumber.replaceAll(RegExp(r'\D'), ''),
      ),
    );
    setState(() => _cardNumberCopied = true);
    Toaster.success(title: 'Номер карты скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cardNumberCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.bankCard.id);
  }

  Future<void> _copyHolderName() async {
    await Clipboard.setData(
      ClipboardData(text: widget.bankCard.cardholderName),
    );
    setState(() => _holderNameCopied = true);
    Toaster.success(title: 'Имя держателя скопировано');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _holderNameCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.bankCard.id);
  }

  Future<void> _copyExpiry() async {
    final expiry =
        '${widget.bankCard.expiryMonth}/${widget.bankCard.expiryYear}';
    await Clipboard.setData(ClipboardData(text: expiry));
    setState(() => _expiryCopied = true);
    Toaster.success(title: 'Срок действия скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _expiryCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.bankCard.id);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.bankCard;

    return ExpandableListCard(
      title: card.name,
      subtitle: '${_maskCardNumber(card.cardNumber)} • ${card.cardholderName}',
      trailingSubtitle: '${card.expiryMonth}/${card.expiryYear}',
      icon: Icons.credit_card,
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
