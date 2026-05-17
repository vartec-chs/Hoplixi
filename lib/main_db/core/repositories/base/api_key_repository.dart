import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/api_key/api_key_items.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/mappers/api_key_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class ApiKeyRepository {
  final MainStore db;

  ApiKeyRepository(this.db);

  Future<String> create(CreateApiKeyDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db
          .into(db.vaultItems)
          .insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.apiKey,
              name: dto.item.name,
              description: Value(dto.item.description),
              categoryId: Value(dto.item.categoryId),
              iconRefId: Value(dto.item.iconRefId),
              isFavorite: Value(dto.item.isFavorite),
              isPinned: Value(dto.item.isPinned),
              createdAt: Value(now),
              modifiedAt: Value(now),
            ),
          );

      await db
          .into(db.apiKeyItems)
          .insert(
            ApiKeyItemsCompanion.insert(
              itemId: itemId,
              service: dto.apiKey.service,
              key: dto.apiKey.key,
              tokenType: Value(dto.apiKey.tokenType),
              tokenTypeOther: Value(dto.apiKey.tokenTypeOther),
              environment: Value(dto.apiKey.environment),
              environmentOther: Value(dto.apiKey.environmentOther),
              expiresAt: Value(dto.apiKey.expiresAt),
              revoked: Value(dto.apiKey.revokedAt != null),
              revokedAt: Value(dto.apiKey.revokedAt),
              rotationPeriodDays: Value(dto.apiKey.rotationPeriodDays),
              lastRotatedAt: Value(dto.apiKey.lastRotatedAt),
              owner: Value(dto.apiKey.owner),
              baseUrl: Value(dto.apiKey.baseUrl),
              scopesText: Value(dto.apiKey.scopesText),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(PatchApiKeyDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(
        db.vaultItems,
      )..where((tbl) => tbl.id.equals(itemId))).write(
        VaultItemsCompanion(
          name: dto.item.name.toRequiredValue(),
          description: dto.item.description.toNullableValue(),
          categoryId: dto.item.categoryId.toNullableValue(),
          iconRefId: dto.item.iconRefId.toNullableValue(),
          isFavorite: dto.item.isFavorite.toRequiredValue(),
          isPinned: dto.item.isPinned.toRequiredValue(),
          modifiedAt: Value(now),
        ),
      );

      final revokedAtUpdate = dto.apiKey.revokedAt;
      Value<bool> revokedUpdate = const Value.absent();
      if (revokedAtUpdate is FieldUpdateSet<DateTime>) {
        revokedUpdate = Value(revokedAtUpdate.value != null);
      }

      await (db.update(
        db.apiKeyItems,
      )..where((tbl) => tbl.itemId.equals(itemId))).write(
        ApiKeyItemsCompanion(
          service: dto.apiKey.service.toRequiredValue(),
          key: dto.apiKey.key.toRequiredValue(),
          tokenType: dto.apiKey.tokenType.toNullableValue(),
          tokenTypeOther: dto.apiKey.tokenTypeOther.toNullableValue(),
          environment: dto.apiKey.environment.toNullableValue(),
          environmentOther: dto.apiKey.environmentOther.toNullableValue(),
          expiresAt: dto.apiKey.expiresAt.toNullableValue(),
          revoked: revokedUpdate,
          revokedAt: dto.apiKey.revokedAt.toNullableValue(),
          rotationPeriodDays: dto.apiKey.rotationPeriodDays.toNullableValue(),
          lastRotatedAt: dto.apiKey.lastRotatedAt.toNullableValue(),
          owner: dto.apiKey.owner.toNullableValue(),
          baseUrl: dto.apiKey.baseUrl.toNullableValue(),
          scopesText: dto.apiKey.scopesText.toNullableValue(),
        ),
      );

      final tagsUpdate = dto.tags;
      if (tagsUpdate is FieldUpdateSet<List<String>>) {
        await db.itemTagsDao.removeAllTagsFromItem(itemId);
        for (final tagId in tagsUpdate.value ?? []) {
          await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
        }
      }
    });
  }

  Future<ApiKeyViewDto?> getViewById(String itemId) async {
    final query =
        db.select(db.vaultItems).join([
            innerJoin(
              db.apiKeyItems,
              db.apiKeyItems.itemId.equalsExp(db.vaultItems.id),
            ),
          ])
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.apiKey));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final apiKey = row.readTable(db.apiKeyItems);

    return ApiKeyViewDto(
      item: item.toVaultItemViewDto(),
      apiKey: apiKey.toApiKeyDataDto(),
    );
  }

  Future<ApiKeyCardDto?> getCardById(String itemId) async {
    final expr = _ApiKeyCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.apiKey));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<ApiKeyCardDto>> getCards({int limit = 50, int offset = 0}) async {
    final expr = _ApiKeyCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.apiKey))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(
      db.vaultItems,
    )..where((tbl) => tbl.id.equals(itemId))).go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _ApiKeyCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.apiKeyItems,
        db.apiKeyItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])..addColumns([
      db.vaultItems.id,
      db.vaultItems.type,
      db.vaultItems.name,
      db.vaultItems.description,
      db.vaultItems.categoryId,
      db.vaultItems.iconRefId,
      db.vaultItems.isFavorite,
      db.vaultItems.isArchived,
      db.vaultItems.isPinned,
      db.vaultItems.isDeleted,
      db.vaultItems.createdAt,
      db.vaultItems.modifiedAt,
      db.vaultItems.lastUsedAt,
      db.vaultItems.archivedAt,
      db.vaultItems.deletedAt,
      db.vaultItems.recentScore,

      db.apiKeyItems.service,
      db.apiKeyItems.tokenType,
      db.apiKeyItems.environment,
      db.apiKeyItems.expiresAt,
      db.apiKeyItems.revokedAt,
      db.apiKeyItems.rotationPeriodDays,
      db.apiKeyItems.lastRotatedAt,
      db.apiKeyItems.owner,
      db.apiKeyItems.baseUrl,
      expr.hasKey,
    ]);
  }

  ApiKeyCardDto _mapRowToCardDto(TypedResult row, _ApiKeyCardExpressions expr) {
    return ApiKeyCardDto(
      item: VaultItemCardDto(
        itemId: row.read(db.vaultItems.id)!,
        type: row.readWithConverter<VaultItemType, String>(db.vaultItems.type)!,
        name: row.read(db.vaultItems.name)!,
        description: row.read(db.vaultItems.description),
        categoryId: row.read(db.vaultItems.categoryId),
        iconRefId: row.read(db.vaultItems.iconRefId),
        isFavorite: row.read(db.vaultItems.isFavorite)!,
        isArchived: row.read(db.vaultItems.isArchived)!,
        isPinned: row.read(db.vaultItems.isPinned)!,
        isDeleted: row.read(db.vaultItems.isDeleted)!,
        createdAt: row.read(db.vaultItems.createdAt)!,
        modifiedAt: row.read(db.vaultItems.modifiedAt)!,
        lastUsedAt: row.read(db.vaultItems.lastUsedAt),
        archivedAt: row.read(db.vaultItems.archivedAt),
        deletedAt: row.read(db.vaultItems.deletedAt),
        recentScore: row.read(db.vaultItems.recentScore),
      ),
      apiKey: ApiKeyCardDataDto(
        service: row.read(db.apiKeyItems.service)!,
        tokenType: row.readWithConverter<ApiKeyTokenType?, String>(
          db.apiKeyItems.tokenType,
        ),
        environment: row.readWithConverter<ApiKeyEnvironment?, String>(
          db.apiKeyItems.environment,
        ),
        expiresAt: row.read(db.apiKeyItems.expiresAt),
        revokedAt: row.read(db.apiKeyItems.revokedAt),
        rotationPeriodDays: row.read(db.apiKeyItems.rotationPeriodDays),
        lastRotatedAt: row.read(db.apiKeyItems.lastRotatedAt),
        owner: row.read(db.apiKeyItems.owner),
        baseUrl: row.read(db.apiKeyItems.baseUrl),
        hasKey: row.read(expr.hasKey) ?? false,
      ),
    );
  }
}

class _ApiKeyCardExpressions {
  _ApiKeyCardExpressions(this.db) : hasKey = db.apiKeyItems.key.isNotNull();

  final MainStore db;
  final Expression<bool> hasKey;
}
