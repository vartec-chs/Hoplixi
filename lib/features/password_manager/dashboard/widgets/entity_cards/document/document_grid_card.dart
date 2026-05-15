import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import '../shared/shared.dart';
import 'package:hoplixi/main_db/core/models/dto/document_dto.dart';

class DocumentGridCard extends ConsumerStatefulWidget {
  final DocumentCardDto document;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDecrypt;
  final VoidCallback? onOpenView;

  const DocumentGridCard({
    super.key,
    required this.document,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onDecrypt,
    this.onOpenView,
  });

  @override
  ConsumerState<DocumentGridCard> createState() => _DocumentGridCardState();
}

class _DocumentGridCardState extends ConsumerState<DocumentGridCard> {
  bool _titleCopied = false;

  Future<void> _copyTitle() async {
    final title = widget.document.item.name;
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.document.item.itemId,
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
    final title = document.item.name;
    final typeLabel = document.document.documentType?.name ?? 'Документ';

    return BaseGridCard(
      title: title,
      subtitle: '$typeLabel • ${document.document.pageCount ?? 0} стр.',
      fallbackIcon: Icons.description,
      category: null, // TODO: Map new category structure if needed
      tags: null, // TODO: Map new tags structure
      usedCount: 0, 
      isFavorite: document.item.isFavorite,
      isPinned: document.item.isPinned,
      isArchived: document.item.isArchived,
      isDeleted: document.item.isDeleted,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
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
