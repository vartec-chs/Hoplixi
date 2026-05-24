import 'package:drift/drift.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/license_key/license_key_items.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/mappers/license_key_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../scheme/tables/vault_items/vault_items.dart';

class LicenseKeyRepository {
  final VaultDB db;

  LicenseKeyRepository(this.db);

  AsyncDbResult<String> create(CreateLicenseKeyDto dto) {
    return ResultUtils.tryCatchAsync(
      () => db.transaction(() async {
        final now = DateTime.now();
        final itemId = const Uuid().v4();

        await db
            .into(db.vaultItems)
            .insert(
              VaultItemsCompanion.insert(
                id: Value(itemId),
                type: VaultItemType.licenseKey,
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
            .into(db.licenseKeyItems)
            .insert(
              LicenseKeyItemsCompanion.insert(
                itemId: itemId,
                productName: dto.licenseKey.productName,
                vendor: Value(dto.licenseKey.vendor),
                licenseKey: dto.licenseKey.licenseKey,
                licenseType: Value(dto.licenseKey.licenseType),
                licenseTypeOther: Value(dto.licenseKey.licenseTypeOther),
                accountEmail: Value(dto.licenseKey.accountEmail),
                accountUsername: Value(dto.licenseKey.accountUsername),
                purchaseEmail: Value(dto.licenseKey.purchaseEmail),
                orderNumber: Value(dto.licenseKey.orderNumber),
                purchaseDate: Value(dto.licenseKey.purchaseDate),
                purchasePrice: Value(dto.licenseKey.purchasePrice),
                currency: Value(dto.licenseKey.currency),
                validFrom: Value(dto.licenseKey.validFrom),
                validTo: Value(dto.licenseKey.validTo),
                renewalDate: Value(dto.licenseKey.renewalDate),
                seats: Value(dto.licenseKey.seats),
                activationLimit: Value(dto.licenseKey.activationLimit),
                activationsUsed: Value(dto.licenseKey.activationsUsed),
              ),
            );

        return itemId;
      }),
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при создании лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Unit> update(PatchLicenseKeyDto dto) {
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
          db.licenseKeyItems,
        )..where((tbl) => tbl.itemId.equals(itemId))).write(
          LicenseKeyItemsCompanion(
            productName: dto.licenseKey.productName.toRequiredValue(),
            vendor: dto.licenseKey.vendor.toNullableValue(),
            licenseKey: dto.licenseKey.licenseKey.toRequiredValue(),
            licenseType: dto.licenseKey.licenseType.toNullableValue(),
            licenseTypeOther: dto.licenseKey.licenseTypeOther.toNullableValue(),
            accountEmail: dto.licenseKey.accountEmail.toNullableValue(),
            accountUsername: dto.licenseKey.accountUsername.toNullableValue(),
            purchaseEmail: dto.licenseKey.purchaseEmail.toNullableValue(),
            orderNumber: dto.licenseKey.orderNumber.toNullableValue(),
            purchaseDate: dto.licenseKey.purchaseDate.toNullableValue(),
            purchasePrice: dto.licenseKey.purchasePrice.toNullableValue(),
            currency: dto.licenseKey.currency.toNullableValue(),
            validFrom: dto.licenseKey.validFrom.toNullableValue(),
            validTo: dto.licenseKey.validTo.toNullableValue(),
            renewalDate: dto.licenseKey.renewalDate.toNullableValue(),
            seats: dto.licenseKey.seats.toNullableValue(),
            activationLimit: dto.licenseKey.activationLimit.toNullableValue(),
            activationsUsed: dto.licenseKey.activationsUsed.toNullableValue(),
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
              message: 'Ошибка при обновлении лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<LicenseKeyViewDto>> getViewById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final query =
            db.select(db.vaultItems).join([
                innerJoin(
                  db.licenseKeyItems,
                  db.licenseKeyItems.itemId.equalsExp(db.vaultItems.id),
                ),
              ])
              ..where(db.vaultItems.id.equals(itemId))
              ..where(db.vaultItems.type.equalsValue(VaultItemType.licenseKey));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        final item = row.readTable(db.vaultItems);
        final licenseKey = row.readTable(db.licenseKeyItems);

        return Some(
          LicenseKeyViewDto(
            item: item.toVaultItemViewDto(),
            licenseKey: licenseKey.toLicenseKeyDataDto(),
          ),
        );
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<Optional<LicenseKeyCardDto>> getCardById(String itemId) {
    return ResultUtils.tryCatchAsync(
      () async {
        final expr = _LicenseKeyCardExpressions(db);
        final query = _buildCardQuery(expr)
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.licenseKey));

        final row = await query.getSingleOrNull();
        if (row == null) return const None();

        return Some(_mapRowToCardDto(row, expr));
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении карточки лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  AsyncDbResult<List<LicenseKeyCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) {
    return ResultUtils.tryCatchAsync(
      () async {
        final expr = _LicenseKeyCardExpressions(db);
        final query = _buildCardQuery(expr)
          ..where(db.vaultItems.type.equalsValue(VaultItemType.licenseKey))
          ..where(db.vaultItems.isDeleted.equals(false))
          ..limit(limit, offset: offset);

        final rows = await query.get();
        return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
      },
      (e, st) => e is DBCoreError
          ? e
          : DBCoreError.unknown(
              message: 'Ошибка при получении списка лицензионных ключей',
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
              message: 'Ошибка при удалении лицензионного ключа',
              cause: e,
              stackTrace: st,
            ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _LicenseKeyCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.licenseKeyItems,
        db.licenseKeyItems.itemId.equalsExp(db.vaultItems.id),
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
      db.licenseKeyItems.productName,
      db.licenseKeyItems.vendor,
      db.licenseKeyItems.licenseType,
      db.licenseKeyItems.accountEmail,
      db.licenseKeyItems.accountUsername,
      db.licenseKeyItems.validTo,
      expr.hasKey,
    ]);
  }

  LicenseKeyCardDto _mapRowToCardDto(
    TypedResult row,
    _LicenseKeyCardExpressions expr,
  ) {
    return LicenseKeyCardDto(
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
      licenseKey: LicenseKeyCardDataDto(
        productName: row.read(db.licenseKeyItems.productName)!,
        vendor: row.read(db.licenseKeyItems.vendor),
        licenseType: row.readWithConverter<LicenseType?, String>(
          db.licenseKeyItems.licenseType,
        ),
        accountEmail: row.read(db.licenseKeyItems.accountEmail),
        accountUsername: row.read(db.licenseKeyItems.accountUsername),
        validTo: row.read(db.licenseKeyItems.validTo),
        hasKey: row.read(expr.hasKey) ?? false,
      ),
    );
  }
}

class _LicenseKeyCardExpressions {
  _LicenseKeyCardExpressions(this.db)
    : hasKey = db.licenseKeyItems.licenseKey.isNotNull();

  final VaultDB db;
  final Expression<bool> hasKey;
}
