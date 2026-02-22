import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/shared/index.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class ContactListCard extends StatelessWidget {
  final ContactCardDto contact;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  const ContactListCard({
    super.key,
    required this.contact,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
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

    return ExpandableListCard(
      title: contact.name,
      subtitle: subtitleParts.join(' • '),
      icon: Icons.contact_phone,
      category: contact.category,
      description: contact.description,
      tags: contact.tags,
      usedCount: contact.usedCount,
      modifiedAt: contact.modifiedAt,
      isFavorite: contact.isFavorite,
      isPinned: contact.isPinned,
      isArchived: contact.isArchived,
      isDeleted: contact.isDeleted,
      onToggleFavorite: onToggleFavorite,
      onTogglePin: onTogglePin,
      onToggleArchive: onToggleArchive,
      onDelete: onDelete,
      onRestore: onRestore,
      onOpenHistory: onOpenHistory,
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
