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

class NoteListCard extends ConsumerStatefulWidget {
  final NoteCardDto note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const NoteListCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  @override
  ConsumerState<NoteListCard> createState() => _NoteListCardState();
}

class _NoteListCardState extends ConsumerState<NoteListCard> {
  bool _titleCopied = false;

  Future<void> _copyTitle() async {
    await Clipboard.setData(ClipboardData(text: widget.note.title));
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Заголовок скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.note.id);
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return ExpandableListCard(
      title: note.title,
      subtitle: note.description,
      icon: Icons.note,
      category: note.category,
      description: note.description,
      tags: note.tags,
      usedCount: note.usedCount,
      modifiedAt: note.modifiedAt,
      isFavorite: note.isFavorite,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isDeleted: note.isDeleted,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: [
        CardActionItem(
          label: 'Заголовок',
          onPressed: _copyTitle,
          icon: Icons.title,
          successIcon: Icons.check,
          isSuccess: _titleCopied,
        ),
        CardActionItem(
          label: 'Открыть',
          onPressed: () {
            context.push(
              AppRoutesPaths.dashboardEntityEdit(EntityType.note, note.id),
            );
          },
          icon: Icons.open_in_new,
        ),
      ],
    );
  }
}
