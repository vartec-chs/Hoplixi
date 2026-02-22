import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class SshKeyGridCard extends ConsumerStatefulWidget {
  const SshKeyGridCard({
    super.key,
    required this.sshKey,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  final SshKeyCardDto sshKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  @override
  ConsumerState<SshKeyGridCard> createState() => _SshKeyGridCardState();
}

class _SshKeyGridCardState extends ConsumerState<SshKeyGridCard> {
  bool _privateKeyCopied = false;

  Future<void> _copyPrivateKey() async {
    final dao = await ref.read(sshKeyDaoProvider.future);
    final text = await dao.getPrivateKeyFieldById(widget.sshKey.id);
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
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
      if (sshKey.fingerprint?.isNotEmpty == true) sshKey.fingerprint!,
    ].join(' • ');

    return BaseGridCard(
      title: sshKey.name,
      subtitle: subtitle.isEmpty ? null : subtitle,
      icon: Icons.key,
      category: sshKey.category,
      tags: sshKey.tags,
      usedCount: sshKey.usedCount,
      isFavorite: sshKey.isFavorite,
      isPinned: sshKey.isPinned,
      isArchived: sshKey.isArchived,
      isDeleted: sshKey.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.sshKey, sshKey.id),
        );
      },
      copyActions: [
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
