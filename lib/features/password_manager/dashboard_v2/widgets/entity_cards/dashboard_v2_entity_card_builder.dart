import 'package:flutter/material.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';

import '../../models/dashboard_view_mode.dart';
import 'api_key/api_key_grid_card.dart';
import 'api_key/api_key_list_card.dart';
import 'bank_card/bank_card_grid.dart';
import 'bank_card/bank_card_list_card.dart';
import 'certificate/certificate_grid_card.dart';
import 'certificate/certificate_list_card.dart';
import 'contact/contact_grid_card.dart';
import 'contact/contact_list_card.dart';
import 'crypto_wallet/crypto_wallet_grid_card.dart';
import 'crypto_wallet/crypto_wallet_list_card.dart';
import 'document/document_grid_card.dart';
import 'document/document_list_card.dart';
import 'file/file_grid_card.dart';
import 'file/file_list_card.dart';
import 'identity/identity_grid_card.dart';
import 'identity/identity_list_card.dart';
import 'license_key/license_key_grid_card.dart';
import 'license_key/license_key_list_card.dart';
import 'loyalty_card/loyalty_card_grid.dart';
import 'loyalty_card/loyalty_card_list_card.dart';
import 'note/note_grid.dart';
import 'note/note_list_card.dart';
import 'otp/otp_grid.dart';
import 'otp/otp_list_card.dart';
import 'password/password_grid.dart';
import 'password/password_list_card.dart';
import 'recovery_codes/recovery_codes_grid_card.dart';
import 'recovery_codes/recovery_codes_list_card.dart';
import 'ssh_key/ssh_key_grid_card.dart';
import 'ssh_key/ssh_key_list_card.dart';
import 'wifi/wifi_grid_card.dart';
import 'wifi/wifi_list_card.dart';

typedef DashboardV2CardCallback = void Function(BaseCardDto item);
typedef DashboardV2SelectionCallback = void Function(String id);

final class DashboardV2EntityCardActions {
  const DashboardV2EntityCardActions({
    required this.onOpen,
    required this.onOpenEdit,
    required this.onToggleSelection,
    required this.onStartSelection,
    required this.onToggleFavorite,
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onDelete,
    required this.onRestore,
    required this.onOpenView,
    required this.onOpenHistory,
  });

  final DashboardV2CardCallback onOpen;
  final DashboardV2CardCallback onOpenEdit;
  final DashboardV2SelectionCallback onToggleSelection;
  final DashboardV2SelectionCallback onStartSelection;
  final DashboardV2CardCallback onToggleFavorite;
  final DashboardV2CardCallback onTogglePinned;
  final DashboardV2CardCallback onToggleArchived;
  final DashboardV2CardCallback onDelete;
  final DashboardV2CardCallback onRestore;
  final DashboardV2CardCallback onOpenView;
  final DashboardV2CardCallback onOpenHistory;
}

final class DashboardV2EntityCardBuilder {
  const DashboardV2EntityCardBuilder._();

  static Widget build({
    required BaseCardDto item,
    required DashboardViewMode viewMode,
    required Set<String> selectedIds,
    required DashboardV2EntityCardActions actions,
  }) {
    final card = viewMode.isGrid
        ? buildGrid(item: item, actions: actions)
        : buildList(item: item, actions: actions);

    return _SelectableEntityCard(
      key: ValueKey(item.id),
      item: item,
      isSelected: selectedIds.contains(item.id),
      isSelecting: selectedIds.isNotEmpty,
      actions: actions,
      child: card,
    );
  }

