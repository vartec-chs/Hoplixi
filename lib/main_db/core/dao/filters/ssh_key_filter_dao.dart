import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/ssh_key/ssh_key_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'ssh_key_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  SshKeyItems,
  Categories,
  Tags,
  ItemTags,
])
class SshKeyFilterDao extends DatabaseAccessor<MainStore>
    with _$SshKeyFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<SshKeyFilter, FilteredCardDto<SshKeyCardDto>> {
  SshKeyFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<SshKeyCardDto>>> getFiltered(
    SshKeyFilter filter,
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

    final hasPrivateKeyExpr = db.sshKeyItems.privateKey.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final ssh = row.readTable(sshKeyItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = SshKeyCardDto(
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
        sshKey: SshKeyCardDataDto(
          publicKey: ssh.publicKey,
          keyType: row.readWithConverter<SshKeyType?, String>(sshKeyItems.keyType),
          keySize: ssh.keySize,
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(SshKeyFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(SshKeyFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.sshKey);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.keyType != null) {
      whereExpr &= sshKeyItems.keyType.equalsValue(filter.keyType!);
    }
    if (filter.keySize != null) {
      whereExpr &= sshKeyItems.keySize.equals(filter.keySize!);
    }

    if (filter.hasPublicKey != null) {
      if (filter.hasPublicKey!) {
        whereExpr &= sshKeyItems.publicKey.isNotNull();
      } else {
        whereExpr &= sshKeyItems.publicKey.isNull();
      }
    }
    if (filter.hasPrivateKey != null) {
      if (filter.hasPrivateKey!) {
        whereExpr &= sshKeyItems.privateKey.isNotNull();
      } else {
        whereExpr &= sshKeyItems.privateKey.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q);
      whereExpr &= textExpr;
    }

    final hasPrivateKeyExpr = db.sshKeyItems.privateKey.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(sshKeyItems, sshKeyItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([hasPrivateKeyExpr]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case SshKeySortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case SshKeySortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case SshKeySortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case SshKeySortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case SshKeySortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case SshKeySortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
