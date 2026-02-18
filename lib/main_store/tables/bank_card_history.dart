import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';

import 'vault_item_history.dart';

/// History-таблица для специфичных полей банковской карты.
@DataClassName('BankCardHistoryData')
class BankCardHistory extends Table {
  /// PK и FK → vault_item_history.id ON DELETE CASCADE
  TextColumn get historyId =>
      text().references(VaultItemHistory, #id, onDelete: KeyAction.cascade)();

  /// Имя владельца (snapshot)
  TextColumn get cardholderName => text().withLength(min: 1, max: 255)();

  /// Зашифрованный номер карты (snapshot, nullable)
  TextColumn get cardNumber => text().nullable()();

  /// Тип карты (snapshot)
  TextColumn get cardType => textEnum<CardType>().nullable()();

  /// Платёжная сеть (snapshot)
  TextColumn get cardNetwork => textEnum<CardNetwork>().nullable()();

  /// Месяц истечения (snapshot)
  TextColumn get expiryMonth => text().nullable()();

  /// Год истечения (snapshot)
  TextColumn get expiryYear => text().nullable()();

  /// CVV (snapshot, nullable для приватности)
  TextColumn get cvv => text().nullable()();

  /// Название банка (snapshot)
  TextColumn get bankName => text().nullable()();

  /// Номер счёта (snapshot)
  TextColumn get accountNumber => text().nullable()();

  /// Маршрутный номер (snapshot)
  TextColumn get routingNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {historyId};

  @override
  String get tableName => 'bank_card_history';
}
