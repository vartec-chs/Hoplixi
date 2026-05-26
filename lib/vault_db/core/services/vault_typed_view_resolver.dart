import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

class VaultTypedViewResolver {
  VaultTypedViewResolver(this.repos);

  final VaultRepositories repos;

  Future<VaultEntityViewDto?> getView({
    required String itemId,
    required VaultItemType type,
  }) async {
    final result = await switch (type) {
      VaultItemType.apiKey => repos.apiKey.getViewById(itemId),
      VaultItemType.password => repos.password.getViewById(itemId),
      VaultItemType.bankCard => repos.bankCard.getViewById(itemId),
      VaultItemType.note => repos.note.getViewById(itemId),
      VaultItemType.otp => repos.otp.getViewById(itemId),
      VaultItemType.document => repos.document.getViewById(itemId),
      VaultItemType.file => repos.file.getViewById(itemId),
      VaultItemType.contact => repos.contact.getViewById(itemId),
      VaultItemType.sshKey => repos.sshKey.getViewById(itemId),
      VaultItemType.certificate => repos.certificate.getViewById(itemId),
      VaultItemType.cryptoWallet => repos.cryptoWallet.getViewById(itemId),
      VaultItemType.wifi => repos.wifi.getViewById(itemId),
      VaultItemType.identity => repos.identity.getViewById(itemId),
      VaultItemType.licenseKey => repos.licenseKey.getViewById(itemId),
      VaultItemType.recoveryCodes => repos.recoveryCodes.getViewById(itemId),
      VaultItemType.loyaltyCard => repos.loyaltyCard.getViewById(itemId),
    };

    return result.getOrThrow().getOrNull();
  }
}
