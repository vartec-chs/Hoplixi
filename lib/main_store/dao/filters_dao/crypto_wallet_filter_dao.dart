import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/crypto_wallet_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/crypto_wallets_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/crypto_wallet_items.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'crypto_wallet_filter_dao.g.dart';

@DriftAccessor(
  tables: [
    VaultItems,
    CryptoWalletItems,
    Categories,
    Tags,
    ItemTags,
    NoteItems,
  ],
)
class CryptoWalletFilterDao extends DatabaseAccessor<MainStore>
    with _$CryptoWalletFilterDaoMixin
    implements FilterDao<CryptoWalletsFilter, CryptoWalletCardDto> {
  CryptoWalletFilterDao(super.db);

  @override
  Future<List<CryptoWalletCardDto>> getFiltered(
    CryptoWalletsFilter filter,
  ) async {
    final query = select(vaultItems).join([
      innerJoin(
        cryptoWalletItems,
        cryptoWalletItems.itemId.equalsExp(vaultItems.id),
      ),
      leftOuterJoin(categories, categories.id.equalsExp(vaultItems.categoryId)),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final rows = await query.get();
    final itemIds = rows.map((r) => r.readTable(vaultItems).id).toList();
    final tagsMap = await _loadTagsForItems(itemIds);

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final wallet = row.readTable(cryptoWalletItems);
      final category = row.readTableOrNull(categories);

      return CryptoWalletCardDto(
        id: item.id,
        name: item.name,
        walletType: wallet.walletType,
        network: wallet.network,
        derivationPath: wallet.derivationPath,
        hardwareDevice: wallet.hardwareDevice,
        lastBalanceCheckedAt: wallet.lastBalanceCheckedAt,
        watchOnly: wallet.watchOnly,
        hasMnemonic: wallet.mnemonic != null && wallet.mnemonic!.isNotEmpty,
        hasPrivateKey:
            wallet.privateKey != null && wallet.privateKey!.isNotEmpty,
        hasXpub: wallet.xpub != null && wallet.xpub!.isNotEmpty,
        hasXprv: wallet.xprv != null && wallet.xprv!.isNotEmpty,
        description: item.description,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[item.id] ?? [],
        isFavorite: item.isFavorite,
        isPinned: item.isPinned,
        isArchived: item.isArchived,
        isDeleted: item.isDeleted,
        usedCount: item.usedCount,
        modifiedAt: item.modifiedAt,
        createdAt: item.createdAt,
      );
    }).toList();
  }

  @override
  Future<int> countFiltered(CryptoWalletsFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(
        cryptoWalletItems,
        cryptoWalletItems.itemId.equalsExp(vaultItems.id),
      ),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(CryptoWalletsFilter filter) {
    Expression<bool> expr = const Constant(true);
    expr = expr & _applyBaseFilters(filter.base);
    expr = expr & _applySpecificFilters(filter);
    return expr;
  }

  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expr = const Constant(true);

    if (base.isDeleted == null) {
      expr = expr & vaultItems.isDeleted.equals(false);
    }

    if (base.query.isNotEmpty) {
      final q = base.query.toLowerCase();
      expr =
          expr &
          (vaultItems.name.lower().like('%$q%') |
              cryptoWalletItems.walletType.lower().like('%$q%') |
              cryptoWalletItems.network.lower().like('%$q%') |
              cryptoWalletItems.hardwareDevice.lower().like('%$q%') |
              cryptoWalletItems.derivationPath.lower().like('%$q%') |
              vaultItems.description.lower().like('%$q%') |
              noteItems.content.lower().like('%$q%'));
    }

    if (base.categoryIds.isNotEmpty) {
      expr = expr & vaultItems.categoryId.isIn(base.categoryIds);
    }

    if (base.tagIds.isNotEmpty) {
      final tagExists = existsQuery(
        select(itemTags)..where(
          (t) => t.itemId.equalsExp(vaultItems.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expr = expr & tagExists;
    }

    if (base.isFavorite != null) {
      expr = expr & vaultItems.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expr = expr & vaultItems.isArchived.equals(base.isArchived!);
    } else {
      expr = expr & vaultItems.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expr = expr & vaultItems.isDeleted.equals(base.isDeleted!);
    }

    return expr;
  }

  Expression<bool> _applySpecificFilters(CryptoWalletsFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.walletType != null) {
      expr =
          expr &
          cryptoWalletItems.walletType.lower().like(
            '%${filter.walletType!.toLowerCase()}%',
          );
    }

    if (filter.network != null) {
      expr =
          expr &
          cryptoWalletItems.network.lower().like(
            '%${filter.network!.toLowerCase()}%',
          );
    }

    if (filter.hardwareDevice != null) {
      expr =
          expr &
          cryptoWalletItems.hardwareDevice.lower().like(
            '%${filter.hardwareDevice!.toLowerCase()}%',
          );
    }

    if (filter.watchOnly != null) {
      expr = expr & cryptoWalletItems.watchOnly.equals(filter.watchOnly!);
    }

    if (filter.hasMnemonic != null) {
      expr =
          expr &
          (filter.hasMnemonic!
              ? (cryptoWalletItems.mnemonic.isNotNull() &
                    cryptoWalletItems.mnemonic.isBiggerThanValue(''))
              : (cryptoWalletItems.mnemonic.isNull() |
                    cryptoWalletItems.mnemonic.equals('')));
    }

    if (filter.hasPrivateKey != null) {
      expr =
          expr &
          (filter.hasPrivateKey!
              ? (cryptoWalletItems.privateKey.isNotNull() &
                    cryptoWalletItems.privateKey.isBiggerThanValue(''))
              : (cryptoWalletItems.privateKey.isNull() |
                    cryptoWalletItems.privateKey.equals('')));
    }

    if (filter.hasXprv != null) {
      expr =
          expr &
          (filter.hasXprv!
              ? (cryptoWalletItems.xprv.isNotNull() &
                    cryptoWalletItems.xprv.isBiggerThanValue(''))
              : (cryptoWalletItems.xprv.isNull() |
                    cryptoWalletItems.xprv.equals('')));
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(CryptoWalletsFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case CryptoWalletsSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case CryptoWalletsSortField.walletType:
        terms.add(
          OrderingTerm(expression: cryptoWalletItems.walletType, mode: mode),
        );
      case CryptoWalletsSortField.network:
        terms.add(
          OrderingTerm(expression: cryptoWalletItems.network, mode: mode),
        );
      case CryptoWalletsSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case CryptoWalletsSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case CryptoWalletsSortField.lastAccessed:
        terms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
      case null:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
    }

    return terms;
  }

  Future<Map<String, List<TagInCardDto>>> _loadTagsForItems(
    List<String> itemIds,
  ) async {
    if (itemIds.isEmpty) return {};

    final query = select(itemTags).join([
      innerJoin(tags, tags.id.equalsExp(itemTags.tagId)),
    ])..where(itemTags.itemId.isIn(itemIds));

    final rows = await query.get();
    final tagsMap = <String, List<TagInCardDto>>{};

    for (final row in rows) {
      final it = row.readTable(itemTags);
      final tag = row.readTable(tags);
      final list = tagsMap.putIfAbsent(it.itemId, () => []);
      if (list.length < 10) {
        list.add(TagInCardDto(id: tag.id, name: tag.name, color: tag.color));
      }
    }

    return tagsMap;
  }
}
