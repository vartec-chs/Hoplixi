import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/bank_card_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'bank_card_dao.g.dart';

@DriftAccessor(tables: [VaultItems, BankCardItems])
class BankCardDao extends DatabaseAccessor<MainStore> with _$BankCardDaoMixin {
  BankCardDao(super.db);

  /// Получить все карты (JOIN)
  Future<List<(VaultItemsData, BankCardItemsData)>> getAllBankCards() async {
    final query = select(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(bankCardItems)))
        .toList();
  }

  /// Получить карту по ID
  Future<(VaultItemsData, BankCardItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(bankCardItems));
  }

  /// Смотреть все карты
  Stream<List<(VaultItemsData, BankCardItemsData)>> watchAllBankCards() {
    final query = select(vaultItems).join([
      innerJoin(bankCardItems, bankCardItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (row.readTable(vaultItems), row.readTable(bankCardItems)),
          )
          .toList(),
    );
  }

  /// Создать новую карту
  Future<String> createBankCard(CreateBankCardDto dto) {
    final uuid = const Uuid().v4();
    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(uuid),
          type: VaultItemType.bankCard,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );
      await into(bankCardItems).insert(
        BankCardItemsCompanion.insert(
          itemId: uuid,
          cardholderName: dto.cardholderName,
          cardNumber: dto.cardNumber,
          expiryMonth: dto.expiryMonth,
          expiryYear: dto.expiryYear,
          cardType: dto.cardType != null
              ? Value(CardTypeX.fromString(dto.cardType!))
              : const Value.absent(),
          cardNetwork: dto.cardNetwork != null
              ? Value(CardNetworkX.fromString(dto.cardNetwork!))
              : const Value.absent(),
          cvv: Value(dto.cvv),
          bankName: Value(dto.bankName),
          accountNumber: Value(dto.accountNumber),
          routingNumber: Value(dto.routingNumber),
        ),
      );
      await db.vaultItemDao.insertTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  /// Обновить карту
  Future<bool> updateBankCard(String id, UpdateBankCardDto dto) {
    return db.transaction(() async {
      final vaultCompanion = VaultItemsCompanion(
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isArchived: dto.isArchived != null
            ? Value(dto.isArchived!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );
      await (update(
        vaultItems,
      )..where((v) => v.id.equals(id))).write(vaultCompanion);

      final cardCompanion = BankCardItemsCompanion(
        cardholderName: dto.cardholderName != null
            ? Value(dto.cardholderName!)
            : const Value.absent(),
        cardNumber: dto.cardNumber != null
            ? Value(dto.cardNumber!)
            : const Value.absent(),
        expiryMonth: dto.expiryMonth != null
            ? Value(dto.expiryMonth!)
            : const Value.absent(),
        expiryYear: dto.expiryYear != null
            ? Value(dto.expiryYear!)
            : const Value.absent(),
        cardType: dto.cardType != null
            ? Value(CardTypeX.fromString(dto.cardType!))
            : const Value(null),
        cardNetwork: dto.cardNetwork != null
            ? Value(CardNetworkX.fromString(dto.cardNetwork!))
            : const Value(null),
        cvv: Value(dto.cvv),
        bankName: Value(dto.bankName),
        accountNumber: Value(dto.accountNumber),
        routingNumber: Value(dto.routingNumber),
      );
      await (update(
        bankCardItems,
      )..where((c) => c.itemId.equals(id))).write(cardCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }
      return true;
    });
  }
}
