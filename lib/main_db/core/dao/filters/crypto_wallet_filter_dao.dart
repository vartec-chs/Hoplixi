import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/crypto_wallet/crypto_wallet_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'crypto_wallet_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  CryptoWalletItems,
  Categories,
  Tags,
  ItemTags,
])
class CryptoWalletFilterDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<CryptoWalletFilter, FilteredCardDto<CryptoWalletCardDto>> {
  CryptoWalletFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<CryptoWalletCardDto>>> getFiltered(
    CryptoWalletFilter filter,
  ) async {
    final query = _buildQuery(filter);
    applyLimitOffset(query, filter.base);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final categoryIds =
        rows.map((r) => r.readTable(vaultItems).categoryId).whereType<String>().toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    final hasMnemonicExpr = db.cryptoWalletItems.mnemonic.isNotNull();
    final hasPrivateKeyExpr = db.cryptoWalletItems.privateKey.isNotNull();
    final hasXprvExpr = db.cryptoWalletItems.xprv.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final wallet = row.readTable(cryptoWalletItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = CryptoWalletCardDto(
        item: VaultItemCardDto(
          itemId: item.id,
          type: item.type,
          name: item.name,
          description: item.description,
          categoryId: item.categoryId,
          iconRefId: item.iconRefId,
          isFavorite: item.isFavorite,
          isArchived: item.isArchived,
          isPinned: item.isPinned,
          isDeleted: item.isDeleted,
          createdAt: item.createdAt,
          modifiedAt: item.modifiedAt,
          lastUsedAt: item.lastUsedAt,
          archivedAt: item.archivedAt,
          deletedAt: item.deletedAt,
          recentScore: item.recentScore,
        ),
        cryptoWallet: CryptoWalletCardDataDto(
          walletType: row.readWithConverter<CryptoWalletType?, String>(cryptoWalletItems.walletType),
          network: row.readWithConverter<CryptoNetwork?, String>(cryptoWalletItems.network),
          addresses: wallet.addresses,
          xpub: wallet.xpub,
          hardwareDevice: wallet.hardwareDevice,
          watchOnly: wallet.watchOnly,
          hasMnemonic: row.read(hasMnemonicExpr) ?? false,
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
          hasXprv: row.read(hasXprvExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(CryptoWalletFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(CryptoWalletFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.cryptoWallet);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.walletType != null) {
      whereExpr &= cryptoWalletItems.walletType.equalsValue(filter.walletType!);
    }
    if (filter.network != null) {
      whereExpr &= cryptoWalletItems.network.equalsValue(filter.network!);
    }
    if (filter.derivationScheme != null) {
      whereExpr &= cryptoWalletItems.derivationScheme.equalsValue(filter.derivationScheme!);
    }
    if (filter.watchOnly != null) {
      whereExpr &= cryptoWalletItems.watchOnly.equals(filter.watchOnly!);
    }

    if (filter.hasMnemonic != null) {
      if (filter.hasMnemonic!) {
        whereExpr &= cryptoWalletItems.mnemonic.isNotNull();
      } else {
        whereExpr &= cryptoWalletItems.mnemonic.isNull();
      }
    }
    if (filter.hasPrivateKey != null) {
      if (filter.hasPrivateKey!) {
        whereExpr &= cryptoWalletItems.privateKey.isNotNull();
      } else {
        whereExpr &= cryptoWalletItems.privateKey.isNull();
      }
    }
    if (filter.hasXpub != null) {
      if (filter.hasXpub!) {
        whereExpr &= cryptoWalletItems.xpub.isNotNull();
      } else {
        whereExpr &= cryptoWalletItems.xpub.isNull();
      }
    }
    if (filter.hasXprv != null) {
      if (filter.hasXprv!) {
        whereExpr &= cryptoWalletItems.xprv.isNotNull();
      } else {
        whereExpr &= cryptoWalletItems.xprv.isNull();
      }
    }
    if (filter.hardwareDevice != null) {
      whereExpr &= cryptoWalletItems.hardwareDevice.contains(filter.hardwareDevice!);
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          cryptoWalletItems.addresses.like(q) |
          cryptoWalletItems.hardwareDevice.like(q);
      whereExpr &= textExpr;
    }

    final hasMnemonicExpr = db.cryptoWalletItems.mnemonic.isNotNull();
    final hasPrivateKeyExpr = db.cryptoWalletItems.privateKey.isNotNull();
    final hasXprvExpr = db.cryptoWalletItems.xprv.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(cryptoWalletItems, cryptoWalletItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasMnemonicExpr, hasPrivateKeyExpr, hasXprvExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case CryptoWalletSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case CryptoWalletSortField.walletType:
          orderingTerms.add(OrderingTerm(expression: cryptoWalletItems.walletType, mode: mode));
          break;
        case CryptoWalletSortField.network:
          orderingTerms.add(OrderingTerm(expression: cryptoWalletItems.network, mode: mode));
          break;
        case CryptoWalletSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case CryptoWalletSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case CryptoWalletSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case CryptoWalletSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case CryptoWalletSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
