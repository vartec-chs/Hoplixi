import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/crypto_wallet_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/crypto_wallet_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'crypto_wallet_dao.g.dart';

@DriftAccessor(tables: [VaultItems, CryptoWalletItems])
class CryptoWalletDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletDaoMixin
    implements BaseMainEntityDao {
  CryptoWalletDao(super.db);

  Future<List<(VaultItemsData, CryptoWalletItemsData)>>
  getAllCryptoWallets() async {
    final query = select(vaultItems).join([
      innerJoin(
        cryptoWalletItems,
        cryptoWalletItems.itemId.equalsExp(vaultItems.id),
      ),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) =>
              (row.readTable(vaultItems), row.readTable(cryptoWalletItems)),
        )
        .toList();
  }

  Future<(VaultItemsData, CryptoWalletItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(
        cryptoWalletItems,
        cryptoWalletItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(cryptoWalletItems));
  }

  Stream<List<(VaultItemsData, CryptoWalletItemsData)>>
  watchAllCryptoWallets() {
    final query = select(vaultItems).join([
      innerJoin(
        cryptoWalletItems,
        cryptoWalletItems.itemId.equalsExp(vaultItems.id),
      ),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) =>
                (row.readTable(vaultItems), row.readTable(cryptoWalletItems)),
          )
          .toList(),
    );
  }

  Future<String> createCryptoWallet(CreateCryptoWalletDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.cryptoWallet,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(cryptoWalletItems).insert(
        CryptoWalletItemsCompanion.insert(
          itemId: id,
          walletType: dto.walletType,
          mnemonic: Value(dto.mnemonic),
          privateKey: Value(dto.privateKey),
          derivationPath: Value(dto.derivationPath),
          network: Value(dto.network),
          addresses: Value(dto.addresses),
          xpub: Value(dto.xpub),
          xprv: Value(dto.xprv),
          hardwareDevice: Value(dto.hardwareDevice),
          lastBalanceCheckedAt: Value(dto.lastBalanceCheckedAt),
          notesOnUsage: Value(dto.notesOnUsage),
          watchOnly: Value(dto.watchOnly ?? false),
          derivationScheme: Value(dto.derivationScheme),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateCryptoWallet(String id, UpdateCryptoWalletDto dto) {
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

      final itemCompanion = CryptoWalletItemsCompanion(
        walletType: dto.walletType != null
            ? Value(dto.walletType!)
            : const Value.absent(),
        mnemonic: Value(dto.mnemonic),
        privateKey: Value(dto.privateKey),
        derivationPath: Value(dto.derivationPath),
        network: Value(dto.network),
        addresses: Value(dto.addresses),
        xpub: Value(dto.xpub),
        xprv: Value(dto.xprv),
        hardwareDevice: Value(dto.hardwareDevice),
        lastBalanceCheckedAt: Value(dto.lastBalanceCheckedAt),
        notesOnUsage: Value(dto.notesOnUsage),
        watchOnly: dto.watchOnly != null
            ? Value(dto.watchOnly!)
            : const Value.absent(),
        derivationScheme: Value(dto.derivationScheme),
      );

      await (update(
        cryptoWalletItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  Future<String?> getMnemonicFieldById(String id) async {
    final query = selectOnly(cryptoWalletItems)
      ..addColumns([cryptoWalletItems.mnemonic])
      ..where(cryptoWalletItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(cryptoWalletItems.mnemonic);
  }

  Future<String?> getPrivateKeyFieldById(String id) async {
    final query = selectOnly(cryptoWalletItems)
      ..addColumns([cryptoWalletItems.privateKey])
      ..where(cryptoWalletItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(cryptoWalletItems.privateKey);
  }

  Future<String?> getXprvFieldById(String id) async {
    final query = selectOnly(cryptoWalletItems)
      ..addColumns([cryptoWalletItems.xprv])
      ..where(cryptoWalletItems.itemId.equals(id));

    final result = await query.getSingleOrNull();
    return result?.read(cryptoWalletItems.xprv);
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
