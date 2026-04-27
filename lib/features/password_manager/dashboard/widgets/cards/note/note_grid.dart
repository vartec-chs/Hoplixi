import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:hoplixi/main_db/new/providers/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

class NoteGridCard extends ConsumerStatefulWidget {
  final NoteCardDto note;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const NoteGridCard({
    super.key,
    required this.note,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenView,
  });

  @override
  ConsumerState<NoteGridCard> createState() => _NoteGridCardState();
}

class _NoteGridCardState extends ConsumerState<NoteGridCard> {
  bool _titleCopied = false;

  Future<void> _copyTitle() async {
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.note.id,
      text: widget.note.title,
    );
    if (!copied) return;
    setState(() => _titleCopied = true);
    Toaster.success(title: 'Заголовок скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _titleCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return BaseGridCard(
      title: note.title,
      subtitle: note.description,
      fallbackIcon: Icons.note,
      iconSource: note.iconSource,
      iconValue: note.iconValue,
      category: note.category,
      tags: note.tags,
      usedCount: note.usedCount,
      isFavorite: note.isFavorite,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isDeleted: note.isDeleted,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.note, note.id),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'Заголовок',
          onPressed: _copyTitle,
          icon: Icons.title,
          successIcon: Icons.check,
          isSuccess: _titleCopied,
        ),
      ],
    );
  }
}
