import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/api_key_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class ApiKeyListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<ApiKeyCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const ApiKeyListCard({
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
  ConsumerState<ApiKeyListCard> createState() => _ApiKeyListCardState();
}

class _ApiKeyListCardState extends ConsumerState<ApiKeyListCard> {
  bool _keyCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  ApiKeyCardDataDto get _apiKey => widget.data.card.data;

  Future<void> _copyKey() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Ключ недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _keyCopied = true);
    Toaster.success(title: 'API-ключ скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _keyCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if ((_apiKey.service ?? '').isNotEmpty) _apiKey.service!,
      if (_apiKey.environment != null) _apiKey.environment!.name,
      if (_apiKey.tokenType != null) _apiKey.tokenType!.name,
    ];

    return ExpandableListCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.api,
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
          label: 'Ключ',
          onPressed: _copyKey,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _keyCopied,
        ),
      ],
    );
  }
}
