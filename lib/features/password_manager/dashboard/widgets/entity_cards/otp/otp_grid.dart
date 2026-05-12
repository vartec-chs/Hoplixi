import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:otp/otp.dart';

import '../shared/shared.dart';

class TotpGridCard extends ConsumerStatefulWidget {
  final OtpCardDto otp;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const TotpGridCard({
    super.key,
    required this.otp,
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

  Future<void> _copyCode() async {
    final otpDao = await ref.read(otpDaoProvider.future);
    final secretBytes = await otpDao.getOtpSecretById(widget.otp.id);

    if (secretBytes == null) {
      Toaster.error(title: 'Не удалось получить секрет OTP');
      return;
    }

    final secretBase32 = String.fromCharCodes(secretBytes);
    final code = OTP.generateTOTPCodeString(
      secretBase32,
      DateTime.now().millisecondsSinceEpoch,
      length: widget.otp.digits,
      interval: widget.otp.period,
      isGoogle: true,
      algorithm: Algorithm.SHA1,
    );

    final copied = await copyCardValue(
      ref: ref,
      itemId: widget.otp.id,
      text: code,
    );
    if (!copied) return;
    setState(() => _codeCopied = true);
    Toaster.success(title: 'Код скопирован');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.otp;
    final title = otp.issuer ?? otp.accountName ?? 'OTP';
    final subtitle = [
      if (otp.issuer != null && otp.accountName != null) otp.accountName!,
      '${otp.digits} цифр',
      '${otp.period}с',
    ].join(' • ');

    return BaseGridCard(
      title: title,
      subtitle: subtitle,
      fallbackIcon: Icons.vpn_key,
      iconSource: otp.iconSource,
      iconValue: otp.iconValue,
      category: otp.category,
      tags: otp.tags,
      usedCount: otp.usedCount,
      isFavorite: otp.isFavorite,
      isPinned: otp.isPinned,
      isArchived: otp.isArchived,
      isDeleted: otp.isDeleted,
      onTap: widget.onTap,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenView: widget.onOpenView,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.otp, otp.id),
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
