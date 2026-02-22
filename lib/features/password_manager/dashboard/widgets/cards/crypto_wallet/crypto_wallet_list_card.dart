import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class CryptoWalletListCard extends ConsumerStatefulWidget {
  const CryptoWalletListCard({
    super.key,
    required this.wallet,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final CryptoWalletCardDto wallet;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<CryptoWalletListCard> createState() =>
      _CryptoWalletListCardState();
}

class _CryptoWalletListCardState extends ConsumerState<CryptoWalletListCard> {
  bool _mnemonicCopied = false;
  bool _privateKeyCopied = false;

  Future<void> _copyMnemonic() async {
    final dao = await ref.read(cryptoWalletDaoProvider.future);
    final text = await dao.getMnemonicFieldById(widget.wallet.id);
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      setState(() => _mnemonicCopied = true);
      Toaster.success(title: 'Mnemonic скопирован');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _mnemonicCopied = false);
      });
    } else {
      Toaster.error(title: 'Mnemonic не найден');
    }
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.wallet.id);
  }

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

  List<CardActionItem> _buildCopyActions() {
    final actions = <CardActionItem>[];
    if (widget.wallet.hasMnemonic) {
      actions.add(
        CardActionItem(
          label: 'Mnemonic',
          onPressed: _copyMnemonic,
          icon: Icons.key,
          successIcon: Icons.check,
          isSuccess: _mnemonicCopied,
        ),
      );
    }
    if (widget.wallet.hasPrivateKey) {
      actions.add(
        CardActionItem(
          label: 'PrivKey',
          onPressed: _copyPrivateKey,
          icon: Icons.vpn_key,
          successIcon: Icons.check,
          isSuccess: _privateKeyCopied,
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;
    final subtitleParts = [
      wallet.walletType,
      if (wallet.network?.isNotEmpty == true) wallet.network!,
      if (wallet.watchOnly) 'watch-only',
    ];

    return ExpandableListCard(
      title: wallet.name,
      subtitle: subtitleParts.join(' • '),
      trailingSubtitle: wallet.hardwareDevice,
      icon: Icons.currency_bitcoin,
      category: wallet.category,
      description: wallet.description,
      tags: wallet.tags,
      usedCount: wallet.usedCount,
      modifiedAt: wallet.modifiedAt,
      isFavorite: wallet.isFavorite,
      isPinned: wallet.isPinned,
      isArchived: wallet.isArchived,
      isDeleted: wallet.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: _buildCopyActions(),
    );
  }
}
