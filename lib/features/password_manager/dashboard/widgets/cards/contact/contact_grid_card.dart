import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';
import 'package:hoplixi/routing/paths.dart';

class ContactGridCard extends StatelessWidget {
  final ContactCardDto contact;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const ContactGridCard({
    super.key,
    required this.contact,
    this.onTap,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  Future<void> _copyPhone() async {
    if (contact.phone == null || contact.phone!.isEmpty) {
      Toaster.warning(title: 'Телефон не указан');
      return;
    }
    await Clipboard.setData(ClipboardData(text: contact.phone!));
    Toaster.success(title: 'Телефон скопирован');
  }

  Future<void> _copyEmail() async {
    if (contact.email == null || contact.email!.isEmpty) {
      Toaster.warning(title: 'Email не указан');
      return;
    }
    await Clipboard.setData(ClipboardData(text: contact.email!));
    Toaster.success(title: 'Email скопирован');
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (contact.isEmergencyContact == true) 'Экстренный',
      if (contact.company?.isNotEmpty == true) contact.company!,
      if (contact.phone?.isNotEmpty == true) contact.phone!,
      if (contact.email?.isNotEmpty == true) contact.email!,
    ];

    return BaseGridCard(
      title: contact.name,
      subtitle: subtitleParts.join(' • '),
      icon: Icons.contact_phone,
      category: contact.category,
      tags: contact.tags,
      usedCount: contact.usedCount,
      isFavorite: contact.isFavorite,
      isPinned: contact.isPinned,
      isArchived: contact.isArchived,
      isDeleted: contact.isDeleted,
      onTap: onTap,
      onToggleFavorite: onToggleFavorite,
      onTogglePin: onTogglePin,
      onToggleArchive: onToggleArchive,
      onDelete: onDelete,
      onRestore: onRestore,
      onEdit: () {
        context.push(
          AppRoutesPaths.dashboardEntityEdit(EntityType.contact, contact.id),
        );
      },
      copyActions: [
        CardActionItem(
          label: 'Телефон',
          onPressed: _copyPhone,
          icon: Icons.phone,
        ),
        CardActionItem(
          label: 'Email',
          onPressed: _copyEmail,
          icon: Icons.email,
        ),
      ],
    );
  }
}
