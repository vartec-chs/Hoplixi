import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/otp/otp_items.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/dto/otp_dto.dart';
import '../../models/mappers/otp_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class OtpRepository {
  final MainStore db;

  OtpRepository(this.db);

  Future<String> create(CreateOtpDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.otp,
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

      await db.into(db.otpItems).insert(
            OtpItemsCompanion.insert(
              itemId: itemId,
              type: Value(dto.otp.type),
              issuer: Value(dto.otp.issuer),
              accountName: Value(dto.otp.accountName),
              secret: dto.otp.secret,
              algorithm: Value(dto.otp.algorithm),
              digits: Value(dto.otp.digits),
              period: Value(dto.otp.period),
              counter: Value(dto.otp.counter),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateOtpDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = dto.item.itemId;

      await (db.update(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
          .write(
        VaultItemsCompanion(
          name: Value(dto.item.name),
          description: Value(dto.item.description),
          categoryId: Value(dto.item.categoryId),
          iconRefId: Value(dto.item.iconRefId),
          isFavorite: Value(dto.item.isFavorite),
          isPinned: Value(dto.item.isPinned),
          modifiedAt: Value(now),
        ),
      );

      await (db.update(db.otpItems)..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        OtpItemsCompanion(
          type: Value(dto.otp.type),
          issuer: Value(dto.otp.issuer),
          accountName: Value(dto.otp.accountName),
          secret: Value(dto.otp.secret),
          algorithm: Value(dto.otp.algorithm),
          digits: Value(dto.otp.digits),
          period: Value(dto.otp.period),
          counter: Value(dto.otp.counter),
        ),
      );
    });
  }

  Future<OtpViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.otpItems,
        db.otpItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.otp));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final otp = row.readTable(db.otpItems);

    return OtpViewDto(
      item: item.toVaultItemViewDto(),
      otp: otp.toOtpDataDto(),
    );
  }

  Future<OtpCardDto?> getCardById(String itemId) async {
    final expr = _OtpCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.otp));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<OtpCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final expr = _OtpCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.otp))
      ..where(db.vaultItems.isDeleted.equals(false))
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) => _mapRowToCardDto(row, expr)).toList();
  }

  Future<void> deletePermanently(String itemId) {
    return (db.delete(db.vaultItems)..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildCardQuery(
    _OtpCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.otpItems,
        db.otpItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..addColumns([
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

        db.otpItems.type,
        db.otpItems.issuer,
        db.otpItems.accountName,
        db.otpItems.algorithm,
        db.otpItems.digits,
        db.otpItems.period,
        db.otpItems.counter,
        expr.hasSecret,
      ]);
  }

  OtpCardDto _mapRowToCardDto(TypedResult row, _OtpCardExpressions expr) {
    return OtpCardDto(
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
      otp: OtpCardDataDto(
        type: row.readWithConverter<OtpType, String>(db.otpItems.type)!,
        issuer: row.read(db.otpItems.issuer),
        accountName: row.read(db.otpItems.accountName),
        algorithm:
            row.readWithConverter<OtpHashAlgorithm, String>(db.otpItems.algorithm)!,
        digits: row.read(db.otpItems.digits)!,
        period: row.read(db.otpItems.period),
        counter: row.read(db.otpItems.counter),
        hasSecret: row.read(expr.hasSecret) ?? false,
      ),
    );
  }
}

class _OtpCardExpressions {
  _OtpCardExpressions(this.db) : hasSecret = db.otpItems.secret.isNotNull();

  final MainStore db;
  final Expression<bool> hasSecret;
}
