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

class ApiKeyGridCard extends ConsumerStatefulWidget {
  final ApiKeyCardDto apiKey;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const ApiKeyGridCard({
    super.key,
    required this.apiKey,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<ApiKeyGridCard> createState() => _ApiKeyGridCardState();
}

class _ApiKeyGridCardState extends ConsumerState<ApiKeyGridCard> {
  bool _keyCopied = false;

  Future<void> _copyKey() async {
    final dao = await ref.read(apiKeyDaoProvider.future);
    final keyText = await dao.getKeyFieldById(widget.apiKey.id);

    if (keyText != null) {
      await Clipboard.setData(ClipboardData(text: keyText));
      setState(() => _keyCopied = true);
      Toaster.success(title: 'Ключ скопирован');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _keyCopied = false);
      });
    } else {
      Toaster.error(title: 'Не удалось получить ключ');
    }
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.apiKey.id);
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = widget.apiKey;

    final DateTime now = DateTime.now();
    final bool isExpired =
        apiKey.expiresAt != null && apiKey.expiresAt!.isBefore(now);
    final bool isExpiringSoon =
        !isExpired &&
        apiKey.expiresAt != null &&
        apiKey.expiresAt!.difference(now).inDays <= 30;

    final subtitleParts = [
      apiKey.service,
      if (apiKey.environment?.isNotEmpty == true) apiKey.environment!,
      if (apiKey.tokenType?.isNotEmpty == true) apiKey.tokenType!,
    ];

    return BaseGridCard(
      title: apiKey.name,
      subtitle: subtitleParts.join(' • '),
      icon: Icons.api,
      category: apiKey.category,
      tags: apiKey.tags,
      usedCount: apiKey.usedCount,
      isFavorite: apiKey.isFavorite,
      isPinned: apiKey.isPinned,
      isArchived: apiKey.isArchived,
      isDeleted: apiKey.isDeleted,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.apiKey, apiKey.id),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'Ключ',
          onPressed: _copyKey,
          icon: Icons.key,
          successIcon: Icons.check,
          isSuccess: _keyCopied,
        ),
      ],
    );
  }
}
