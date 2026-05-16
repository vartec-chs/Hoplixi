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
    final whereExpr = _buildWhere(filter);
    final hasPrivateKeyExpr = certificateItems.privateKey.isNotNull();
    final hasCertificateBlobExpr =
        certificateItems.certificateBlob.isNotNull();
    final hasPrivateKeyPasswordExpr =
        certificateItems.privateKeyPassword.isNotNull();
    final hasPasswordForPfxExpr =
        certificateItems.passwordForPfx.isNotNull();
    final hasCertificatePemExpr =
        certificateItems.certificatePem.isNotNull();

    final query = selectOnly(vaultItems).join([
      innerJoin(
          certificateItems, certificateItems.itemId.equalsExp(vaultItems.id)),
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
        certificateItems.certificateFormat,
        certificateItems.keyAlgorithm,
        certificateItems.keySize,
        certificateItems.serialNumber,
        certificateItems.issuer,
        certificateItems.subject,
        certificateItems.validFrom,
        certificateItems.validTo,
        hasPrivateKeyExpr,
        hasCertificateBlobExpr,
        hasPrivateKeyPasswordExpr,
        hasPasswordForPfxExpr,
        hasCertificatePemExpr,
      ])
      ..where(whereExpr);

    applyLimitOffset(query, filter.base);

    final orderingTerms = buildBaseOrdering(filter.base);
    if (filter.sortField != null) {
      final isAsc = filter.base.sortDirection == SortDirection.asc;
      final mode = isAsc ? OrderingMode.asc : OrderingMode.desc;
      switch (filter.sortField!) {
        case CertificateSortField.name:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.name, mode: mode));
          break;
        case CertificateSortField.serialNumber:
          orderingTerms.add(OrderingTerm(
              expression: certificateItems.serialNumber, mode: mode));
          break;
        case CertificateSortField.issuer:
          orderingTerms.add(
              OrderingTerm(expression: certificateItems.issuer, mode: mode));
          break;
        case CertificateSortField.subject:
          orderingTerms.add(
              OrderingTerm(expression: certificateItems.subject, mode: mode));
          break;
        case CertificateSortField.validFrom:
          orderingTerms.add(OrderingTerm(
              expression: certificateItems.validFrom, mode: mode));
          break;
        case CertificateSortField.validTo:
          orderingTerms.add(OrderingTerm(
              expression: certificateItems.validTo, mode: mode));
          break;
        case CertificateSortField.createdAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.createdAt, mode: mode));
          break;
        case CertificateSortField.modifiedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.modifiedAt, mode: mode));
          break;
        case CertificateSortField.lastUsedAt:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.lastUsedAt, mode: mode));
          break;
        case CertificateSortField.usedCount:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.usedCount, mode: mode));
          break;
        case CertificateSortField.recentScore:
          orderingTerms.add(
              OrderingTerm(expression: vaultItems.recentScore, mode: mode));
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

      final cardDto = CertificateCardDto(
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
        certificate: CertificateCardDataDto(
          certificateFormat: row.readWithConverter<CertificateFormat?, String>(
              certificateItems.certificateFormat),
          keyAlgorithm: row.readWithConverter<CertificateKeyAlgorithm?, String>(
              certificateItems.keyAlgorithm),
          keySize: row.read(certificateItems.keySize),
          serialNumber: row.read(certificateItems.serialNumber),
          issuer: row.read(certificateItems.issuer),
          subject: row.read(certificateItems.subject),
          validFrom: row.read(certificateItems.validFrom),
          validTo: row.read(certificateItems.validTo),
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
    final whereExpr = _buildWhere(filter);
    final countExp = countAll();
    final query = selectOnly(vaultItems).join([
      innerJoin(
          certificateItems, certificateItems.itemId.equalsExp(vaultItems.id)),
    ])
      ..addColumns([countExp])
      ..where(whereExpr);

    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Expression<bool> _buildWhere(CertificateFilter filter) {
    Expression<bool> whereExpr =
        vaultItems.type.equalsValue(VaultItemType.certificate);

    whereExpr &= applyBaseVaultItemFilters(filter.base);

    if (filter.certificateFormat != null) {
      whereExpr &= certificateItems.certificateFormat
          .equalsValue(filter.certificateFormat!);
    }
    if (filter.keyAlgorithm != null) {
      whereExpr &=
          certificateItems.keyAlgorithm.equalsValue(filter.keyAlgorithm!);
    }
    if (filter.keySize != null) {
      whereExpr &= certificateItems.keySize.equals(filter.keySize!);
    }
    if (filter.serialNumber != null) {
      whereExpr &=
          certificateItems.serialNumber.contains(filter.serialNumber!);
    }
    if (filter.issuer != null) {
      whereExpr &= certificateItems.issuer.contains(filter.issuer!);
    }
    if (filter.subject != null) {
      whereExpr &= certificateItems.subject.contains(filter.subject!);
    }

    if (filter.validFromAfter != null) {
      whereExpr &= certificateItems.validFrom
          .isBiggerOrEqualValue(filter.validFromAfter!);
    }
    if (filter.validToBefore != null) {
      whereExpr &=
          certificateItems.validTo.isSmallerOrEqualValue(filter.validToBefore!);
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

    return whereExpr;
  }
}
