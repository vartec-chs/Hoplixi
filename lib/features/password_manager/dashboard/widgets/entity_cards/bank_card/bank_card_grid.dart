import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class BankCardGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<BankCardCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const BankCardGridCard({
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
  ConsumerState<BankCardGridCard> createState() => _BankCardGridCardState();
}

class _BankCardGridCardState extends ConsumerState<BankCardGridCard> {
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

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final card = widget.data.card.data;
    final hasHolder = (card.cardholderName ?? '').isNotEmpty;
    final hasNumber = card.hasCardNumber;
    final subtitle = hasHolder
        ? '${hasNumber ? '•••• ••••' : '—'} • ${card.cardholderName}'
        : (hasNumber ? '•••• ••••' : 'Номер не задан');

    return BaseGridCard(
      title: item.name,
      subtitle: subtitle,
      fallbackIcon: Icons.credit_card,
      category: widget.data.meta.category,
      tags: widget.data.meta.tags,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      isExpired: _isExpired(),
      isExpiringSoon: _isExpiringSoon(),
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      copyActions: const [],
    );
  }
}
