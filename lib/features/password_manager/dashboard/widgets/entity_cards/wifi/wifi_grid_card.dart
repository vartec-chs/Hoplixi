import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

import '../shared/shared.dart';

class WifiGridCard extends ConsumerStatefulWidget {
  const WifiGridCard({
    super.key,
    required this.wifi,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenView,
  });

  final WifiCardDto wifi;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  @override
  ConsumerState<WifiGridCard> createState() => _WifiGridCardState();
}

class _WifiGridCardState extends ConsumerState<WifiGridCard> {
  bool _passwordCopied = false;

  Future<void> _copyPassword() async {
    final dao = await ref.read(wifiDaoProvider.future);
    final text = await dao.getPasswordFieldById(widget.wifi.id);
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.wifi.id,
      text: text,
    );
    if (!copied) {
      Toaster.error(title: 'Пароль Wi-Fi не найден');
      return;
    }
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль Wi-Fi скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wifi = widget.wifi;
    final subtitle = [
      wifi.ssid,
      if (wifi.security?.isNotEmpty == true) wifi.security! else 'Open',
    ].join(' • ');

    return BaseGridCard(
      title: wifi.name,
      subtitle: subtitle,
      fallbackIcon: Icons.wifi,
      iconSource: wifi.iconSource,
      iconValue: wifi.iconValue,
      category: wifi.category,
      tags: wifi.tags,
      usedCount: wifi.usedCount,
      isFavorite: wifi.isFavorite,
      isPinned: wifi.isPinned,
      isArchived: wifi.isArchived,
      isDeleted: wifi.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.wifi, wifi.id),
        );
      },
      copyActions: [
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
