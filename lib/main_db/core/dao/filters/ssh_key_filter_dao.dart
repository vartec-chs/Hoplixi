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

@DriftAccessor(tables: [VaultItems, SshKeyItems, Categories, Tags, ItemTags])
class SshKeyFilterDao extends DatabaseAccessor<MainStore>
    with _$SshKeyFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<SshKeyFilter, FilteredCardDto<SshKeyCardDto>> {
  SshKeyFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<SshKeyCardDto>>> getFiltered(
    SshKeyFilter filter,
  ) async {
    final whereExpr = _buildWhere(filter);
    final hasPrivateKeyExpr = sshKeyItems.privateKey.isNotNull();

    final query =
        selectOnly(vaultItems).join([
            innerJoin(sshKeyItems, sshKeyItems.itemId.equalsExp(vaultItems.id)),
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
            sshKeyItems.publicKey,
            sshKeyItems.keyType,
            sshKeyItems.keySize,
            hasPrivateKeyExpr,
          ])
          ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case SshKeySortField.name:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.name, mode: mode),
          );
          break;
        case SshKeySortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.createdAt, mode: mode),
          );
          break;
        case SshKeySortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.modifiedAt, mode: mode),
          );
          break;
        case SshKeySortField.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode),
          );
          break;
        case SshKeySortField.usedCount:
          orderingTerms.add(
            OrderingTerm(expression: vaultItems.usedCount, mode: mode),
          );
          break;
        case SshKeySortField.recentScore:
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

      final cardDto = SshKeyCardDto(
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
        sshKey: SshKeyCardDataDto(
          publicKey: row.read(sshKeyItems.publicKey),
          keyType: row.readWithConverter<SshKeyType?, String>(
            sshKeyItems.keyType,
          ),
          keySize: row.read(sshKeyItems.keySize),
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(SshKeyFilter filter) async {
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query =
        selectOnly(vaultItems).join([
            innerJoin(sshKeyItems, sshKeyItems.itemId.equalsExp(vaultItems.id)),
          ])
          ..addColumns([countExp])
          ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(SshKeyFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(
      VaultItemType.sshKey,
    );

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
      final textExpr = vaultItems.name.like(q) | vaultItems.description.like(q);
      whereExpr &= textExpr;
    }

    return whereExpr;
  }
}
