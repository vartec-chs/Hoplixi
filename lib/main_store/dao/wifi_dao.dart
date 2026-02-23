import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/wifi_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:hoplixi/main_store/tables/wifi_items.dart';
import 'package:uuid/uuid.dart';

part 'wifi_dao.g.dart';

@DriftAccessor(tables: [VaultItems, WifiItems])
class WifiDao extends DatabaseAccessor<MainStore>
    with _$WifiDaoMixin
    implements BaseMainEntityDao {
  WifiDao(super.db);

  Future<List<(VaultItemsData, WifiItemsData)>> getAllWifis() async {
    final query = select(
      vaultItems,
    ).join([innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id))]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(wifiItems)))
        .toList();
  }

  Future<(VaultItemsData, WifiItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(wifiItems));
  }

  Stream<List<(VaultItemsData, WifiItemsData)>> watchAllWifis() {
    final query = select(vaultItems).join([
      innerJoin(wifiItems, wifiItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(vaultItems), row.readTable(wifiItems)))
          .toList(),
    );
  }

  Future<String> createWifi(CreateWifiDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.wifi,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(wifiItems).insert(
        WifiItemsCompanion.insert(
          itemId: id,
          ssid: dto.ssid,
          password: Value(dto.password),
          security: Value(dto.security),
          hidden: Value(dto.hidden ?? false),
          eapMethod: Value(dto.eapMethod),
          username: Value(dto.username),
          identity: Value(dto.identity),
          domain: Value(dto.domain),
          lastConnectedBssid: Value(dto.lastConnectedBssid),
          priority: Value(dto.priority),
          qrCodePayload: Value(dto.qrCodePayload),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateWifi(String id, UpdateWifiDto dto) {
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

      final itemCompanion = WifiItemsCompanion(
        ssid: dto.ssid != null ? Value(dto.ssid!) : const Value.absent(),
        password: Value(dto.password),
        security: Value(dto.security),
        hidden: dto.hidden != null ? Value(dto.hidden!) : const Value.absent(),
        eapMethod: Value(dto.eapMethod),
        username: Value(dto.username),
        identity: Value(dto.identity),
        domain: Value(dto.domain),
        lastConnectedBssid: Value(dto.lastConnectedBssid),
        priority: Value(dto.priority),
        qrCodePayload: Value(dto.qrCodePayload),
      );

      await (update(
        wifiItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  Future<String?> getPasswordFieldById(String id) async {
    final query = selectOnly(wifiItems)
      ..addColumns([wifiItems.password])
      ..where(wifiItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(wifiItems.password);
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
