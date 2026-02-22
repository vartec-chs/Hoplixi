import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class SshKeyListCard extends ConsumerStatefulWidget {
  const SshKeyListCard({
    super.key,
    required this.sshKey,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final SshKeyCardDto sshKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<SshKeyListCard> createState() => _SshKeyListCardState();
}

class _SshKeyListCardState extends ConsumerState<SshKeyListCard> {
  bool _publicKeyCopied = false;
  bool _privateKeyCopied = false;

  Future<void> _copyPublicKey() async {
    await Clipboard.setData(ClipboardData(text: widget.sshKey.publicKey));
    setState(() => _publicKeyCopied = true);
    Toaster.success(title: 'Публичный ключ скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _publicKeyCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.sshKey.id);
  }

  Future<void> _copyPrivateKey() async {
    final dao = await ref.read(sshKeyDaoProvider.future);
    final privateKey = await dao.getPrivateKeyFieldById(widget.sshKey.id);
    if (privateKey != null && privateKey.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: privateKey));
      setState(() => _privateKeyCopied = true);
      Toaster.success(title: 'Приватный ключ скопирован');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _privateKeyCopied = false);
      });
    } else {
      Toaster.error(title: 'Приватный ключ не найден');
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.sshKey.id);
  }

  @override
  Widget build(BuildContext context) {
    final sshKey = widget.sshKey;
    final subtitle = [
      if (sshKey.keyType?.isNotEmpty == true) sshKey.keyType!,
      if (sshKey.usage?.isNotEmpty == true) sshKey.usage!,
    ].join(' • ');

    return ExpandableListCard(
      title: sshKey.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      trailingSubtitle: sshKey.fingerprint,
      icon: Icons.key,
      category: sshKey.category,
      description: sshKey.description,
      tags: sshKey.tags,
      usedCount: sshKey.usedCount,
      modifiedAt: sshKey.modifiedAt,
      isFavorite: sshKey.isFavorite,
      isPinned: sshKey.isPinned,
      isArchived: sshKey.isArchived,
      isDeleted: sshKey.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        CardActionItem(
          label: 'PubKey',
          onPressed: _copyPublicKey,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _publicKeyCopied,
        ),
        CardActionItem(
          label: 'PrivKey',
          onPressed: _copyPrivateKey,
          icon: Icons.vpn_key,
          successIcon: Icons.check,
          isSuccess: _privateKeyCopied,
        ),
      ],
    );
  }
}
