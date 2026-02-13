import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

@DataClassName('BankCardsHistoryData')
class BankCardsHistory extends Table {
  TextColumn get id =>
      text().clientDefault(() => const Uuid().v4())(); // UUID v4
  TextColumn get originalCardId => text()(); // ID of original card
  TextColumn get action => textEnum<ActionInHistory>().withLength(
    min: 1,
    max: 50,
  )(); // 'deleted', 'modified'

  // Bank card data snapshot
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get cardholderName => text().withLength(min: 1, max: 255)();
  TextColumn get cardNumber =>
      text().nullable()(); // Encrypted card number (nullable for privacy)
  TextColumn get cardType =>
      textEnum<CardType>().nullable()(); // Card type (debit, credit, etc.)
  TextColumn get cardNetwork => textEnum<CardNetwork>()
      .nullable()(); // Card network (VISA, Mastercard, etc.)
  TextColumn get expiryMonth => text().nullable()(); // MM
  TextColumn get expiryYear => text().nullable()(); // YYYY
  TextColumn get cvv =>
      text().nullable()(); // Encrypted CVV (nullable for privacy)
  TextColumn get bankName => text().nullable()();
  TextColumn get accountNumber => text().nullable()();
  TextColumn get routingNumber => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get noteId => text().nullable()(); // Foreign key to notes

  // Relations
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action

  // State flags snapshot
  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  RealColumn get recentScore => real().nullable()(); // EWMA snapshot
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // Last used snapshot
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag

  // Timestamps
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();
  DateTimeColumn get originalLastUsedAt => dateTime().nullable()();
  DateTimeColumn get actionAt => dateTime().clientDefault(
    () => DateTime.now(),
  )(); // When action was performed

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'bank_cards_history';
}
