import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/db_core/old/models/dto/document_dto.dart';
import 'package:hoplixi/db_core/old/provider/dao_providers.dart';

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
  final VoidCallback? onOpenView;

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
    this.onOpenView,
  });

  @override
  ConsumerState<DocumentListCard> createState() => _DocumentListCardState();
}

class _DocumentListCardState extends ConsumerState<DocumentListCard> {
  bool _titleCopied = false;

  Future<void> _copyTitle() async {
    final title = widget.document.title ?? 'Без названия';
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.document.id,
      text: title,
    );
    if (!copied) return;
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Название документа скопировано');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });
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
      fallbackIcon: Icons.description,
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
      onOpenView: widget.onOpenView,
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
