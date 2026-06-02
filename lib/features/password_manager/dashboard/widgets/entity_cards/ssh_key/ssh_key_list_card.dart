import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/ssh_key_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class SshKeyListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<SshKeyCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const SshKeyListCard({
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
  ConsumerState<SshKeyListCard> createState() => _SshKeyListCardState();
}

class _SshKeyListCardState extends ConsumerState<SshKeyListCard> {
  bool _publicKeyCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  SshKeyCardDataDto get _sshKey => widget.data.card.data;

  Future<void> _copyPublicKey() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Публичный ключ недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _publicKeyCopied = true);
    Toaster.success(title: 'Публичный ключ скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _publicKeyCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_sshKey.keyType != null) _sshKey.keyType!.name,
      if (_sshKey.keySize != null) '${_sshKey.keySize} бит',
      if (_sshKey.hasPrivateKey) '🔒 Приватный',
    ];

    return ExpandableListCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.key,
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
          label: 'Публичный ключ',
          onPressed: _copyPublicKey,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _publicKeyCopied,
        ),
      ],
    );
  }
}
