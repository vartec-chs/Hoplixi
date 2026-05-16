import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../models/dto/dto.dart';
import '../../models/filters/filters.dart';
import '../../tables/certificate/certificate_items.dart';
import '../../tables/system/categories.dart';
import '../../tables/system/item_tags.dart';
import '../../tables/system/tags.dart';
import '../../tables/vault_items/vault_items.dart';
import 'base_filter_query_mixin.dart';
import 'filter_dao.dart';

part 'certificate_filter_dao.g.dart';

@DriftAccessor(tables: [
  VaultItems,
  CertificateItems,
  Categories,
  Tags,
  ItemTags,
])
class CertificateFilterDao extends DatabaseAccessor<MainStore>
    with _$CertificateFilterDaoMixin, BaseFilterQueryMixin
    implements FilterDao<CertificateFilter, FilteredCardDto<CertificateCardDto>> {
  CertificateFilterDao(super.db);

  @override
  Future<List<FilteredCardDto<CertificateCardDto>>> getFiltered(
    CertificateFilter filter,
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

    final hasPrivateKeyExpr = db.certificateItems.privateKey.isNotNull();
    final hasCertificateBlobExpr = db.certificateItems.certificateBlob.isNotNull();
    final hasPrivateKeyPasswordExpr = db.certificateItems.privateKeyPassword.isNotNull();
    final hasPasswordForPfxExpr = db.certificateItems.passwordForPfx.isNotNull();
    final hasCertificatePemExpr = db.certificateItems.certificatePem.isNotNull();

    return rows.map((row) {
      final item = row.readTable(vaultItems);
      final cert = row.readTable(certificateItems);

      final categoryId = item.categoryId;
      final meta = VaultItemCardMetaDto(
        category: categoryId != null ? categoriesMap[categoryId] : null,
        tags: tagsMap[item.id] ?? const [],
      );

      final cardDto = CertificateCardDto(
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
        certificate: CertificateCardDataDto(
          certificateFormat: row.readWithConverter<CertificateFormat?, String>(certificateItems.certificateFormat),
          keyAlgorithm: row.readWithConverter<CertificateKeyAlgorithm?, String>(certificateItems.keyAlgorithm),
          keySize: cert.keySize,
          serialNumber: cert.serialNumber,
          issuer: cert.issuer,
          subject: cert.subject,
          validFrom: cert.validFrom,
          validTo: cert.validTo,
          hasPrivateKey: row.read(hasPrivateKeyExpr) ?? false,
          hasCertificateBlob: row.read(hasCertificateBlobExpr) ?? false,
          hasPrivateKeyPassword: row.read(hasPrivateKeyPasswordExpr) ?? false,
          hasPasswordForPfx: row.read(hasPasswordForPfxExpr) ?? false,
          hasCertificatePem: row.read(hasCertificatePemExpr) ?? false,
        ),
      );

      return FilteredCardDto(card: cardDto, meta: meta);
    }).toList();
  }

  @override
  Future<int> countFiltered(CertificateFilter filter) async {
    final query = _buildQuery(filter);
    final countExp = countAll();
    query.addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _buildQuery(CertificateFilter filter) {
    Expression<bool> whereExpr = vaultItems.type.equalsValue(VaultItemType.certificate);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.certificateFormat != null) {
      whereExpr &= certificateItems.certificateFormat.equalsValue(filter.certificateFormat!);
    }
    if (filter.keyAlgorithm != null) {
      whereExpr &= certificateItems.keyAlgorithm.equalsValue(filter.keyAlgorithm!);
    }
    if (filter.keySize != null) {
      whereExpr &= certificateItems.keySize.equals(filter.keySize!);
    }
    if (filter.serialNumber != null) {
      whereExpr &= certificateItems.serialNumber.contains(filter.serialNumber!);
    }
    if (filter.issuer != null) {
      whereExpr &= certificateItems.issuer.contains(filter.issuer!);
    }
    if (filter.subject != null) {
      whereExpr &= certificateItems.subject.contains(filter.subject!);
    }

    if (filter.validFromAfter != null) {
      whereExpr &= certificateItems.validFrom.isBiggerOrEqualValue(filter.validFromAfter!);
    }
    if (filter.validToBefore != null) {
      whereExpr &= certificateItems.validTo.isSmallerOrEqualValue(filter.validToBefore!);
    }

    if (filter.hasPrivateKey != null) {
      if (filter.hasPrivateKey!) {
        whereExpr &= certificateItems.privateKey.isNotNull();
      } else {
        whereExpr &= certificateItems.privateKey.isNull();
      }
    }
    if (filter.hasCertificateBlob != null) {
      if (filter.hasCertificateBlob!) {
        whereExpr &= certificateItems.certificateBlob.isNotNull();
      } else {
        whereExpr &= certificateItems.certificateBlob.isNull();
      }
    }
    if (filter.hasCertificatePem != null) {
      if (filter.hasCertificatePem!) {
        whereExpr &= certificateItems.certificatePem.isNotNull();
      } else {
        whereExpr &= certificateItems.certificatePem.isNull();
      }
    }

    if (filter.base.query.isNotEmpty) {
      final q = '%${filter.base.query}%';
      final textExpr = vaultItems.name.like(q) |
          vaultItems.description.like(q) |
          certificateItems.serialNumber.like(q) |
          certificateItems.issuer.like(q) |
          certificateItems.subject.like(q);
      whereExpr &= textExpr;
    }

    final hasPrivateKeyExpr = db.certificateItems.privateKey.isNotNull();
    final hasCertificateBlobExpr = db.certificateItems.certificateBlob.isNotNull();
    final hasPrivateKeyPasswordExpr = db.certificateItems.privateKeyPassword.isNotNull();
    final hasPasswordForPfxExpr = db.certificateItems.passwordForPfx.isNotNull();
    final hasCertificatePemExpr = db.certificateItems.certificatePem.isNotNull();

    final query = select(vaultItems).join([
      innerJoin(certificateItems, certificateItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..where(whereExpr)
      ..addColumns([
        hasPrivateKeyExpr,
        hasCertificateBlobExpr,
        hasPrivateKeyPasswordExpr,
        hasPasswordForPfxExpr,
        hasCertificatePemExpr,
      ]);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case CertificateSortField.name:
          orderingTerms.add(OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case CertificateSortField.serialNumber:
          orderingTerms.add(OrderingTerm(expression: certificateItems.serialNumber, mode: mode));
          break;
        case CertificateSortField.issuer:
          orderingTerms.add(OrderingTerm(expression: certificateItems.issuer, mode: mode));
          break;
        case CertificateSortField.subject:
          orderingTerms.add(OrderingTerm(expression: certificateItems.subject, mode: mode));
          break;
        case CertificateSortField.validFrom:
          orderingTerms.add(OrderingTerm(expression: certificateItems.validFrom, mode: mode));
          break;
        case CertificateSortField.validTo:
          orderingTerms.add(OrderingTerm(expression: certificateItems.validTo, mode: mode));
          break;
        case CertificateSortField.createdAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case CertificateSortField.modifiedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case CertificateSortField.lastUsedAt:
          orderingTerms.add(OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case CertificateSortField.usedCount:
          orderingTerms.add(OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case CertificateSortField.recentScore:
          orderingTerms.add(OrderingTerm(expression: vaultItems.recentScore, mode: mode));
          break;
      }
    }

    query.orderBy(orderingTerms);

    return query;
  }
}
