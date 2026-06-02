import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/document_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class DocumentListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<DocumentCardDto> data;
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
    required this.data,
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

  String get _itemId => widget.data.card.item.itemId;
  String get _title => widget.data.card.item.name;

  Future<void> _copyTitle() async {
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: _title);
    if (!copied) return;
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Название документа скопировано');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final document = widget.data.card.data;
    final typeLabel = document.documentType?.name ?? 'Документ';
    final pageCount = document.pageCount ?? 0;

    return ExpandableListCard(
      title: item.name,
      subtitle: typeLabel,
      trailingSubtitle: '$pageCount стр.',
      fallbackIcon: Icons.description,
      category: widget.data.meta.category,
      description: item.description,
      tags: widget.data.meta.tags,
      modifiedAt: item.modifiedAt,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
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
