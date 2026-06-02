import 'package:flutter/widgets.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum EntityType {
  password('passwords', 'Пароли', LucideIcons.lock),
  note('notes', 'Заметки', LucideIcons.stickyNote),
  bankCard('bank_cards', 'Банковские карты', LucideIcons.creditCard),
  file('files', 'Файлы', LucideIcons.file),
  otp('otps', 'OTP/2FA', LucideIcons.shieldCheck),
  document('documents', 'Документы', LucideIcons.fileText),
  contact('contacts', 'Контакты', LucideIcons.idCard),
  apiKey('api_keys', 'API-ключи', LucideIcons.key),
  sshKey('ssh_keys', 'SSH-ключи', LucideIcons.keyRound),
  certificate('certificates', 'Сертификаты', LucideIcons.shieldCheck),
  cryptoWallet('crypto_wallets', 'Криптокошельки', LucideIcons.wallet),
  wifi('wifi', 'Wi-Fi', LucideIcons.wifi),
  identity('identities', 'Идентификация', LucideIcons.idCard),
  licenseKey('license_keys', 'Лицензии', LucideIcons.key),
  recoveryCodes('recovery_codes', 'Коды восстановления', LucideIcons.key),
  loyaltyCard('loyalty_cards', 'Карты лояльности', LucideIcons.creditCard);

  const EntityType(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static EntityType? fromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }

  static EntityType fromVaultItemType(VaultItemType vaultItemType) {
    switch (vaultItemType) {
      case VaultItemType.password:
        return EntityType.password;
      case VaultItemType.otp:
        return EntityType.otp;
      case VaultItemType.note:
        return EntityType.note;
      case VaultItemType.bankCard:
        return EntityType.bankCard;
      case VaultItemType.document:
        return EntityType.document;
      case VaultItemType.file:
        return EntityType.file;
      case VaultItemType.contact:
        return EntityType.contact;
      case VaultItemType.apiKey:
        return EntityType.apiKey;
      case VaultItemType.sshKey:
        return EntityType.sshKey;
      case VaultItemType.certificate:
        return EntityType.certificate;
      case VaultItemType.cryptoWallet:
        return EntityType.cryptoWallet;
      case VaultItemType.wifi:
        return EntityType.wifi;
      case VaultItemType.identity:
        return EntityType.identity;
      case VaultItemType.licenseKey:
        return EntityType.licenseKey;
      case VaultItemType.recoveryCodes:
        return EntityType.recoveryCodes;
      case VaultItemType.loyaltyCard:
        return EntityType.loyaltyCard;
    }
  }

}

extension VaultItemTypeX on VaultItemType {
  EntityType toEntityType() => EntityType.fromVaultItemType(this);
}
