import 'package:flutter/widgets.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
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

  CategoryType toCategoryType() {
    switch (this) {
      case EntityType.password:
        return CategoryType.password;
      case EntityType.note:
        return CategoryType.note;
      case EntityType.bankCard:
        return CategoryType.bankCard;
      case EntityType.file:
        return CategoryType.file;
      case EntityType.otp:
        return CategoryType.totp;
      case EntityType.document:
        return CategoryType.document;
      case EntityType.contact:
        return CategoryType.contact;
      case EntityType.apiKey:
        return CategoryType.apiKey;
      case EntityType.sshKey:
        return CategoryType.sshKey;
      case EntityType.certificate:
        return CategoryType.certificate;
      case EntityType.cryptoWallet:
        return CategoryType.cryptoWallet;
      case EntityType.wifi:
        return CategoryType.wifi;
      case EntityType.identity:
        return CategoryType.identity;
      case EntityType.licenseKey:
        return CategoryType.licenseKey;
      case EntityType.recoveryCodes:
        return CategoryType.recoveryCodes;
      case EntityType.loyaltyCard:
        return CategoryType.loyaltyCard;
    }
  }

  TagType toTagType() {
    switch (this) {
      case EntityType.password:
        return TagType.password;
      case EntityType.note:
        return TagType.note;
      case EntityType.bankCard:
        return TagType.bankCard;
      case EntityType.file:
        return TagType.file;
      case EntityType.otp:
        return TagType.totp;
      case EntityType.document:
        return TagType.document;
      case EntityType.contact:
        return TagType.contact;
      case EntityType.apiKey:
        return TagType.apiKey;
      case EntityType.sshKey:
        return TagType.sshKey;
      case EntityType.certificate:
        return TagType.certificate;
      case EntityType.cryptoWallet:
        return TagType.cryptoWallet;
      case EntityType.wifi:
        return TagType.wifi;
      case EntityType.identity:
        return TagType.identity;
      case EntityType.licenseKey:
        return TagType.licenseKey;
      case EntityType.recoveryCodes:
        return TagType.recoveryCodes;
      case EntityType.loyaltyCard:
        return TagType.loyaltyCard;
    }
  }
}

extension VaultItemTypeX on VaultItemType {
  EntityType toEntityType() => EntityType.fromVaultItemType(this);
}
