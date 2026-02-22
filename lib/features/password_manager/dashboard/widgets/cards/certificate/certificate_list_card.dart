import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/main_store/provider/dao_providers.dart';

class CertificateListCard extends ConsumerStatefulWidget {
  const CertificateListCard({
    super.key,
    required this.certificate,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final CertificateCardDto certificate;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  ConsumerState<CertificateListCard> createState() =>
      _CertificateListCardState();
}

class _CertificateListCardState extends ConsumerState<CertificateListCard> {
  bool _privateKeyCopied = false;
  bool _pfxPasswordCopied = false;

  Future<void> _copyPrivateKey() async {
    final dao = await ref.read(certificateDaoProvider.future);
    final privateKey = await dao.getPrivateKeyFieldById(widget.certificate.id);

    if (privateKey != null && privateKey.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: privateKey));
      setState(() => _privateKeyCopied = true);
      Toaster.success(title: 'Приватный ключ скопирован');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _privateKeyCopied = false);
      });
    } else {
      Toaster.error(title: 'Приватный ключ не найден');
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.certificate.id);
  }

  Future<void> _copyPfxPassword() async {
    final dao = await ref.read(certificateDaoProvider.future);
    final pfxPassword = await dao.getPasswordForPfxFieldById(
      widget.certificate.id,
    );

    if (pfxPassword != null && pfxPassword.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: pfxPassword));
      setState(() => _pfxPasswordCopied = true);
      Toaster.success(title: 'Пароль PFX скопирован');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _pfxPasswordCopied = false);
      });
    } else {
      Toaster.error(title: 'Пароль PFX не найден');
    }

    final vaultItemDao = await ref.read(vaultItemDaoProvider.future);
    await vaultItemDao.incrementUsage(widget.certificate.id);
  }

  List<CardActionItem> _buildCopyActions() {
    final actions = <CardActionItem>[];
    if (widget.certificate.hasPrivateKey) {
      actions.add(
        CardActionItem(
          label: 'PrivKey',
          onPressed: _copyPrivateKey,
          icon: Icons.vpn_key,
          successIcon: Icons.check,
          isSuccess: _privateKeyCopied,
        ),
      );
    }
    if (widget.certificate.hasPfx) {
      actions.add(
        CardActionItem(
          label: 'PFX pass',
          onPressed: _copyPfxPassword,
          icon: Icons.password,
          successIcon: Icons.check,
          isSuccess: _pfxPasswordCopied,
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final certificate = widget.certificate;
    final now = DateTime.now();
    final isExpired =
        certificate.validTo != null && certificate.validTo!.isBefore(now);
    final isExpiringSoon =
        !isExpired &&
        certificate.validTo != null &&
        certificate.validTo!.difference(now).inDays <= 30;

    final subtitleParts = [
      if (certificate.issuer?.isNotEmpty == true) certificate.issuer!,
      if (certificate.subject?.isNotEmpty == true) certificate.subject!,
    ];

    return ExpandableListCard(
      title: certificate.name,
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
      trailingSubtitle: certificate.fingerprint,
      icon: Icons.verified,
      category: certificate.category,
      description: certificate.description,
      tags: certificate.tags,
      usedCount: certificate.usedCount,
      modifiedAt: certificate.modifiedAt,
      isFavorite: certificate.isFavorite,
      isPinned: certificate.isPinned,
      isArchived: certificate.isArchived,
      isDeleted: certificate.isDeleted,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin,
      onToggleArchive: widget.onToggleArchive,
      onDelete: widget.onDelete,
      onRestore: widget.onRestore,
      onOpenHistory: widget.onOpenHistory,
      copyActions: _buildCopyActions(),
    );
  }
}
