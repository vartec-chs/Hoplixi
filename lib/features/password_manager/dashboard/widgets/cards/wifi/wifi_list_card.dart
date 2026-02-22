import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class WifiListCard extends ConsumerStatefulWidget {
  const WifiListCard({
    super.key,
    required this.wifi,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final WifiCardDto wifi;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<WifiListCard> createState() => _WifiListCardState();
}

class _WifiListCardState extends ConsumerState<WifiListCard> {
  bool _ssidCopied = false;
  bool _passwordCopied = false;

  Future<void> _copySsid() async {
    await Clipboard.setData(ClipboardData(text: widget.wifi.ssid));
    setState(() => _ssidCopied = true);
    Toaster.success(title: 'SSID скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _ssidCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.wifi.id);
  }

  Future<void> _copyPassword() async {
    final dao = await ref.read(wifiDaoProvider.future);
    final password = await dao.getPasswordFieldById(widget.wifi.id);
    if (password != null && password.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: password));
      setState(() => _passwordCopied = true);
      Toaster.success(title: 'Пароль Wi-Fi скопирован');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _passwordCopied = false);
      });
    } else {
      Toaster.error(title: 'Пароль Wi-Fi не найден');
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.wifi.id);
  }

  @override
  Widget build(BuildContext context) {
    final wifi = widget.wifi;
    final subtitleParts = [
      wifi.ssid,
      if (wifi.security?.isNotEmpty == true) wifi.security!,
      if (wifi.hidden) 'hidden',
    ];

    return ExpandableListCard(
      title: wifi.name,
      subtitle: subtitleParts.join(' • '),
      trailingSubtitle: wifi.priority == null ? null : 'prio ${wifi.priority}',
      icon: Icons.wifi,
      category: wifi.category,
      description: wifi.description,
      tags: wifi.tags,
      usedCount: wifi.usedCount,
      modifiedAt: wifi.modifiedAt,
      isFavorite: wifi.isFavorite,
      isPinned: wifi.isPinned,
      isArchived: wifi.isArchived,
      isDeleted: wifi.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        CardActionItem(
          label: 'SSID',
          onPressed: _copySsid,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _ssidCopied,
        ),
        if (wifi.hasPassword)
          CardActionItem(
            label: 'Пароль',
            onPressed: _copyPassword,
            icon: Icons.lock,
            successIcon: Icons.check,
            isSuccess: _passwordCopied,
          ),
      ],
    );
  }
}