  static Widget buildList({
    required BaseCardDto item,
    required DashboardV2EntityCardActions actions,
  }) {
    return switch (item) {
      PasswordCardDto() => PasswordListCard(
        password: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      NoteCardDto() => NoteListCard(
        note: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      BankCardCardDto() => BankCardListCard(
        bankCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      FileCardDto() => FileListCard(
        file: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      OtpCardDto() => TotpListCard(
        otp: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      DocumentCardDto() => DocumentListCard(
        document: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      ContactCardDto() => ContactListCard(
        contact: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      ApiKeyCardDto() => ApiKeyListCard(
        apiKey: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      SshKeyCardDto() => SshKeyListCard(
        sshKey: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      CertificateCardDto() => CertificateListCard(
        certificate: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      CryptoWalletCardDto() => CryptoWalletListCard(
        wallet: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      WifiCardDto() => WifiListCard(
        wifi: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      IdentityCardDto() => IdentityListCard(
        identity: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      LicenseKeyCardDto() => LicenseKeyListCard(
        license: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      RecoveryCodesCardDto() => RecoveryCodesListCard(
        recoveryCodes: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      LoyaltyCardCardDto() => LoyaltyCardListCard(
        loyaltyCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      _ => _UnsupportedEntityCard(item: item),
    };
  }

  static Widget buildGrid({
    required BaseCardDto item,
    required DashboardV2EntityCardActions actions,
  }) {
    return switch (item) {
      PasswordCardDto() => PasswordGridCard(
        password: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      NoteCardDto() => NoteGridCard(
        note: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      BankCardCardDto() => BankCardGridCard(
        bankCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      FileCardDto() => FileGridCard(
        file: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      OtpCardDto() => TotpGridCard(
        otp: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      DocumentCardDto() => DocumentGridCard(
        document: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      ContactCardDto() => ContactGridCard(
        contact: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      ApiKeyCardDto() => ApiKeyGridCard(
        apiKey: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      SshKeyCardDto() => SshKeyGridCard(
        sshKey: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      CertificateCardDto() => CertificateGridCard(
        certificate: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      CryptoWalletCardDto() => CryptoWalletGridCard(
        wallet: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      WifiCardDto() => WifiGridCard(
        wifi: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      IdentityCardDto() => IdentityGridCard(
        identity: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      LicenseKeyCardDto() => LicenseKeyGridCard(
        license: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      RecoveryCodesCardDto() => RecoveryCodesGridCard(
        recoveryCodes: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      LoyaltyCardCardDto() => LoyaltyCardGridCard(
        loyaltyCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      _ => _UnsupportedEntityCard(item: item),
    };
  }
}

final class _SelectableEntityCard extends StatelessWidget {
  const _SelectableEntityCard({
    required this.item,
    required this.isSelected,
    required this.isSelecting,
    required this.actions,
    required this.child,
    super.key,
  });

  final BaseCardDto item;
  final bool isSelected;
  final bool isSelecting;
  final DashboardV2EntityCardActions actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final archiveOrRestoreIcon = item.isDeleted
        ? Icons.restore_from_trash
        : item.isArchived
        ? Icons.unarchive
        : Icons.edit;
    final archiveOrRestoreLabel = item.isDeleted
        ? 'Восстановить'
        : item.isArchived
        ? 'Вернуть из архива'
        : 'Редактировать';

    final decoratedChild = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => isSelecting
          ? actions.onToggleSelection(item.id)
          : actions.onOpen(item),
      onLongPress: () => actions.onStartSelection(item.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            child,
            if (isSelected)
              Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: colors.onPrimary, size: 18),
                ),
              ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('dashboard-v2-swipe-${item.id}'),
      direction: isSelecting
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: item.isDeleted
            ? colors.tertiaryContainer
            : item.isArchived
            ? colors.secondaryContainer
            : colors.primaryContainer,
        foregroundColor: item.isDeleted
            ? colors.onTertiaryContainer
            : item.isArchived
            ? colors.onSecondaryContainer
            : colors.onPrimaryContainer,
        icon: archiveOrRestoreIcon,
        label: archiveOrRestoreLabel,
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: colors.errorContainer,
        foregroundColor: colors.onErrorContainer,
        icon: item.isDeleted ? Icons.delete_forever : Icons.delete,
        label: item.isDeleted ? 'Удалить навсегда' : 'Удалить',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (item.isDeleted) {
            actions.onRestore(item);
          } else if (item.isArchived) {
            actions.onToggleArchived(item);
          } else {
            actions.onOpenEdit(item);
          }
        } else if (direction == DismissDirection.endToStart) {
          actions.onDelete(item);
        }
        return false;
      },
      child: decoratedChild,
    );
  }
}

final class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.foregroundColor,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final Color foregroundColor;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: isLeft ? TextDirection.ltr : TextDirection.rtl,
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foregroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _UnsupportedEntityCard extends StatelessWidget {
  const _UnsupportedEntityCard({required this.item});

  final BaseCardDto item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.id),
      subtitle: const Text('Неподдерживаемый тип элемента'),
    );
  }
}
