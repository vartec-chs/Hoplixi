import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/recovery_codes_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/recovery_codes_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'recovery_codes_dao.g.dart';

@DriftAccessor(tables: [VaultItems, RecoveryCodesItems])
class RecoveryCodesDao extends DatabaseAccessor<MainStore>
    with _$RecoveryCodesDaoMixin
    implements BaseMainEntityDao {
  RecoveryCodesDao(super.db);

  Future<List<(VaultItemsData, RecoveryCodesItemsData)>>
  getAllRecoveryCodes() async {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => (
            row.readTable(vaultItems),
            row.readTable(recoveryCodesItems),
          ),
        )
        .toList();
  }

  Future<(VaultItemsData, RecoveryCodesItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(recoveryCodesItems));
  }

  Stream<List<(VaultItemsData, RecoveryCodesItemsData)>> watchAllRecoveryCodes() {
    final query = select(vaultItems).join([
      innerJoin(
        recoveryCodesItems,
        recoveryCodesItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              row.readTable(vaultItems),
              row.readTable(recoveryCodesItems),
            ),
          )
          .toList(),
    );
  }

  Future<String> createRecoveryCodes(CreateRecoveryCodesDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.recoveryCodes,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(recoveryCodesItems).insert(
        RecoveryCodesItemsCompanion.insert(
          itemId: id,
          codesBlob: dto.codesBlob,
          codesCount: Value(dto.codesCount),
          usedCount: Value(dto.usedCount),
          perCodeStatus: Value(dto.perCodeStatus),
          generatedAt: Value(dto.generatedAt),
          notes: Value(dto.notes),
          oneTime: Value(dto.oneTime ?? false),
          displayHint: Value(dto.displayHint),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateRecoveryCodes(String id, UpdateRecoveryCodesDto dto) {
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

      final itemCompanion = RecoveryCodesItemsCompanion(
        codesBlob: dto.codesBlob != null
            ? Value(dto.codesBlob!)
            : const Value.absent(),
        codesCount: Value(dto.codesCount),
        usedCount: Value(dto.usedCount),
        perCodeStatus: Value(dto.perCodeStatus),
        generatedAt: Value(dto.generatedAt),
        notes: Value(dto.notes),
        oneTime: dto.oneTime != null
            ? Value(dto.oneTime!)
            : const Value.absent(),
        displayHint: Value(dto.displayHint),
      );

      await (update(
        recoveryCodesItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

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
