import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/tables.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../models/mappers/wifi_mapper.dart';

class WifiRepository {
  final VaultDB db;

  WifiRepository(this.db);

  AsyncDbResult<String> create(CreateWifiDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db
            .into(db.vaultItems)
            .insert(
              VaultItemsCompanion.insert(
                id: Value(itemId),
                type: VaultItemType.wifi,
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
            .into(db.wifiItems)
            .insert(
              WifiItemsCompanion.insert(
                itemId: itemId,
                ssid: dto.wifi.ssid,
                password: Value(dto.wifi.password),
                securityType: Value(dto.wifi.securityType),
                securityTypeOther: Value(dto.wifi.securityTypeOther),
                encryption: Value(dto.wifi.encryption),
                encryptionOther: Value(dto.wifi.encryptionOther),
                hiddenSsid: Value(dto.wifi.hiddenSsid),
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
              message: 'Ошибка при создании Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchWifiDto dto) {
    return ResultUtils.tryCatchAsync(
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

        await (db.update(
          db.wifiItems,
        )..where((tbl) => tbl.itemId.equals(itemId))).write(
          WifiItemsCompanion(
            ssid: dto.wifi.ssid.toRequiredValue(),
            password: dto.wifi.password.toNullableValue(),
            securityType: dto.wifi.securityType.toNullableValue(),
            securityTypeOther: dto.wifi.securityTypeOther.toNullableValue(),
            encryption: dto.wifi.encryption.toNullableValue(),
            encryptionOther: dto.wifi.encryptionOther.toNullableValue(),
            hiddenSsid: dto.wifi.hiddenSsid.toRequiredValue(),
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
              message: 'Ошибка при обновлении Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<WifiViewDto>> getViewById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.wifiItems,
                  db.wifiItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(db.vaultItems.type.equalsValue(VaultItemType.wifi));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final wifi = row.readTable(db.wifiItems);

        return Some(
          WifiViewDto(
            item: item.toVaultItemViewDto(),
            wifi: wifi.toWifiDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<WifiCardDto>> getCardById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final expr = _WifiCardExpressions(db);
        final query = _buildCardQuery(expr)
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.wifi));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row, expr));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<WifiCardDto>> getCards({int limit = 50, int offset = 0}) {
    return ResultUtils.tryCatchAsync(
      () async {
        final expr = _WifiCardExpressions(db);
        final query = _buildCardQuery(expr)
          ..where(db.vaultItems.type.equalsValue(VaultItemType.wifi))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> deletePermanently(String itemId) {
    return ResultUtils.tryCatchAsync(
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
              message: 'Ошибка при удалении Wi-Fi',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _WifiCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(db.wifiItems, db.wifiItems.itemId.equalsExp(db.vaultItems.id)),
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
      db.wifiItems.ssid,
      db.wifiItems.securityType,
      db.wifiItems.encryption,
      db.wifiItems.hiddenSsid,
      expr.hasWifiPassword,
    ]);
  }

  WifiCardDto _mapRowToCardDto(TypedResult row, _WifiCardExpressions expr) {
    return WifiCardDto(
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
      wifi: WifiCardDataDto(
        ssid: row.read(db.wifiItems.ssid)!,
        securityType: row.readWithConverter<WifiSecurityType?, String>(
          db.wifiItems.securityType,
        ),
        encryption: row.readWithConverter<WifiEncryptionType?, String>(
          db.wifiItems.encryption,
        ),
        hiddenSsid: row.read(db.wifiItems.hiddenSsid)!,
        hasWifiPassword: row.read(expr.hasWifiPassword) ?? false,
      ),
    );
  }
}

class _WifiCardExpressions {
  _WifiCardExpressions(this.db)
    : hasWifiPassword = db.wifiItems.password.isNotNull();

  final VaultDB db;
  final Expression<bool> hasWifiPassword;
}
