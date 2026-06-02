import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/dashboard_card_compat.dart';

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
import 'loyalty_card/loyalty_card_grid_card.dart';
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

typedef DashboardCardCallback = void Function(BaseCardDto item);
typedef DashboardSelectionCallback = void Function(String id);

final class DashboardEntityCardActions {
  const DashboardEntityCardActions({
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

  final DashboardCardCallback onOpen;
  final DashboardCardCallback onOpenEdit;
  final DashboardSelectionCallback onToggleSelection;
  final DashboardSelectionCallback onStartSelection;
  final DashboardCardCallback onToggleFavorite;
  final DashboardCardCallback onTogglePinned;
  final DashboardCardCallback onToggleArchived;
  final DashboardCardCallback onDelete;
  final DashboardCardCallback onRestore;
  final DashboardCardCallback onOpenView;
  final DashboardCardCallback onOpenHistory;
}

final class DashboardEntityCardBuilder {
  const DashboardEntityCardBuilder._();

  static Widget build({
    required BaseCardDto item,
    required DashboardViewMode viewMode,
    required Set<String> selectedIds,
    required DashboardEntityCardActions actions,
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
    required DashboardEntityCardActions actions,
  }) {
    return switch (item) {
      PasswordCardEntry(:final data) => PasswordListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      NoteCardEntry(:final data) => NoteListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      BankCardEntry(:final data) => BankCardListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      FileCardEntry(:final data) => FileListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      OtpCardEntry(:final data) => TotpListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      DocumentCardEntry(:final data) => DocumentListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      ContactCardEntry(:final data) => ContactListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      ApiKeyCardEntry(:final data) => ApiKeyListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      SshKeyCardEntry(:final data) => SshKeyListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      CertificateCardEntry(:final data) => CertificateListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      CryptoWalletCardEntry(:final data) => CryptoWalletListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      WifiCardEntry(:final data) => WifiListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      IdentityCardEntry(:final data) => IdentityListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      LicenseKeyCardEntry(:final data) => LicenseKeyListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      RecoveryCodesCardEntry(:final data) => RecoveryCodesListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      LoyaltyCardEntry(:final data) => LoyaltyCardListCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
        onOpenHistory: () => actions.onOpenHistory(item),
      ),
      _ => throw UnimplementedError('Unknown card entry: ${item.runtimeType}'),
    };
  }

  static Widget buildGrid({
    required BaseCardDto item,
    required DashboardEntityCardActions actions,
  }) {
    return switch (item) {
      PasswordCardEntry(:final data) => PasswordGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      NoteCardEntry(:final data) => NoteGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      BankCardEntry(:final data) => BankCardGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      FileCardEntry(:final data) => FileGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      OtpCardEntry(:final data) => TotpGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      DocumentCardEntry(:final data) => DocumentGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      ContactCardEntry(:final data) => ContactGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      ApiKeyCardEntry(:final data) => ApiKeyGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      SshKeyCardEntry(:final data) => SshKeyGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      CertificateCardEntry(:final data) => CertificateGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      CryptoWalletCardEntry(:final data) => CryptoWalletGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      WifiCardEntry(:final data) => WifiGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      IdentityCardEntry(:final data) => IdentityGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      LicenseKeyCardEntry(:final data) => LicenseKeyGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      RecoveryCodesCardEntry(:final data) => RecoveryCodesGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      LoyaltyCardEntry(:final data) => LoyaltyCardGridCard(
        data: data,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onRestore: () => actions.onRestore(item),
        onOpenView: () => actions.onOpenView(item),
      ),
      _ => throw UnimplementedError('Unknown card entry: ${item.runtimeType}'),
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
  final DashboardEntityCardActions actions;
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
