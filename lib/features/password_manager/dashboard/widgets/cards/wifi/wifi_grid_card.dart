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

class WifiGridCard extends ConsumerStatefulWidget {
  const WifiGridCard({
    super.key,
    required this.wifi,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  final WifiCardDto wifi;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  @override
  ConsumerState<WifiGridCard> createState() => _WifiGridCardState();
}

class _WifiGridCardState extends ConsumerState<WifiGridCard> {
  bool _passwordCopied = false;

  Future<void> _copyPassword() async {
    final dao = await ref.read(wifiDaoProvider.future);
    final text = await dao.getPasswordFieldById(widget.wifi.id);
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
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
    final subtitle = [
      wifi.ssid,
      if (wifi.security?.isNotEmpty == true) wifi.security! else 'Open',
    ].join(' • ');

    return BaseGridCard(
      title: wifi.name,
      subtitle: subtitle,
      icon: Icons.wifi,
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
