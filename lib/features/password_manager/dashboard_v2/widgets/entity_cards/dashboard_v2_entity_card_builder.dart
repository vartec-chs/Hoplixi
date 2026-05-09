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
    required this.onToggleSelection,
    required this.onStartSelection,
    required this.onToggleFavorite,
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onDelete,
  });

  final DashboardV2CardCallback onOpen;
  final DashboardV2SelectionCallback onToggleSelection;
  final DashboardV2SelectionCallback onStartSelection;
  final DashboardV2CardCallback onToggleFavorite;
  final DashboardV2CardCallback onTogglePinned;
  final DashboardV2CardCallback onToggleArchived;
  final DashboardV2CardCallback onDelete;
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
        onOpenView: () => actions.onOpen(item),
      ),
      NoteCardDto() => NoteListCard(
        note: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      BankCardCardDto() => BankCardListCard(
        bankCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      FileCardDto() => FileListCard(
        file: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      OtpCardDto() => TotpListCard(
        otp: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      DocumentCardDto() => DocumentListCard(
        document: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      ContactCardDto() => ContactListCard(
        contact: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      ApiKeyCardDto() => ApiKeyListCard(
        apiKey: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      SshKeyCardDto() => SshKeyListCard(
        sshKey: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      CertificateCardDto() => CertificateListCard(
        certificate: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      CryptoWalletCardDto() => CryptoWalletListCard(
        wallet: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      WifiCardDto() => WifiListCard(
        wifi: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      IdentityCardDto() => IdentityListCard(
        identity: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      LicenseKeyCardDto() => LicenseKeyListCard(
        license: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      RecoveryCodesCardDto() => RecoveryCodesListCard(
        recoveryCodes: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      LoyaltyCardCardDto() => LoyaltyCardListCard(
        loyaltyCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
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
        onOpenView: () => actions.onOpen(item),
      ),
      NoteCardDto() => NoteGridCard(
        note: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      BankCardCardDto() => BankCardGridCard(
        bankCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      FileCardDto() => FileGridCard(
        file: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      OtpCardDto() => TotpGridCard(
        otp: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      DocumentCardDto() => DocumentGridCard(
        document: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      ContactCardDto() => ContactGridCard(
        contact: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      ApiKeyCardDto() => ApiKeyGridCard(
        apiKey: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      SshKeyCardDto() => SshKeyGridCard(
        sshKey: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      CertificateCardDto() => CertificateGridCard(
        certificate: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      CryptoWalletCardDto() => CryptoWalletGridCard(
        wallet: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      WifiCardDto() => WifiGridCard(
        wifi: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      IdentityCardDto() => IdentityGridCard(
        identity: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      LicenseKeyCardDto() => LicenseKeyGridCard(
        license: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      RecoveryCodesCardDto() => RecoveryCodesGridCard(
        recoveryCodes: item,
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
      ),
      LoyaltyCardCardDto() => LoyaltyCardGridCard(
        loyaltyCard: item,
        onTap: () => actions.onOpen(item),
        onToggleFavorite: () => actions.onToggleFavorite(item),
        onTogglePin: () => actions.onTogglePinned(item),
        onToggleArchive: () => actions.onToggleArchived(item),
        onDelete: () => actions.onDelete(item),
        onOpenView: () => actions.onOpen(item),
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

    return GestureDetector(
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
          borderRadius: BorderRadius.circular(10),
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
