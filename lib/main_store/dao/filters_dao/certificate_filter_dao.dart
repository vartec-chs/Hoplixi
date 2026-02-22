import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/certificate_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/certificates_filter.dart';
import 'package:hoplixi/main_store/tables/categories.dart';
import 'package:hoplixi/main_store/tables/certificate_items.dart';
import 'package:hoplixi/main_store/tables/item_tags.dart';
import 'package:hoplixi/main_store/tables/note_items.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';

part 'certificate_filter_dao.g.dart';

@DriftAccessor(
  tables: [VaultItems, CertificateItems, Categories, Tags, ItemTags, NoteItems],
)
class CertificateFilterDao extends DatabaseAccessor<MainStore>
    with _$CertificateFilterDaoMixin
    implements FilterDao<CertificatesFilter, CertificateCardDto> {
  CertificateFilterDao(super.db);

  @override
  Future<List<CertificateCardDto>> getFiltered(
    CertificatesFilter filter,
  ) async {
    final query = select(vaultItems).join([
      innerJoin(
        certificateItems,
        certificateItems.itemId.equalsExp(vaultItems.id),
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
      final cert = row.readTable(certificateItems);
      final category = row.readTableOrNull(categories);

      return CertificateCardDto(
        id: item.id,
        name: item.name,
        serialNumber: cert.serialNumber,
        issuer: cert.issuer,
        subject: cert.subject,
        validFrom: cert.validFrom,
        validTo: cert.validTo,
        fingerprint: cert.fingerprint,
        hasPrivateKey: cert.privateKey != null && cert.privateKey!.isNotEmpty,
        hasPfx: cert.pfxBlob != null && cert.pfxBlob!.isNotEmpty,
        autoRenew: cert.autoRenew,
        lastCheckedAt: cert.lastCheckedAt,
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
  Future<int> countFiltered(CertificatesFilter filter) async {
    final query = select(vaultItems).join([
      innerJoin(
        certificateItems,
        certificateItems.itemId.equalsExp(vaultItems.id),
      ),
      leftOuterJoin(noteItems, noteItems.itemId.equalsExp(vaultItems.noteId)),
    ]);

    query.where(_buildWhereExpression(filter));
    final rows = await query.get();
    return rows.length;
  }

  Expression<bool> _buildWhereExpression(CertificatesFilter filter) {
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
              certificateItems.issuer.lower().like('%$q%') |
              certificateItems.subject.lower().like('%$q%') |
              certificateItems.serialNumber.lower().like('%$q%') |
              certificateItems.fingerprint.lower().like('%$q%') |
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

  Expression<bool> _applySpecificFilters(CertificatesFilter filter) {
    Expression<bool> expr = const Constant(true);

    if (filter.name != null) {
      expr =
          expr &
          vaultItems.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    if (filter.issuer != null) {
      expr =
          expr &
          certificateItems.issuer.lower().like(
            '%${filter.issuer!.toLowerCase()}%',
          );
    }

    if (filter.subject != null) {
      expr =
          expr &
          certificateItems.subject.lower().like(
            '%${filter.subject!.toLowerCase()}%',
          );
    }

    if (filter.serialNumber != null) {
      expr =
          expr &
          certificateItems.serialNumber.lower().like(
            '%${filter.serialNumber!.toLowerCase()}%',
          );
    }

    if (filter.fingerprint != null) {
      expr =
          expr &
          certificateItems.fingerprint.lower().like(
            '%${filter.fingerprint!.toLowerCase()}%',
          );
    }

    if (filter.hasPrivateKey != null) {
      expr =
          expr &
          (filter.hasPrivateKey!
              ? (certificateItems.privateKey.isNotNull() &
                    certificateItems.privateKey.isBiggerThanValue(''))
              : (certificateItems.privateKey.isNull() |
                    certificateItems.privateKey.equals('')));
    }

    if (filter.hasPfx != null) {
      expr =
          expr &
          (filter.hasPfx!
              ? certificateItems.pfxBlob.isNotNull()
              : certificateItems.pfxBlob.isNull());
    }

    if (filter.autoRenew != null) {
      expr = expr & certificateItems.autoRenew.equals(filter.autoRenew!);
    }

    if (filter.isExpired != null) {
      final now = DateTime.now();
      expr =
          expr &
          (filter.isExpired!
              ? (certificateItems.validTo.isNotNull() &
                    certificateItems.validTo.isSmallerThanValue(now))
              : (certificateItems.validTo.isNull() |
                    certificateItems.validTo.isBiggerOrEqualValue(now)));
    }

    return expr;
  }

  List<OrderingTerm> _buildOrderBy(CertificatesFilter filter) {
    final terms = <OrderingTerm>[
      OrderingTerm(expression: vaultItems.isPinned, mode: OrderingMode.desc),
    ];

    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    switch (filter.sortField) {
      case CertificatesSortField.name:
        terms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
      case CertificatesSortField.issuer:
        terms.add(
          OrderingTerm(expression: certificateItems.issuer, mode: mode),
        );
      case CertificatesSortField.subject:
        terms.add(
          OrderingTerm(expression: certificateItems.subject, mode: mode),
        );
      case CertificatesSortField.validTo:
        terms.add(
          OrderingTerm(expression: certificateItems.validTo, mode: mode),
        );
      case CertificatesSortField.createdAt:
        terms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
      case CertificatesSortField.modifiedAt:
        terms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
      case CertificatesSortField.lastAccessed:
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
