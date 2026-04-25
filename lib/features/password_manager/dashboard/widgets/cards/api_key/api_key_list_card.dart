import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/old/provider/dao_providers.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:intl/intl.dart' show DateFormat;

class ApiKeyListCard extends ConsumerStatefulWidget {
  final ApiKeyCardDto apiKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const ApiKeyListCard({
    super.key,
    required this.apiKey,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    this.onOpenView,
  });

  @override
  ConsumerState<ApiKeyListCard> createState() => _ApiKeyListCardState();
}

class _ApiKeyListCardState extends ConsumerState<ApiKeyListCard> {
  bool _keyCopied = false;

  Future<void> _copyKey() async {
    final dao = await ref.read(apiKeyDaoProvider.future);
    final keyText = await dao.getKeyFieldById(widget.apiKey.id);

    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.apiKey.id,
      text: keyText,
    );
    if (!copied) {
      Toaster.error(title: 'Не удалось получить ключ');
      return;
    }
    setState(() => _keyCopied = true);
    Toaster.success(title: 'Ключ скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _keyCopied = false);
    });
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

  Widget? _buildExpirySection(
    ThemeData theme,
    DateTime? expiresAt,
    bool isExpired,
    bool isExpiringSoon,
  ) {
    if (expiresAt == null) return null;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(expiresAt);
    final Color color;
    final String label;
    if (isExpired) {
      color = theme.colorScheme.error;
      label = 'Истёк: $dateStr';
    } else if (isExpiringSoon) {
      color = Colors.orange;
      label = 'Истекает: $dateStr';
    } else {
      color = theme.colorScheme.onSurfaceVariant;
      label = 'Срок действия: $dateStr';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
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
      fallbackIcon: Icons.api,
      iconSource: apiKey.iconSource,
      iconValue: apiKey.iconValue,
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
      onOpenView: widget.onOpenView,
      onOpenHistory: widget.onOpenHistory,
      customExpandedContent: _buildExpirySection(
        Theme.of(context),
        apiKey.expiresAt,
        isExpired,
        isExpiringSoon,
      ),
      copyActions: _buildCopyActions(),
    );
  }
}
