import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class BankCardGridCard extends ConsumerStatefulWidget {
  final BankCardCardDto bankCard;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const BankCardGridCard({
    super.key,
    required this.bankCard,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<BankCardGridCard> createState() => _BankCardGridCardState();
}

class _BankCardGridCardState extends ConsumerState<BankCardGridCard> {
  bool _cardNumberCopied = false;

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

  @override
  Widget build(BuildContext context) {
    final card = widget.bankCard;

    return BaseGridCard(
      title: card.name,
      subtitle: '${_maskCardNumber(card.cardNumber)} • ${card.cardholderName}',
      icon: Icons.credit_card,
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
      copyActions: [
        CardActionItem(
          label: 'Номер',
          onPressed: _copyCardNumber,
          icon: Icons.credit_card,
          successIcon: Icons.check,
          isSuccess: _cardNumberCopied,
        ),
      ],
    );
  }
}
