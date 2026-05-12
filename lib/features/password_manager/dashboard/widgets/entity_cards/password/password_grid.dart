import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';

import '../shared/shared.dart';

class PasswordGridCard extends ConsumerStatefulWidget {
  final PasswordCardDto password;
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
    required this.password,
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

  Future<void> _copyPassword() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final passwordText = await passwordDao.getPasswordFieldById(
      widget.password.id,
    );

    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.password.id,
      text: passwordText,
    );
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
    final text = widget.password.email ?? widget.password.login;
    if (text == null || text.isEmpty) return;
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.password.id,
      text: text,
    );
    if (!copied) return;
    setState(() => _loginCopied = true);
    Toaster.success(title: 'Логин скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loginCopied = false);
    });
  }

  Future<void> _copyUrl() async {
    final text = widget.password.url;
    if (text == null || text.isEmpty) return;
    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.password.id,
      text: text,
    );
    if (!copied) return;
    setState(() => _urlCopied = true);
    Toaster.success(title: 'URL скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _urlCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final password = widget.password;
    final displayLogin = password.email ?? password.login;
    final hostUrl = CardUtils.extractHost(password.url);
    final now = DateTime.now();
    final isExpired =
        password.expireAt != null && password.expireAt!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        password.expireAt != null &&
        password.expireAt!.difference(now).inDays <= 30;

    return BaseGridCard(
      title: password.name,
      subtitle: displayLogin,
      trailingSubtitle: hostUrl.isEmpty ? null : hostUrl,
      fallbackIcon: Icons.lock,
      iconSource: password.iconSource,
      iconValue: password.iconValue,
      category: password.category,
      description: password.description,
      tags: password.tags,
      usedCount: password.usedCount,
      modifiedAt: password.modifiedAt,
      isFavorite: password.isFavorite,
      isPinned: password.isPinned,
      isArchived: password.isArchived,
      isDeleted: password.isDeleted,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.password, password.id),
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
        if ((password.url ?? '').isNotEmpty)
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
