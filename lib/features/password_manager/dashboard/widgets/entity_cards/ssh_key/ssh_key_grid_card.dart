import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class SshKeyGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<SshKeyCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const SshKeyGridCard({
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
  ConsumerState<SshKeyGridCard> createState() => _SshKeyGridCardState();
}

class _SshKeyGridCardState extends ConsumerState<SshKeyGridCard> {
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

    return BaseGridCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.key,
      category: widget.data.meta.category,
      tags: widget.data.meta.tags,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.sshKey, _itemId),
        );
      },
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
