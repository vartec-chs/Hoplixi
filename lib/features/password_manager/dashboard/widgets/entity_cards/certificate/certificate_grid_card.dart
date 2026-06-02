import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/certificate_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class CertificateGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<CertificateCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const CertificateGridCard({
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
  ConsumerState<CertificateGridCard> createState() =>
      _CertificateGridCardState();
}

class _CertificateGridCardState extends ConsumerState<CertificateGridCard> {
  bool _pemCopied = false;
  bool _serialCopied = false;

  String get _itemId => widget.data.card.item.itemId;
  CertificateCardDataDto get _cert => widget.data.card.data;

  Future<void> _copyPem() async {
    final value = null;
    if (value == null || value.isEmpty) {
      Toaster.warning(title: 'value недоступен');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: value);
    if (!copied) return;
    setState(() => _pemCopied = true);
    Toaster.success(title: 'value скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _pemCopied = false);
    });
  }

  Future<void> _copySerial() async {
    final serial = _cert.serialNumber;
    if (serial == null || serial.isEmpty) {
      Toaster.warning(title: 'Серийный номер отсутствует');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: serial);
    if (!copied) return;
    setState(() => _serialCopied = true);
    Toaster.success(title: 'Серийный номер скопирован');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _serialCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_cert.certificateFormat != null) _cert.certificateFormat!.name,
      if (_cert.keyAlgorithm != null) _cert.keyAlgorithm!.name,
      if (_cert.keySize != null) '${_cert.keySize} бит',
    ];

    return BaseGridCard(
      title: item.name,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.verified_user,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.certificate, _itemId),
        );
      },
      copyActions: [
        if ((_cert.serialNumber ?? '').isNotEmpty)
          CardActionItem(
            label: 'Серийный №',
            onPressed: _copySerial,
            icon: Icons.tag,
            successIcon: Icons.check,
            isSuccess: _serialCopied,
          ),
        if (_cert.hasCertificatePem)
          CardActionItem(
            label: 'value',
            onPressed: _copyPem,
            icon: Icons.copy,
            successIcon: Icons.check,
            isSuccess: _pemCopied,
          ),
      ],
    );
  }
}
