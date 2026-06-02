import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/errors/db_error.dart';
import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/api_key/api_key_items.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import '../../models/mappers/api_key_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class ApiKeyRepository {
  final VaultDB db;

  ApiKeyRepository(this.db);

  AsyncDBResult<String> create(CreateApiKeyDto dto) {
    return tryCatchAsync(
      () => db.transaction(() async {
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

        if (dto.tagIds.isNotEmpty) {
          for (final tagId in dto.tagIds) {
            await db.itemTagsDao.assignTagToItem(itemId: itemId, tagId: tagId);
          }
        }

        return itemId;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> update(PatchApiKeyDto dto) {
    return tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = dto.item.itemId;

        final itemUpdated =
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

        if (itemUpdated == 0) {
          throw DBCoreError.notFound(entity: 'vault_items', id: itemId);
        }

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
        return unit;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при обновлении API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<ApiKeyViewDto>> getViewById(String itemId) {
    return tryCatchAsync(
      () async {
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
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final apiKey = row.readTable(db.apiKeyItems);

        return Some(
          ApiKeyViewDto(
            item: item.toVaultItemViewDto(),
            apiKey: apiKey.toApiKeyDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении API ключа по ID',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Optional<ApiKeyCardDto>> getCardById(String itemId) {
    return tryCatchAsync(
      () async {
        final expr = _ApiKeyCardExpressions(db);
        final query = _buildCardQuery(expr)
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.apiKey));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row, expr));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<List<ApiKeyCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return tryCatchAsync(
      () async {
        final expr = _ApiKeyCardExpressions(db);
        final query = _buildCardQuery(expr)
          ..where(db.vaultItems.type.equalsValue(VaultItemType.apiKey))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка API ключей',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDBResult<Unit> deletePermanently(String itemId) {
    return tryCatchAsync(
      () async {
        final rows = await (db.delete(
          db.vaultItems,
        )..where((tbl) => tbl.id.equals(itemId))).go();
        if (rows == 0) {
          throw DBCoreError.notFound(entity: 'vault_items', id: itemId);
        }
        return unit;
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при окончательном удалении API ключа',
              cause: e,
              stackTrace: st,
            ),
    );
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
      data: ApiKeyCardDataDto(
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

  final VaultDB db;
  final Expression<bool> hasKey;
}
