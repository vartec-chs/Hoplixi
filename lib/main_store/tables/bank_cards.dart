import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:uuid/uuid.dart';

import 'categories.dart';
import 'notes.dart';

@DataClassName('BankCardsData')
class BankCards extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get cardholderName => text().withLength(min: 1, max: 255)();
  TextColumn get cardNumber => text()(); // Encrypted card number
  TextColumn get cardType => textEnum<CardType>()
      .withDefault(Constant(CardType.debit.value))
      .nullable()(); // VISA, Mastercard, etc.
  TextColumn get cardNetwork => textEnum<CardNetwork>()
      .withDefault(Constant(CardNetwork.other.value))
      .nullable()(); // Card network
  TextColumn get expiryMonth => text().withLength(min: 2, max: 2)(); // MM
  TextColumn get expiryYear => text().withLength(min: 4, max: 4)(); // YYYY
  TextColumn get cvv => text().nullable()(); // Encrypted CVV
  TextColumn get bankName => text().nullable()();
  TextColumn get accountNumber => text().nullable()(); // Account number
  TextColumn get routingNumber => text().nullable()(); // Routing number
  TextColumn get description => text().nullable()();
  TextColumn get noteId => text().nullable().references(
    Notes,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to notes
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to categories

  IntColumn get usedCount =>
      integer().withDefault(const Constant(0))(); // Usage count
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))(); // Archived flag
  BoolColumn get isPinned =>
      boolean().withDefault(const Constant(false))(); // Pinned to top flag
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  RealColumn get recentScore => real().nullable()(); // EWMA for sorting
  DateTimeColumn get lastUsedAt =>
      dateTime().nullable()(); // For filters and UX

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'bank_cards';
}
