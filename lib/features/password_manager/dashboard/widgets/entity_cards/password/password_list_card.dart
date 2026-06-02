import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/vault_db/core/models/dto/password_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class PasswordListCard extends ConsumerStatefulWidget {
  final FilteredCardDto<PasswordCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenView;

  const PasswordListCard({
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
  ConsumerState<PasswordListCard> createState() => _PasswordListCardState();
}

class _PasswordListCardState extends ConsumerState<PasswordListCard> {
  bool _passwordCopied = false;
  bool _loginCopied = false;
  bool _urlCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  PasswordCardDataDto get _password => widget.data.card.data;

  Future<void> _copyPassword() async {
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: null);
    if (!copied) {
      Toaster.warning(title: 'Пароль недоступен');
      return;
    }
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });
  }

  Future<void> _copyLogin() async {
    final text = _password.email ?? _password.login;
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
    final text = _password.url;
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
    final item = widget.data.card.item;
    final displayLogin = _password.email ?? _password.login;
    final hostUrl = CardUtils.extractHost(_password.url);
    final now = DateTime.now();
    final isExpired =
        _password.expiresAt != null && _password.expiresAt!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        _password.expiresAt != null &&
        _password.expiresAt!.difference(now).inDays <= 30;

    return ExpandableListCard(
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
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onOpenHistory: widget.onOpenHistory,
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
        if ((_password.url ?? '').isNotEmpty)
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
