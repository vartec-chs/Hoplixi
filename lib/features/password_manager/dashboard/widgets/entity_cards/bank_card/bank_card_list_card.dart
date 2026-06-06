import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class BankCardListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<BankCardCardDto> data;
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
  ConsumerState<BankCardListCard> createState() => _BankCardListCardState();
}

class _BankCardListCardState extends ConsumerState<BankCardListCard> {
  bool _cardNumberCopied = false;
  bool _holderNameCopied = false;
  bool _expiryCopied = false;

  String get _itemId => widget.data.card.item.itemId;

  bool _isExpired() {
    final now = DateTime.now();
    final card = widget.data.card.data;
    final expiryYear = int.tryParse(card.expiryYear ?? '') ?? 0;
    final expiryMonth = int.tryParse(card.expiryMonth ?? '') ?? 0;
    if (expiryYear < now.year) return true;
    if (expiryYear == now.year && expiryMonth < now.month) return true;
    return false;
  }

  bool _isExpiringSoon() {
    if (_isExpired()) return false;
    final now = DateTime.now();
    final card = widget.data.card.data;
    final expiryYear = int.tryParse(card.expiryYear ?? '') ?? 0;
    final expiryMonth = int.tryParse(card.expiryMonth ?? '') ?? 0;
    final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0);
    return expiryDate.isBefore(now.add(const Duration(days: 90)));
  }

  Future<void> _copyCardNumber() async {
    final value = null;
    if (value == null) {
      Toaster.error(title: 'Номер карты недоступен');
      return;
    }
    final copied = await copyCardValue(
      ref: ref,
      itemId: _itemId,
      text: value.replaceAll(RegExp(r'\D'), ''),
    );
    if (!copied) return;
    setState(() => _cardNumberCopied = true);
    Toaster.success(title: 'Номер карты скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cardNumberCopied = false);
    });
  }

  Future<void> _copyHolderName() async {
    final holder = widget.data.card.data.cardholderName ?? '';
    if (holder.isEmpty) return;
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: holder);
    if (!copied) return;
    setState(() => _holderNameCopied = true);
    Toaster.success(title: 'Имя держателя скопировано');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _holderNameCopied = false);
    });
  }

  Future<void> _copyExpiry() async {
    final card = widget.data.card.data;
    final expiry = '${card.expiryMonth ?? ''}/${card.expiryYear ?? ''}';
    if (expiry == '/') return;
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: expiry);
    if (!copied) return;
    setState(() => _expiryCopied = true);
    Toaster.success(title: 'Срок действия скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _expiryCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final card = widget.data.card.data;
    final hasHolder = (card.cardholderName ?? '').isNotEmpty;
    final hasNumber = card.hasCardNumber;
    final hasExpiry =
        (card.expiryMonth ?? '').isNotEmpty &&
        (card.expiryYear ?? '').isNotEmpty;
    final subtitle = hasHolder
        ? '${hasNumber ? '•••• ••••' : '—'} • ${card.cardholderName}'
        : (hasNumber ? '•••• ••••' : 'Номер не задан');

    return ExpandableListCard(
      title: item.name,
      subtitle: subtitle,
      trailingSubtitle: hasExpiry
          ? '${card.expiryMonth}/${card.expiryYear}'
          : null,
      fallbackIcon: Icons.credit_card,
      category: widget.data.meta.category,
      description: item.description,
      tags: widget.data.meta.tags,
      modifiedAt: item.modifiedAt,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
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
        if (hasNumber)
          CardActionItem(
            label: 'Номер',
            onPressed: _copyCardNumber,
            icon: Icons.credit_card,
            successIcon: Icons.check,
            isSuccess: _cardNumberCopied,
          ),
        if (hasHolder)
          CardActionItem(
            label: 'Держатель',
            onPressed: _copyHolderName,
            icon: Icons.person,
            successIcon: Icons.check,
            isSuccess: _holderNameCopied,
          ),
        if (hasExpiry)
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
