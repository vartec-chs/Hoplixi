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

class CryptoWalletGridCard extends ConsumerStatefulWidget {
  const CryptoWalletGridCard({
    super.key,
    required this.wallet,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  final CryptoWalletCardDto wallet;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  @override
  ConsumerState<CryptoWalletGridCard> createState() =>
      _CryptoWalletGridCardState();
}

class _CryptoWalletGridCardState extends ConsumerState<CryptoWalletGridCard> {
  bool _privateKeyCopied = false;

  Future<void> _copyPrivateKey() async {
    final dao = await ref.read(cryptoWalletDaoProvider.future);
    final text = await dao.getPrivateKeyFieldById(widget.wallet.id);
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      setState(() => _privateKeyCopied = true);
      Toaster.success(title: 'Private key скопирован');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _privateKeyCopied = false);
      });
    } else {
      Toaster.error(title: 'Private key не найден');
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.wallet.id);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    final subtitle = [
      wallet.walletType,
      if (wallet.network?.isNotEmpty == true) wallet.network!,
    ].join(' • ');

    return BaseGridCard(
      title: wallet.name,
      subtitle: subtitle,
      icon: Icons.currency_bitcoin,
      category: wallet.category,
      tags: wallet.tags,
      usedCount: wallet.usedCount,
      isFavorite: wallet.isFavorite,
      isPinned: wallet.isPinned,
      isArchived: wallet.isArchived,
      isDeleted: wallet.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(
            EntityType.cryptoWallet,
            wallet.id,
          ),
        );
      },
      copyActions: [
        if (wallet.hasPrivateKey)
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
