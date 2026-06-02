import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/otp_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:otp/otp.dart';

import '../shared/shared.dart';

class TotpGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<OtpCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const TotpGridCard({
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
  ConsumerState<TotpGridCard> createState() => _TotpGridCardState();
}

class _TotpGridCardState extends ConsumerState<TotpGridCard> {
  bool _codeCopied = false;

  String get _itemId => widget.data.card.item.itemId;

  Future<void> _copyCode() async {
    final value = null;

    if (value == null) {
      Toaster.error(title: 'Не удалось получить секрет OTP');
      return;
    }

    final otp = widget.data.card.data;
    final secretBase32 = String.fromCharCodes(value);
    final code = OTP.generateTOTPCodeString(
      secretBase32,
      DateTime.now().millisecondsSinceEpoch,
      length: otp.digits,
      interval: otp.period ?? 30,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );

    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: code);
    if (!copied) return;
    setState(() => _codeCopied = true);
    Toaster.success(title: 'Код скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final otp = widget.data.card.data;
    final title = otp.issuer ?? otp.accountName ?? 'OTP';
    final subtitle = [
      if (otp.issuer != null && otp.accountName != null) otp.accountName!,
      '${otp.digits} цифр',
      '${otp.period ?? 30}с',
    ].join(' • ');

    return BaseGridCard(
      title: title,
      subtitle: subtitle,
      fallbackIcon: Icons.vpn_key,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.otp, _itemId),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'Код',
          onPressed: _copyCode,
          icon: Icons.copy,
          successIcon: Icons.check,
          isSuccess: _codeCopied,
        ),
      ],
    );
  }
}
