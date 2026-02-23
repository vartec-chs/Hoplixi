import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/license_key_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/license_key_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'license_key_dao.g.dart';

@DriftAccessor(tables: [VaultItems, LicenseKeyItems])
class LicenseKeyDao extends DatabaseAccessor<MainStore>
    with _$LicenseKeyDaoMixin
    implements BaseMainEntityDao {
  LicenseKeyDao(super.db);

  Future<List<(VaultItemsData, LicenseKeyItemsData)>>
  getAllLicenseKeys() async {
    final query = select(vaultItems).join([
      innerJoin(
        licenseKeyItems,
        licenseKeyItems.itemId.equalsExp(vaultItems.id),
      ),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => (row.readTable(vaultItems), row.readTable(licenseKeyItems)),
        )
        .toList();
  }

  Future<(VaultItemsData, LicenseKeyItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(
        licenseKeyItems,
        licenseKeyItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(licenseKeyItems));
  }

  Stream<List<(VaultItemsData, LicenseKeyItemsData)>> watchAllLicenseKeys() {
    final query = select(vaultItems).join([
      innerJoin(
        licenseKeyItems,
        licenseKeyItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                (row.readTable(vaultItems), row.readTable(licenseKeyItems)),
          )
          .toList(),
    );
  }

  Future<String> createLicenseKey(CreateLicenseKeyDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.licenseKey,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(licenseKeyItems).insert(
        LicenseKeyItemsCompanion.insert(
          itemId: id,
          product: dto.product,
          licenseKey: dto.licenseKey,
          licenseType: Value(dto.licenseType),
          seats: Value(dto.seats),
          maxActivations: Value(dto.maxActivations),
          activatedOn: Value(dto.activatedOn),
          purchaseDate: Value(dto.purchaseDate),
          purchaseFrom: Value(dto.purchaseFrom),
          orderId: Value(dto.orderId),
          licenseFileId: Value(dto.licenseFileId),
          expiresAt: Value(dto.expiresAt),
          supportContact: Value(dto.supportContact),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateLicenseKey(String id, UpdateLicenseKeyDto dto) {
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

      final itemCompanion = LicenseKeyItemsCompanion(
        product: dto.product != null
            ? Value(dto.product!)
            : const Value.absent(),
        licenseKey: dto.licenseKey != null
            ? Value(dto.licenseKey!)
            : const Value.absent(),
        licenseType: Value(dto.licenseType),
        seats: Value(dto.seats),
        maxActivations: Value(dto.maxActivations),
        activatedOn: Value(dto.activatedOn),
        purchaseDate: Value(dto.purchaseDate),
        purchaseFrom: Value(dto.purchaseFrom),
        orderId: Value(dto.orderId),
        licenseFileId: Value(dto.licenseFileId),
        expiresAt: Value(dto.expiresAt),
        supportContact: Value(dto.supportContact),
      );

      await (update(
        licenseKeyItems,
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
