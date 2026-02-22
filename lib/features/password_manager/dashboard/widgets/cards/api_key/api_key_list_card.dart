import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class ApiKeyListCard extends ConsumerStatefulWidget {
  final ApiKeyCardDto apiKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const ApiKeyListCard({
    super.key,
    required this.apiKey,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  @override
  ConsumerState<ApiKeyListCard> createState() => _ApiKeyListCardState();
}

class _ApiKeyListCardState extends ConsumerState<ApiKeyListCard> {
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

  List<CardActionItem> _buildCopyActions() {
    return [
      CardActionItem(
        label: 'Ключ',
        onPressed: _copyKey,
        icon: Icons.key,
        successIcon: Icons.check,
        isSuccess: _keyCopied,
      ),
    ];
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

    return ExpandableListCard(
      title: apiKey.name,
      subtitle: subtitleParts.join(' • '),
      icon: Icons.api,
      category: apiKey.category,
      description: apiKey.description,
      tags: apiKey.tags,
      usedCount: apiKey.usedCount,
      modifiedAt: apiKey.modifiedAt,
      isFavorite: apiKey.isFavorite,
      isPinned: apiKey.isPinned,
      isArchived: apiKey.isArchived,
      isDeleted: apiKey.isDeleted,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
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
