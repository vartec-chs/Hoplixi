import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/ssh_key/ssh_key_items.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/dto/ssh_key_dto.dart';
import '../../models/mappers/ssh_key_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class SshKeyRepository {
  final MainStore db;

  SshKeyRepository(this.db);

  Future<String> create(CreateSshKeyDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db.into(db.vaultItems).insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.sshKey,
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

      await db.into(db.sshKeyItems).insert(
            SshKeyItemsCompanion.insert(
              itemId: itemId,
              publicKey: Value(dto.sshKey.publicKey),
              privateKey: Value(dto.sshKey.privateKey),
              keyType: Value(dto.sshKey.keyType),
              keyTypeOther: Value(dto.sshKey.keyTypeOther),
              keySize: Value(dto.sshKey.keySize),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(UpdateSshKeyDto dto) {
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

      await (db.update(db.sshKeyItems)
            ..where((tbl) => tbl.itemId.equals(itemId)))
          .write(
        SshKeyItemsCompanion(
          publicKey: Value(dto.sshKey.publicKey),
          privateKey: Value(dto.sshKey.privateKey),
          keyType: Value(dto.sshKey.keyType),
          keyTypeOther: Value(dto.sshKey.keyTypeOther),
          keySize: Value(dto.sshKey.keySize),
        ),
      );
    });
  }

  Future<SshKeyViewDto?> getViewById(String itemId) async {
    final query = db.select(db.vaultItems).join([
      innerJoin(
        db.sshKeyItems,
        db.sshKeyItems.itemId.equalsExp(db.vaultItems.id),
      ),
    ])
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.sshKey));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final sshKey = row.readTable(db.sshKeyItems);

    return SshKeyViewDto(
      item: item.toVaultItemViewDto(),
      sshKey: sshKey.toSshKeyDataDto(),
    );
  }

  Future<SshKeyCardDto?> getCardById(String itemId) async {
    final expr = _SshKeyCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.sshKey));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<SshKeyCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final expr = _SshKeyCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.sshKey))
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
    _SshKeyCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.sshKeyItems,
        db.sshKeyItems.itemId.equalsExp(db.vaultItems.id),
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

        db.sshKeyItems.publicKey,
        db.sshKeyItems.keyType,
        db.sshKeyItems.keySize,
        expr.hasPrivateKey,
      ]);
  }

  SshKeyCardDto _mapRowToCardDto(TypedResult row, _SshKeyCardExpressions expr) {
    return SshKeyCardDto(
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
      sshKey: SshKeyCardDataDto(
        publicKey: row.read(db.sshKeyItems.publicKey),
        keyType: row.readWithConverter<SshKeyType?, String>(
          db.sshKeyItems.keyType,
        ),
        keySize: row.read(db.sshKeyItems.keySize),
        hasPrivateKey: row.read(expr.hasPrivateKey) ?? false,
      ),
    );
  }
}

class _SshKeyCardExpressions {
  _SshKeyCardExpressions(this.db)
      : hasPrivateKey = db.sshKeyItems.privateKey.isNotNull();

  final MainStore db;
  final Expression<bool> hasPrivateKey;
}
