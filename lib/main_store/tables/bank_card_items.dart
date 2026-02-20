import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';

import 'vault_items.dart';

/// Type-specific таблица для банковских карт.
///
/// Содержит ТОЛЬКО поля, специфичные для банковской карты.
/// Общие поля (name, categoryId, isFavorite и т.д.)
/// хранятся в vault_items.
@DataClassName('BankCardItemsData')
class BankCardItems extends Table {
  /// PK и FK → vault_items.id ON DELETE CASCADE
  TextColumn get itemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  /// Имя владельца карты
  TextColumn get cardholderName => text().withLength(min: 1, max: 255)();

  /// Зашифрованный номер карты
  TextColumn get cardNumber => text()();

  /// Тип карты (дебитовая, кредитная и т.д.)
  TextColumn get cardType => textEnum<CardType>()
      .withDefault(Constant(CardType.debit.value))
      .nullable()();

  /// Платёжная сеть (Visa, Mastercard и т.д.)
  TextColumn get cardNetwork => textEnum<CardNetwork>()
      .withDefault(Constant(CardNetwork.other.value))
      .nullable()();

  /// Месяц истечения (MM)
  TextColumn get expiryMonth => text().withLength(min: 2, max: 2)();

  /// Год истечения (YYYY)
  TextColumn get expiryYear => text().withLength(min: 4, max: 4)();

  /// Зашифрованный CVV
  TextColumn get cvv => text().nullable()();

  /// Название банка
  TextColumn get bankName => text().nullable()();

  /// Номер счёта
  TextColumn get accountNumber => text().nullable()();

  /// Маршрутный номер
  TextColumn get routingNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};

  @override
  String get tableName => 'bank_card_items';
}
