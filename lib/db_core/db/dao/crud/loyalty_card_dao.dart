import 'package:drift/drift.dart';
import 'package:hoplixi/db_core/db/main_store.dart';
import 'package:hoplixi/db_core/old/models/base_main_entity_dao.dart';
import 'package:hoplixi/db_core/old/models/dto/loyalty_card_dto.dart';
import 'package:hoplixi/db_core/old/models/enums/index.dart';
import 'package:hoplixi/db_core/db/tables/loyalty_card_items.dart';
import 'package:hoplixi/db_core/db/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'loyalty_card_dao.g.dart';

@DriftAccessor(tables: [VaultItems, LoyaltyCardItems])
class LoyaltyCardDao extends DatabaseAccessor<MainStore>
    with _$LoyaltyCardDaoMixin
    implements BaseMainEntityDao {
  LoyaltyCardDao(super.db);

  Future<List<(VaultItemsData, LoyaltyCardItemsData)>>
  getAllLoyaltyCards() async {
    final query = select(vaultItems).join([
      innerJoin(
        loyaltyCardItems,
        loyaltyCardItems.itemId.equalsExp(vaultItems.id),
      ),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => (row.readTable(vaultItems), row.readTable(loyaltyCardItems)),
        )
        .toList();
  }

  Future<(VaultItemsData, LoyaltyCardItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(
        loyaltyCardItems,
        loyaltyCardItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(loyaltyCardItems));
  }

  Stream<List<(VaultItemsData, LoyaltyCardItemsData)>> watchAllLoyaltyCards() {
    final query = select(vaultItems).join([
      innerJoin(
        loyaltyCardItems,
        loyaltyCardItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                (row.readTable(vaultItems), row.readTable(loyaltyCardItems)),
          )
          .toList(),
    );
  }

  Future<String> createLoyaltyCard(CreateLoyaltyCardDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.loyaltyCard,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(loyaltyCardItems).insert(
        LoyaltyCardItemsCompanion.insert(
          itemId: id,
          programName: dto.programName,
          cardNumber: Value(dto.cardNumber),
          holderName: Value(dto.holderName),
          barcodeValue: Value(dto.barcodeValue),
          barcodeType: Value(dto.barcodeType),
          password: Value(dto.password),
          pointsBalance: Value(dto.pointsBalance),
          tier: Value(dto.tier),
          expiryDate: Value(dto.expiryDate),
          website: Value(dto.website),
          phoneNumber: Value(dto.phoneNumber),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateLoyaltyCard(String id, UpdateLoyaltyCardDto dto) {
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

      final loyaltyCompanion = LoyaltyCardItemsCompanion(
        programName: dto.programName != null
            ? Value(dto.programName!)
            : const Value.absent(),
        cardNumber: Value(dto.cardNumber),
        holderName: Value(dto.holderName),
        barcodeValue: Value(dto.barcodeValue),
        barcodeType: Value(dto.barcodeType),
        password: Value(dto.password),
        pointsBalance: Value(dto.pointsBalance),
        tier: Value(dto.tier),
        expiryDate: Value(dto.expiryDate),
        website: Value(dto.website),
        phoneNumber: Value(dto.phoneNumber),
      );

      await (update(
        loyaltyCardItems,
      )..where((i) => i.itemId.equals(id))).write(loyaltyCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  @override
  Future<bool> incrementUsage(String id) => db.vaultItemDao.incrementUsage(id);

  @override
  Future<bool> permanentDelete(String id) =>
      db.vaultItemDao.permanentDelete(id);

  @override
  Future<bool> restoreFromDeleted(String id) =>
      db.vaultItemDao.restoreFromDeleted(id);

  @override
  Future<bool> softDelete(String id) => db.vaultItemDao.softDelete(id);

  @override
  Future<bool> toggleArchive(String id, bool isArchived) =>
      db.vaultItemDao.toggleArchive(id, isArchived);

  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) =>
      db.vaultItemDao.toggleFavorite(id, isFavorite);

  @override
  Future<bool> togglePin(String id, bool isPinned) =>
      db.vaultItemDao.togglePin(id, isPinned);
}
