import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/documents_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'document_filter_dao.g.dart';

@DriftAccessor(tables: [Documents, Categories, DocumentsTags, Tags])
class DocumentFilterDao extends DatabaseAccessor<MainStore>
    with _$DocumentFilterDaoMixin
    implements FilterDao<DocumentsFilter, DocumentCardDto> {
  DocumentFilterDao(super.db);

  /// Получить отфильтрованные документы
  @override
  Future<List<DocumentCardDto>> getFiltered(DocumentsFilter filter) async {
    final query = select(documents).join([
      leftOuterJoin(categories, categories.id.equalsExp(documents.categoryId)),
    ]);

    final whereExpression = _buildWhereExpression(filter);
    if (whereExpression != null) {
      query.where(whereExpression);
    }

    query.orderBy(_buildOrderBy(filter));

    if (filter.base.limit != null) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    final results = await query.get();

    // Собираем ID всех документов для загрузки тегов
    final documentIds = results
        .map((row) => row.readTable(documents).id)
        .toList();

    // Загружаем теги для всех документов (максимум 10 на документ)
    final tagsMap = await _loadTagsForDocuments(documentIds);

    return results.map((row) {
      final document = row.readTable(documents);
      final category = row.readTableOrNull(categories);

      // Получаем теги для текущего документа
      final documentTags = tagsMap[document.id] ?? [];

      return DocumentCardDto(
        id: document.id,
        title: document.title,
        documentType: document.documentType,
        description: document.description,
        pageCount: document.pageCount,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: documentTags,
        isFavorite: document.isFavorite,
        isArchived: document.isArchived,
        isPinned: document.isPinned,
        isDeleted: document.isDeleted,
        usedCount: document.usedCount,
        modifiedAt: document.modifiedAt,
      );
    }).toList();
  }

  /// Подсчитывает количество отфильтрованных документов
  @override
  Future<int> countFiltered(DocumentsFilter filter) async {
    // Создаем запрос для подсчета с join
    final query = select(documents).join([
      leftOuterJoin(categories, categories.id.equalsExp(documents.categoryId)),
    ]);

    // Применяем те же фильтры
    final whereExpression = _buildWhereExpression(filter);
    if (whereExpression != null) {
      query.where(whereExpression);
    }

    // Выполняем запрос и считаем
    final results = await query.get();
    return results.length;
  }

  /// Построить WHERE выражение на основе фильтра
  Expression<bool>? _buildWhereExpression(DocumentsFilter filter) {
    final expressions = <Expression<bool>>[];

    // Применяем базовые фильтры
    _applyBaseFilters(filter.base, expressions);

    // Применяем специфичные для документов фильтры
    _applyDocumentSpecificFilters(filter, expressions);

    if (expressions.isEmpty) return null;

    return expressions.reduce((a, b) => a & b);
  }

  /// Применить базовые фильтры из BaseFilter
  void _applyBaseFilters(BaseFilter base, List<Expression<bool>> expressions) {
    // Фильтр по поисковому запросу
    if (base.query.isNotEmpty) {
      final queryLower = base.query.toLowerCase();
      Expression<bool> searchExpression =
          documents.title.lower().like('%$queryLower%') |
          documents.description.lower().like('%$queryLower%') |
          documents.aggregatedText.lower().like('%$queryLower%');
      expressions.add(searchExpression);
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expressions.add(documents.categoryId.isIn(base.categoryIds));
    }

    // Фильтр по тегам (EXISTS subquery)
    if (base.tagIds.isNotEmpty) {
      final tagFilter = existsQuery(
        select(documentsTags)..where(
          (row) =>
              row.documentId.equalsExp(documents.id) &
              row.tagId.isIn(base.tagIds),
        ),
      );
      expressions.add(tagFilter);
    }

    // Фильтр по дате создания
    if (base.createdAfter != null) {
      expressions.add(
        documents.createdAt.isBiggerOrEqualValue(base.createdAfter!),
      );
    }
    if (base.createdBefore != null) {
      expressions.add(
        documents.createdAt.isSmallerOrEqualValue(base.createdBefore!),
      );
    }

    // Фильтр по дате модификации
    if (base.modifiedAfter != null) {
      expressions.add(
        documents.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!),
      );
    }
    if (base.modifiedBefore != null) {
      expressions.add(
        documents.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!),
      );
    }

    // Фильтр по дате последнего доступа
    if (base.lastUsedAfter != null) {
      expressions.add(
        documents.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!),
      );
    }
    if (base.lastUsedBefore != null) {
      expressions.add(
        documents.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!),
      );
    }

    // Фильтр по избранным
    if (base.isFavorite != null) {
      expressions.add(documents.isFavorite.equals(base.isFavorite!));
    }

    // Фильтр по закрепленным
    if (base.isPinned != null) {
      expressions.add(documents.isPinned.equals(base.isPinned!));
    }

    // Фильтр по архивным
    if (base.isArchived != null) {
      expressions.add(documents.isArchived.equals(base.isArchived!));
    } else {
      // По умолчанию исключаем архивные
      expressions.add(documents.isArchived.equals(false));
    }

    // Фильтр по удаленным
    if (base.isDeleted != null) {
      expressions.add(documents.isDeleted.equals(base.isDeleted!));
    } else {
      // По умолчанию исключаем удаленные
      expressions.add(documents.isDeleted.equals(false));
    }
  }

  /// Применить фильтры, специфичные для документов
  void _applyDocumentSpecificFilters(
    DocumentsFilter filter,
    List<Expression<bool>> expressions,
  ) {
    // Фильтр по типам документов
    if (filter.documentTypes.isNotEmpty) {
      Expression<bool>? typeExpression;
      for (final type in filter.documentTypes) {
        final condition = documents.documentType.lower().equals(type);
        if (typeExpression == null) {
          typeExpression = condition;
        } else {
          typeExpression = typeExpression | condition;
        }
      }
      if (typeExpression != null) {
        expressions.add(typeExpression);
      }
    }

    // Фильтр по названию документа
    if (filter.titleQuery != null && filter.titleQuery!.isNotEmpty) {
      final titleLower = filter.titleQuery!.toLowerCase();
      expressions.add(documents.title.lower().like('%$titleLower%'));
    }

    // Фильтр по описанию
    if (filter.descriptionQuery != null &&
        filter.descriptionQuery!.isNotEmpty) {
      final descriptionLower = filter.descriptionQuery!.toLowerCase();
      expressions.add(
        documents.description.lower().like('%$descriptionLower%'),
      );
    }

    // Фильтр по агрегированному тексту (OCR)
    if (filter.aggregatedTextQuery != null &&
        filter.aggregatedTextQuery!.isNotEmpty) {
      final textLower = filter.aggregatedTextQuery!.toLowerCase();
      expressions.add(documents.aggregatedText.lower().like('%$textLower%'));
    }

    // Фильтр по минимальному количеству страниц
    if (filter.minPageCount != null) {
      expressions.add(
        documents.pageCount.isBiggerOrEqualValue(filter.minPageCount!),
      );
    }

    // Фильтр по максимальному количеству страниц
    if (filter.maxPageCount != null) {
      expressions.add(
        documents.pageCount.isSmallerOrEqualValue(filter.maxPageCount!),
      );
    }
  }

  /// Вычисляет динамический score для сортировки по активности
  /// Формула: recent_score * exp(-(current_time - last_used_at) / window_days)
  Expression<double> _calculateDynamicScore(int windowDays) {
    final now = DateTime.now();
    final nowSeconds = now.millisecondsSinceEpoch ~/ 1000; // в секундах
    final windowSeconds = windowDays * 24 * 60 * 60;

    // Строим всё выражение как единый CustomExpression
    // recent_score * exp(-(now - last_used_at) / window_seconds)
    // Drift хранит DateTime как Unix timestamp в секундах
    // Если last_used_at == null, используем created_at
    return CustomExpression<double>(
      'CAST(COALESCE("documents"."recent_score", 1) AS REAL) * '
      'exp(-($nowSeconds - COALESCE("documents"."last_used_at", "documents"."created_at")) / $windowSeconds.0)',
    );
  }

  /// Построить ORDER BY выражение
  List<OrderingTerm> _buildOrderBy(DocumentsFilter filter) {
    final orderTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderTerms.add(
      OrderingTerm(expression: documents.isPinned, mode: OrderingMode.desc),
    );

    // Сортировка
    final sortDirection = filter.base.sortDirection;
    final mode = sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    // Если установлен фильтр по часто используемым, применяем динамическую сортировку
    if (filter.base.isFrequentlyUsed == true) {
      final windowDays = filter.base.frequencyWindowDays ?? 7;
      final scoreExpr = _calculateDynamicScore(windowDays);
      orderTerms.add(OrderingTerm(expression: scoreExpr, mode: mode));
      return orderTerms;
    }

    if (filter.sortField != null) {
      // Используем специфичное поле для документов
      switch (filter.sortField!) {
        case DocumentsSortField.title:
          orderTerms.add(OrderingTerm(expression: documents.title, mode: mode));
        case DocumentsSortField.documentType:
          orderTerms.add(
            OrderingTerm(expression: documents.documentType, mode: mode),
          );
        case DocumentsSortField.pageCount:
          orderTerms.add(
            OrderingTerm(expression: documents.pageCount, mode: mode),
          );
        case DocumentsSortField.createdAt:
          orderTerms.add(
            OrderingTerm(expression: documents.createdAt, mode: mode),
          );
        case DocumentsSortField.modifiedAt:
          orderTerms.add(
            OrderingTerm(expression: documents.modifiedAt, mode: mode),
          );
        case DocumentsSortField.lastUsedAt:
          orderTerms.add(
            OrderingTerm(expression: documents.lastUsedAt, mode: mode),
          );
      }
    } else {
      // Используем базовый sortBy из BaseFilter
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          orderTerms.add(
            OrderingTerm(expression: documents.createdAt, mode: mode),
          );
        case SortBy.modifiedAt:
          orderTerms.add(
            OrderingTerm(expression: documents.modifiedAt, mode: mode),
          );
        case SortBy.lastUsedAt:
          orderTerms.add(
            OrderingTerm(expression: documents.lastUsedAt, mode: mode),
          );
        case SortBy.recentScore:
          orderTerms.add(
            OrderingTerm(expression: documents.recentScore, mode: mode),
          );
      }
    }

    return orderTerms;
  }

  /// Загружает теги для списка документов (максимум 10 тегов на документ)
  Future<Map<String, List<TagInCardDto>>> _loadTagsForDocuments(
    List<String> documentIds,
  ) async {
    if (documentIds.isEmpty) return {};

    // Запрос для получения тегов со связями
    final query = select(documentsTags).join([
      innerJoin(tags, tags.id.equalsExp(documentsTags.tagId)),
    ])..where(documentsTags.documentId.isIn(documentIds));

    // Группируем теги по documentId
    final tagsMap = <String, List<TagInCardDto>>{};

    // Обрабатываем результаты
    final results = await query.get();

    for (final row in results) {
      final documentTag = row.readTable(documentsTags);
      final tag = row.readTable(tags);

      final documentId = documentTag.documentId;

      if (!tagsMap.containsKey(documentId)) {
        tagsMap[documentId] = [];
      }

      // Ограничиваем максимум 10 тегами
      if (tagsMap[documentId]!.length < 10) {
        tagsMap[documentId]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }

    return tagsMap;
  }
}
