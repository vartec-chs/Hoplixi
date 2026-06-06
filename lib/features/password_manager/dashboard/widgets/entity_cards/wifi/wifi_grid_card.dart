import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class WifiGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<WifiCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const WifiGridCard({
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
  ConsumerState<WifiGridCard> createState() => _WifiGridCardState();
}

class _WifiGridCardState extends ConsumerState<WifiGridCard> {
  bool _passwordCopied = false;
  bool _ssidCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  WifiCardDataDto get _wifi => widget.data.card.data;

  Future<void> _copyPassword() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'Пароль недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });
  }

  Future<void> _copySsid() async {
    final ssid = _wifi.ssid;
    if (ssid.isEmpty) {
      Toaster.warning(title: 'SSID не указан');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: ssid);
    if (!copied) return;
    setState(() => _ssidCopied = true);
    Toaster.success(title: 'SSID скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _ssidCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_wifi.securityType != null) _wifi.securityType!.name,
      if (_wifi.encryption != null) _wifi.encryption!.name,
      if (_wifi.hiddenSsid) 'Скрытая',
    ];

    return BaseGridCard(
      title: _wifi.ssid,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.wifi,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.wifi, _itemId),
        );
      },
      copyActions: [
        if (_wifi.ssid.isNotEmpty)
          CardActionItem(
            label: 'SSID',
            onPressed: _copySsid,
            icon: Icons.wifi,
            successIcon: Icons.check,
            isSuccess: _ssidCopied,
          ),
        if (_wifi.hasWifiPassword)
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
