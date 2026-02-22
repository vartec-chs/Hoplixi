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

class PasswordGridCard extends ConsumerStatefulWidget {
  final PasswordCardDto password;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const PasswordGridCard({
    super.key,
    required this.password,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  @override
  ConsumerState<PasswordGridCard> createState() => _PasswordGridCardState();
}

class _PasswordGridCardState extends ConsumerState<PasswordGridCard> {
  bool _passwordCopied = false;
  bool _loginCopied = false;

  Future<void> _copyPassword() async {
    final passwordDao = await ref.read(passwordDaoProvider.future);
    final passwordText = await passwordDao.getPasswordFieldById(
      widget.password.id,
    );

    if (passwordText == null) {
      Toaster.error(title: 'Не удалось получить пароль');
      return;
    }

    await Clipboard.setData(ClipboardData(text: passwordText));
    setState(() => _passwordCopied = true);
    Toaster.success(title: 'Пароль скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _passwordCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
  }

  Future<void> _copyLogin() async {
    final text = widget.password.email ?? widget.password.login;
    if (text == null || text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _loginCopied = true);
    Toaster.success(title: 'Логин скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loginCopied = false);
    });

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.password.id);
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
      subtitle: displayLogin ?? (hostUrl.isEmpty ? null : hostUrl),
      icon: Icons.lock,
      category: password.category,
      tags: password.tags,
      usedCount: password.usedCount,
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
        if (displayLogin != null)
          CardActionItem(
            label: 'Логин',
            onPressed: _copyLogin,
            icon: Icons.person,
            successIcon: Icons.check,
            isSuccess: _loginCopied,
          ),
      ],
    );
  }
}
