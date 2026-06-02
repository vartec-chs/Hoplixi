import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class PasswordGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<PasswordCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const PasswordGridCard({
    super.key,
    required this.data,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
    this.onOpenView,
  });

  @override
  ConsumerState<PasswordGridCard> createState() => _PasswordGridCardState();
}

class _PasswordGridCardState extends ConsumerState<PasswordGridCard> {
  bool _passwordCopied = false;
  bool _loginCopied = false;
  bool _urlCopied = false;

  String get _itemId => widget.data.card.item.itemId;

  Future<void> _copyPassword() async {
    final value = null;

    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) {
      Toaster.error(title: 'Не удалось получить пароль');
      return;
    }
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });
  }

  Future<void> _copyLogin() async {
    final text = widget.data.card.data.email ?? widget.data.card.data.login;
    if (text == null || text.isEmpty) return;
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: text);
    if (!copied) return;
    setState(() => _loginCopied = true);
    Toaster.success(title: 'Логин скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loginCopied = false);
    });
  }

  Future<void> _copyUrl() async {
    final text = widget.data.card.data.url;
    if (text == null || text.isEmpty) return;
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: text);
    if (!copied) return;
    setState(() => _urlCopied = true);
    Toaster.success(title: 'URL скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _urlCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.data.card;
    final item = card.item;
    final value = card.data;
    final displayLogin = value.email ?? value.login;
    final hostUrl = CardUtils.extractHost(value.url);
    final now = DateTime.now();
    final isExpired = value.expiresAt != null && value.expiresAt!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        value.expiresAt != null &&
        value.expiresAt!.difference(now).inDays <= 30;

    return BaseGridCard(
      title: item.name,
      subtitle: displayLogin,
      trailingSubtitle: hostUrl.isEmpty ? null : hostUrl,
      fallbackIcon: Icons.lock,
      category: widget.data.meta.category,
      description: item.description,
      tags: widget.data.meta.tags,
      modifiedAt: item.modifiedAt,
      isFavorite: item.isFavorite,
      isPinned: item.isPinned,
      isArchived: item.isArchived,
      isDeleted: item.isDeleted,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.password, _itemId),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'Пароль',
          onPressed: _copyPassword,
          icon: Icons.lock,
          successIcon: Icons.check,
          isSuccess: _passwordCopied,
        ),
        if (displayLogin != null && displayLogin.isNotEmpty)
          CardActionItem(
            label: 'Логин',
            onPressed: _copyLogin,
            icon: Icons.person,
            successIcon: Icons.check,
            isSuccess: _loginCopied,
          ),
        if ((value.url ?? '').isNotEmpty)
          CardActionItem(
            label: 'URL',
            onPressed: _copyUrl,
            icon: Icons.link,
            successIcon: Icons.check,
            isSuccess: _urlCopied,
          ),
      ],
    );
  }
}
