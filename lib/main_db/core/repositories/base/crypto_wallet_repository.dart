import 'package:drift/drift.dart';
import 'package:hoplixi/main_db/core/models/dto/dto.dart';
import 'package:hoplixi/main_db/core/tables/crypto_wallet/crypto_wallet_items.dart';
import 'package:uuid/uuid.dart';

import '../../main_store.dart';
import '../../models/mappers/crypto_wallet_mapper.dart';
import '../../models/mappers/vault_item_mapper.dart';
import '../../tables/vault_items/vault_items.dart';

class CryptoWalletRepository {
  final MainStore db;

  CryptoWalletRepository(this.db);

  Future<String> create(CreateCryptoWalletDto dto) {
    return db.transaction(() async {
      final now = DateTime.now();
      final itemId = const Uuid().v4();

      await db
          .into(db.vaultItems)
          .insert(
            VaultItemsCompanion.insert(
              id: Value(itemId),
              type: VaultItemType.cryptoWallet,
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
          .into(db.cryptoWalletItems)
          .insert(
            CryptoWalletItemsCompanion.insert(
              itemId: itemId,
              walletType: Value(dto.cryptoWallet.walletType),
              walletTypeOther: Value(dto.cryptoWallet.walletTypeOther),
              network: Value(dto.cryptoWallet.network),
              networkOther: Value(dto.cryptoWallet.networkOther),
              mnemonic: Value(dto.cryptoWallet.mnemonic),
              privateKey: Value(dto.cryptoWallet.privateKey),
              derivationPath: Value(dto.cryptoWallet.derivationPath),
              derivationScheme: Value(dto.cryptoWallet.derivationScheme),
              derivationSchemeOther: Value(
                dto.cryptoWallet.derivationSchemeOther,
              ),
              addresses: Value(dto.cryptoWallet.addresses),
              xpub: Value(dto.cryptoWallet.xpub),
              xprv: Value(dto.cryptoWallet.xprv),
              hardwareDevice: Value(dto.cryptoWallet.hardwareDevice),
              watchOnly: Value(dto.cryptoWallet.watchOnly),
            ),
          );

      return itemId;
    });
  }

  Future<void> update(PatchCryptoWalletDto dto) {
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

      await (db.update(
        db.cryptoWalletItems,
      )..where((tbl) => tbl.itemId.equals(itemId))).write(
        CryptoWalletItemsCompanion(
          walletType: dto.cryptoWallet.walletType.toNullableValue(),
          walletTypeOther: dto.cryptoWallet.walletTypeOther.toNullableValue(),
          network: dto.cryptoWallet.network.toNullableValue(),
          networkOther: dto.cryptoWallet.networkOther.toNullableValue(),
          mnemonic: dto.cryptoWallet.mnemonic.toNullableValue(),
          privateKey: dto.cryptoWallet.privateKey.toNullableValue(),
          derivationPath: dto.cryptoWallet.derivationPath.toNullableValue(),
          derivationScheme: dto.cryptoWallet.derivationScheme.toNullableValue(),
          derivationSchemeOther: dto.cryptoWallet.derivationSchemeOther
              .toNullableValue(),
          addresses: dto.cryptoWallet.addresses.toNullableValue(),
          xpub: dto.cryptoWallet.xpub.toNullableValue(),
          xprv: dto.cryptoWallet.xprv.toNullableValue(),
          hardwareDevice: dto.cryptoWallet.hardwareDevice.toNullableValue(),
          watchOnly: dto.cryptoWallet.watchOnly.toRequiredValue(),
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

  Future<CryptoWalletViewDto?> getViewById(String itemId) async {
    final query =
        db.select(db.vaultItems).join([
            innerJoin(
              db.cryptoWalletItems,
              db.cryptoWalletItems.itemId.equalsExp(db.vaultItems.id),
            ),
          ])
          ..where(db.vaultItems.id.equals(itemId))
          ..where(db.vaultItems.type.equalsValue(VaultItemType.cryptoWallet));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final item = row.readTable(db.vaultItems);
    final cryptoWallet = row.readTable(db.cryptoWalletItems);

    return CryptoWalletViewDto(
      item: item.toVaultItemViewDto(),
      cryptoWallet: cryptoWallet.toCryptoWalletDataDto(),
    );
  }

  Future<CryptoWalletCardDto?> getCardById(String itemId) async {
    final expr = _CryptoWalletCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.id.equals(itemId))
      ..where(db.vaultItems.type.equalsValue(VaultItemType.cryptoWallet));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToCardDto(row, expr);
  }

  Future<List<CryptoWalletCardDto>> getCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final expr = _CryptoWalletCardExpressions(db);
    final query = _buildCardQuery(expr)
      ..where(db.vaultItems.type.equalsValue(VaultItemType.cryptoWallet))
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
    _CryptoWalletCardExpressions expr,
  ) {
    return db.selectOnly(db.vaultItems).join([
      innerJoin(
        db.cryptoWalletItems,
        db.cryptoWalletItems.itemId.equalsExp(db.vaultItems.id),
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
      db.cryptoWalletItems.walletType,
      db.cryptoWalletItems.network,
      db.cryptoWalletItems.addresses,
      db.cryptoWalletItems.xpub,
      db.cryptoWalletItems.hardwareDevice,
      db.cryptoWalletItems.watchOnly,
      expr.hasMnemonic,
      expr.hasPrivateKey,
      expr.hasXprv,
    ]);
  }

  CryptoWalletCardDto _mapRowToCardDto(
    TypedResult row,
    _CryptoWalletCardExpressions expr,
  ) {
    return CryptoWalletCardDto(
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
      cryptoWallet: CryptoWalletCardDataDto(
        walletType: row.readWithConverter<CryptoWalletType?, String>(
          db.cryptoWalletItems.walletType,
        ),
        network: row.readWithConverter<CryptoNetwork?, String>(
          db.cryptoWalletItems.network,
        ),
        addresses: row.read(db.cryptoWalletItems.addresses),
        xpub: row.read(db.cryptoWalletItems.xpub),
        hardwareDevice: row.read(db.cryptoWalletItems.hardwareDevice),
        watchOnly: row.read(db.cryptoWalletItems.watchOnly)!,
        hasMnemonic: row.read(expr.hasMnemonic) ?? false,
        hasPrivateKey: row.read(expr.hasPrivateKey) ?? false,
        hasXprv: row.read(expr.hasXprv) ?? false,
      ),
    );
  }
}

class _CryptoWalletCardExpressions {
  _CryptoWalletCardExpressions(this.db)
    : hasMnemonic = db.cryptoWalletItems.mnemonic.isNotNull(),
      hasPrivateKey = db.cryptoWalletItems.privateKey.isNotNull(),
      hasXprv = db.cryptoWalletItems.xprv.isNotNull();

  final MainStore db;
  final Expression<bool> hasMnemonic;
  final Expression<bool> hasPrivateKey;
  final Expression<bool> hasXprv;
}
