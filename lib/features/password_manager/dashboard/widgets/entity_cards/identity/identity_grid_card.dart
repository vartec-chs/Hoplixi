import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/identity_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class IdentityGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<IdentityCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const IdentityGridCard({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenView,
  });

  @override
  ConsumerState<IdentityGridCard> createState() => _IdentityGridCardState();
}

class _IdentityGridCardState extends ConsumerState<IdentityGridCard> {
  bool _emailCopied = false;
  bool _phoneCopied = false;
  bool _usernameCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  IdentityCardDataDto get _identity => widget.data.card.data;

  Future<void> _copyText(
    String? text,
    String label, {
    required void Function(bool) setSuccess,
  }) async {
    if (text == null || text.isEmpty) {
      Toaster.warning(title: '$label не указан');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: text);
    if (!copied) return;
    setSuccess(true);
    Toaster.success(title: '$label скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setSuccess(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final identity = _identity;
    final subtitleParts = [
      if ((identity.company ?? '').isNotEmpty) identity.company!,
      if ((identity.email ?? '').isNotEmpty) identity.email!,
      if ((identity.phone ?? '').isNotEmpty) identity.phone!,
    ];

    return BaseGridCard(
      title: identity.displayName ?? item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.person,
      category: widget.data.meta.category,
      tags: widget.data.meta.tags,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.identity, _itemId),
        );
      },
      copyActions: [
        if ((identity.username ?? '').isNotEmpty)
          CardActionItem(
            label: 'Логин',
            onPressed: () => _copyText(
              identity.username,
              'Логин',
              setSuccess: (v) => setState(() => _usernameCopied = v),
            ),
            icon: Icons.person_outline,
            successIcon: Icons.check,
            isSuccess: _usernameCopied,
          ),
        if ((identity.email ?? '').isNotEmpty)
          CardActionItem(
            label: 'Email',
            onPressed: () => _copyText(
              identity.email,
              'Email',
              setSuccess: (v) => setState(() => _emailCopied = v),
            ),
            icon: Icons.email,
            successIcon: Icons.check,
            isSuccess: _emailCopied,
          ),
        if ((identity.phone ?? '').isNotEmpty)
          CardActionItem(
            label: 'Телефон',
            onPressed: () => _copyText(
              identity.phone,
              'Телефон',
              setSuccess: (v) => setState(() => _phoneCopied = v),
            ),
            icon: Icons.phone,
            successIcon: Icons.check,
            isSuccess: _phoneCopied,
          ),
      ],
    );
  }
}
