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

class CertificateGridCard extends ConsumerStatefulWidget {
  const CertificateGridCard({
    super.key,
    required this.certificate,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  final CertificateCardDto certificate;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  @override
  ConsumerState<CertificateGridCard> createState() =>
      _CertificateGridCardState();
}

class _CertificateGridCardState extends ConsumerState<CertificateGridCard> {
  bool _privateKeyCopied = false;

  Future<void> _copyPrivateKey() async {
    final dao = await ref.read(certificateDaoProvider.future);
    final text = await dao.getPrivateKeyFieldById(widget.certificate.id);
    if (text != null && text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
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

    return BaseGridCard(
      title: certificate.name,
      subtitle: certificate.issuer ?? certificate.subject,
      icon: Icons.verified,
      category: certificate.category,
      tags: certificate.tags,
      usedCount: certificate.usedCount,
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
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(
            EntityType.certificate,
            certificate.id,
          ),
        );
      },
      copyActions: [
        if (certificate.hasPrivateKey)
          CardActionItem(
            label: 'PrivKey',
            onPressed: _copyPrivateKey,
            icon: Icons.vpn_key,
            successIcon: Icons.check,
            isSuccess: _privateKeyCopied,
          ),
      ],
    );
  }
}
