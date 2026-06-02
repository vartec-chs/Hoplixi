import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/vault_db/core/models/dto/contact_dto.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

import '../shared/shared.dart';

class ContactGridCard extends ConsumerStatefulWidget {
  final FilteredCardDto<ContactCardDto> data;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenView;

  const ContactGridCard({
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
  ConsumerState<ContactGridCard> createState() => _ContactGridCardState();
}

class _ContactGridCardState extends ConsumerState<ContactGridCard> {
  String get _itemId => widget.data.card.item.itemId;
  ContactCardDataDto get _contact => widget.data.card.data;

  String get _displayName {
    final parts = <String>[
      _contact.firstName,
      _contact.middleName ?? '',
      _contact.lastName ?? '',
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? widget.data.card.item.name : parts.join(' ');
  }

  Future<void> _copyPhone() async {
    final phone = _contact.phone;
    if (phone == null || phone.isEmpty) {
      Toaster.warning(title: 'Телефон не указан');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: phone);
    if (!copied) return;
    Toaster.success(title: 'Телефон скопирован');
  }

  Future<void> _copyEmail() async {
    final email = _contact.email;
    if (email == null || email.isEmpty) {
      Toaster.warning(title: 'Email не указан');
      return;
    }
    final copied = await copyCardValue(ref: ref, itemId: _itemId, text: email);
    if (!copied) return;
    Toaster.success(title: 'Email скопирован');
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data.card.item;
    final subtitleParts = [
      if (_contact.isEmergencyContact) 'Экстренный',
      if ((_contact.company ?? '').isNotEmpty) _contact.company!,
      if ((_contact.phone ?? '').isNotEmpty) _contact.phone!,
      if ((_contact.email ?? '').isNotEmpty) _contact.email!,
    ];

    return BaseGridCard(
      title: _displayName,
      subtitle: subtitleParts.join(' • '),
      fallbackIcon: Icons.contact_phone,
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
          AppRoutesPaths.dashboardEntityEdit(EntityType.contact, _itemId),
        );
      },
      copyActions: [
        if ((_contact.phone ?? '').isNotEmpty)
          CardActionItem(
            label: 'Телефон',
            onPressed: _copyPhone,
            icon: Icons.phone,
          ),
        if ((_contact.email ?? '').isNotEmpty)
          CardActionItem(
            label: 'Email',
            onPressed: _copyEmail,
            icon: Icons.email,
          ),
      ],
    );
  }
}
