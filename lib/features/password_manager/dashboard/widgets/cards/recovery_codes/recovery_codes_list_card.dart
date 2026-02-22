import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class RecoveryCodesListCard extends ConsumerStatefulWidget {
  const RecoveryCodesListCard({
    super.key,
    required this.recoveryCodes,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final RecoveryCodesCardDto recoveryCodes;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<RecoveryCodesListCard> createState() =>
      _RecoveryCodesListCardState();
}

class _RecoveryCodesListCardState extends ConsumerState<RecoveryCodesListCard> {
  bool _hintCopied = false;

  Future<void> _copyHint() async {
    final hint = widget.recoveryCodes.displayHint;
    if (hint == null || hint.isEmpty) {
      Toaster.error(title: 'Подсказка отсутствует');
      return;
    }
    await Clipboard.setData(ClipboardData(text: hint));
    setState(() => _hintCopied = true);
    Toaster.success(title: 'Подсказка скопирована');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hintCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.recoveryCodes.id);
  }

  @override
  Widget build(BuildContext context) {
    final recoveryCodes = widget.recoveryCodes;
    final codesCount = recoveryCodes.codesCount ?? 0;
    final usedCount = recoveryCodes.codesUsedCount ?? 0;
    final subtitle = 'Использовано: $usedCount/$codesCount';

    return ExpandableListCard(
      title: recoveryCodes.name,
      subtitle: subtitle,
      trailingSubtitle: recoveryCodes.oneTime == true
          ? 'one-time'
          : 'multi-use',
      icon: Icons.security,
      category: recoveryCodes.category,
      description: recoveryCodes.description,
      tags: recoveryCodes.tags,
      usedCount: recoveryCodes.usedCount,
      modifiedAt: recoveryCodes.modifiedAt,
      isFavorite: recoveryCodes.isFavorite,
      isPinned: recoveryCodes.isPinned,
      isArchived: recoveryCodes.isArchived,
      isDeleted: recoveryCodes.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        if ((recoveryCodes.displayHint ?? '').isNotEmpty)
          CardActionItem(
            label: 'Hint',
            onPressed: _copyHint,
            icon: Icons.copy,
            successIcon: Icons.check,
            isSuccess: _hintCopied,
          ),
      ],
    );
  }
}
