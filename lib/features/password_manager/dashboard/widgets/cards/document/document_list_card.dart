import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class DocumentListCard extends ConsumerStatefulWidget {
  final DocumentCardDto document;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;
  final VoidCallback? onOpenHistory;

  const DocumentListCard({
    super.key,
    required this.document,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
    this.onOpenHistory,
  });

  @override
  ConsumerState<DocumentListCard> createState() => _DocumentListCardState();
}

class _DocumentListCardState extends ConsumerState<DocumentListCard> {
  bool _titleCopied = false;

  Future<void> _copyTitle() async {
    final title = widget.document.title ?? 'Без названия';
    await Clipboard.setData(ClipboardData(text: title));
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Название документа скопировано');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });
    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.document.id);
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final title = document.title ?? 'Без названия';
    final typeLabel = document.documentType ?? 'Документ';

    return ExpandableListCard(
      title: title,
      subtitle: typeLabel,
      trailingSubtitle: '${document.pageCount} стр.',
      icon: Icons.description,
      category: document.category,
      description: document.description,
      tags: document.tags,
      usedCount: document.usedCount,
      modifiedAt: document.modifiedAt,
      isFavorite: document.isFavorite,
      isPinned: document.isPinned,
      isArchived: document.isArchived,
      isDeleted: document.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        if (widget.onDecrypt != null)
          CardActionItem(
            label: 'Расшифровать',
            onPressed: widget.onDecrypt!,
            icon: Icons.lock_open,
          ),
        CardActionItem(
          label: 'Название',
          onPressed: _copyTitle,
          icon: Icons.title,
          successIcon: Icons.check,
          isSuccess: _titleCopied,
        ),
      ],
    );
  }
}
