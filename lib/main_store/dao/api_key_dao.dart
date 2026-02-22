import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/api_key_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/api_key_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'api_key_dao.g.dart';

@DriftAccessor(tables: [VaultItems, ApiKeyItems])
class ApiKeyDao extends DatabaseAccessor<MainStore>
    with _$ApiKeyDaoMixin
    implements BaseMainEntityDao {
  ApiKeyDao(super.db);

  Future<List<(VaultItemsData, ApiKeyItemsData)>> getAllApiKeys() async {
    final query = select(vaultItems).join([
      innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(apiKeyItems)))
        .toList();
  }

  Future<(VaultItemsData, ApiKeyItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(apiKeyItems));
  }

  Stream<List<(VaultItemsData, ApiKeyItemsData)>> watchAllApiKeys() {
    final query = select(vaultItems).join([
      innerJoin(apiKeyItems, apiKeyItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(vaultItems), row.readTable(apiKeyItems)))
          .toList(),
    );
  }

  Future<String> createApiKey(CreateApiKeyDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.apiKey,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(apiKeyItems).insert(
        ApiKeyItemsCompanion.insert(
          itemId: id,
          service: dto.service,
          key: dto.key,
          maskedKey: Value(dto.maskedKey),
          tokenType: Value(dto.tokenType),
          environment: Value(dto.environment),
          expiresAt: Value(dto.expiresAt),
          revoked: Value(dto.revoked ?? false),
          rotationPeriodDays: Value(dto.rotationPeriodDays),
          lastRotatedAt: Value(dto.lastRotatedAt),
          metadata: Value(dto.metadata),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateApiKey(String id, UpdateApiKeyDto dto) {
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

      final itemCompanion = ApiKeyItemsCompanion(
        service: dto.service != null
            ? Value(dto.service!)
            : const Value.absent(),
        key: dto.key != null ? Value(dto.key!) : const Value.absent(),
        maskedKey: Value(dto.maskedKey),
        tokenType: Value(dto.tokenType),
        environment: Value(dto.environment),
        expiresAt: Value(dto.expiresAt),
        revoked: dto.revoked != null
            ? Value(dto.revoked!)
            : const Value.absent(),
        rotationPeriodDays: Value(dto.rotationPeriodDays),
        lastRotatedAt: Value(dto.lastRotatedAt),
        metadata: Value(dto.metadata),
      );

      await (update(
        apiKeyItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  Future<String?> getKeyFieldById(String id) async {
    final query = selectOnly(apiKeyItems)
      ..addColumns([apiKeyItems.key])
      ..where(apiKeyItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(apiKeyItems.key);
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
