import 'package:flutter/material.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';

enum EntityType {
  password('passwords', 'Пароли', Icons.lock),
  note('notes', 'Заметки', Icons.note),
  bankCard('bank_cards', 'Банковские карты', Icons.credit_card),
  file('files', 'Файлы', Icons.attach_file),
  otp('otps', 'OTP/2FA', Icons.security),
  document('documents', 'Документы', Icons.description),
  contact('contacts', 'Контакты', Icons.contact_phone),
  apiKey('api_keys', 'API-ключи', Icons.vpn_key),
  sshKey('ssh_keys', 'SSH-ключи', Icons.key),
  certificate('certificates', 'Сертификаты', Icons.verified_user),
  cryptoWallet(
    'crypto_wallets',
    'Криптокошельки',
    Icons.account_balance_wallet,
  ),
  wifi('wifi', 'Wi-Fi', Icons.wifi),
  identity('identities', 'Идентификация', Icons.badge),
  licenseKey('license_keys', 'Лицензии', Icons.confirmation_number),
  recoveryCodes('recovery_codes', 'Коды восстановления', Icons.password),
  loyaltyCard('loyalty_cards', 'Карты лояльности', Icons.card_membership);

  const EntityType(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static const List<EntityType> allTypes = EntityType.values;

  /// allTypesString
  static final List<String> allTypesString = EntityType.values
      .map((e) => e.id)
      .toList();

  /// Получить тип по идентификатору
  static EntityType? fromId(String id) {
    try {
      return EntityType.values.firstWhere((type) => type.id == id);
    } catch (e) {
      logError('Неизвестный тип сущности', error: e, data: {'id': id});
      return null;
    }
  }

  /// Получить тип по индексу
  static EntityType? fromIndex(int index) {
    try {
      return EntityType.values[index];
    } catch (e) {
      logError(
        'Неизвестный индекс типа сущности',
        error: e,
        data: {'index': index},
      );
      return null;
    }
  }

  @override
  String toString() => 'EntityType(id: $id, label: $label, icon: $icon)';
}

extension EntityTypeX on EntityType {
  /// Конвертирует EntityType в соответствующий TagType для фильтров
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

  /// Конвертирует EntityType в соответствующий CategoryType для фильтров
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
}

extension VaultItemTypeUiX on VaultItemType {
  EntityType toEntityType() {
    switch (this) {
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
