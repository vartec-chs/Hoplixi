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

@DriftAccessor(
  tables: [VaultItems, CryptoWalletItems, Categories, Tags, ItemTags],
)
class CryptoWalletFilterDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletFilterDaoMixin, BaseFilterQueryMixin
    implements
        FilterDao<CryptoWalletFilter, FilteredCardDto<CryptoWalletCardDto>> {
  CryptoWalletFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<CryptoWalletCardDto>>> getFiltered(
    CryptoWalletFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasMnemonicExpr = cryptoWalletItems.mnemonic.isNotNull();
    final hasPrivateKeyExpr = cryptoWalletItems.privateKey.isNotNull();
    final hasXprvExpr = cryptoWalletItems.xprv.isNotNull();

    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              cryptoWalletItems,
              cryptoWalletItems.itemId.equalsExp(vaultItems.id),
            ),
          ])
          ..addColumns([
            vaultItems.id,
            vaultItems.type,
            vaultItems.name,
            vaultItems.description,
            vaultItems.categoryId,
            vaultItems.iconRefId,
            vaultItems.isFavorite,
            vaultItems.isArchived,
            vaultItems.isPinned,
            vaultItems.isDeleted,
            vaultItems.createdAt,
            vaultItems.modifiedAt,
            vaultItems.lastUsedAt,
            vaultItems.archivedAt,
            vaultItems.deletedAt,
            vaultItems.recentScore,
            cryptoWalletItems.walletType,
            cryptoWalletItems.network,
            cryptoWalletItems.addresses,
            cryptoWalletItems.xpub,
            cryptoWalletItems.hardwareDevice,
            cryptoWalletItems.watchOnly,
            hasMnemonicExpr,
            hasPrivateKeyExpr,
            hasXprvExpr,
          ])
          ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case CryptoWalletSortField.name:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.name, mode: mode),
          );
          break;
        case CryptoWalletSortField.walletType:
          orderingTerms.add(
            OrderingTerm(expression: cryptoWalletItems.walletType, mode: mode),
          );
          break;
        case CryptoWalletSortField.network:
          orderingTerms.add(
            OrderingTerm(expression: cryptoWalletItems.network, mode: mode),
          );
          break;
        case CryptoWalletSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.createdAt, mode: mode),
          );
          break;
        case CryptoWalletSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
          break;
        case CryptoWalletSortField.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
          break;
        case CryptoWalletSortField.usedCount:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.usedCount, mode: mode),
          );
          break;
        case CryptoWalletSortField.recentScore:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.recentScore, mode: mode),
          );
          break;
      }
    }
    query.orderBy(orderingTerms);

    final rows = await query.get();
    if (rows.isEmpty) return [];

    final itemIds = rows.map((r) => r.read(vaultItems.id)!).toList();
    final categoryIds = rows
        .map((r) => r.read(vaultItems.categoryId))
        .whereType<String>()
        .toList();

    final categoriesMap = await loadCategoriesForItems(categoryIds);
    final tagsMap = await loadTagsForItems(itemIds);

    return rows.map((row) {
      final itemId = row.read(vaultItems.id)!;
      final categoryId = row.read(vaultItems.categoryId);
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[itemId] ?? const [],
      );

      final cardDto = CryptoWalletCardDto(
        item: VaultItemCardDto(
          itemId: itemId,
          type: row.readWithConverter<VaultItemType, String>(vaultItems.type)!,
          name: row.read(vaultItems.name)!,
          description: row.read(vaultItems.description),
          categoryId: categoryId,
          iconRefId: row.read(vaultItems.iconRefId),
          isFavorite: row.read(vaultItems.isFavorite)!,
          isArchived: row.read(vaultItems.isArchived)!,
          isPinned: row.read(vaultItems.isPinned)!,
          isDeleted: row.read(vaultItems.isDeleted)!,
          createdAt: row.read(vaultItems.createdAt)!,
          modifiedAt: row.read(vaultItems.modifiedAt)!,
          lastUsedAt: row.read(vaultItems.lastUsedAt),
          archivedAt: row.read(vaultItems.archivedAt),
          deletedAt: row.read(vaultItems.deletedAt),
          recentScore: row.read(vaultItems.recentScore),
        ),
        cryptoWallet: CryptoWalletCardDataDto(
          walletType: row.readWithConverter<CryptoWalletType?, String>(
            cryptoWalletItems.walletType,
          ),
          network: row.readWithConverter<CryptoNetwork?, String>(
            cryptoWalletItems.network,
          ),
          addresses: row.read(cryptoWalletItems.addresses),
          xpub: row.read(cryptoWalletItems.xpub),
          hardwareDevice: row.read(cryptoWalletItems.hardwareDevice),
          watchOnly: row.read(cryptoWalletItems.watchOnly) ?? false,
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
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query =
        selectOnly(vaultItems).join([
            innerJoin(
              cryptoWalletItems,
              cryptoWalletItems.itemId.equalsExp(vaultItems.id),
            ),
          ])
          ..addColumns([countExp])
          ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(CryptoWalletFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(
      VaultItemType.cryptoWallet,
    );

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.walletType != null) {
      whereExpr &= cryptoWalletItems.walletType.equalsValue(filter.walletType!);
    }
    if (filter.network != null) {
      whereExpr &= cryptoWalletItems.network.equalsValue(filter.network!);
    }
    if (filter.derivationScheme != null) {
      whereExpr &= cryptoWalletItems.derivationScheme.equalsValue(
        filter.derivationScheme!,
      );
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
      whereExpr &= cryptoWalletItems.hardwareDevice.contains(
        filter.hardwareDevice!,
      );
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr =
          vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          cryptoWalletItems.addresses.like(q) |
          cryptoWalletItems.hardwareDevice.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
