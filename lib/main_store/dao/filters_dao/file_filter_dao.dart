import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/file_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/files_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'file_filter_dao.g.dart';

@DriftAccessor(tables: [Files, Categories, FilesTags, Tags])
class FileFilterDao extends DatabaseAccessor<MainStore>
    with _$FileFilterDaoMixin
    implements FilterDao<FilesFilter, FileCardDto> {
  FileFilterDao(super.db);

  /// Получить отфильтрованные файлы
  @override
  Future<List<FileCardDto>> getFiltered(FilesFilter filter) async {
    final query = select(files).join([
      leftOuterJoin(categories, categories.id.equalsExp(files.categoryId)),
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

    // Собираем ID всех файлов для загрузки тегов
    final fileIds = results.map((row) => row.readTable(files).id).toList();

    // Загружаем теги для всех файлов (максимум 10 на файл)
    final tagsMap = await _loadTagsForFiles(fileIds);

    return results.map((row) {
      final file = row.readTable(files);
      final category = row.readTableOrNull(categories);

      // Получаем теги для текущего файла
      final fileTags = tagsMap[file.id] ?? [];

      return FileCardDto(
        id: file.id,
        name: file.name,
        fileName: file.fileName,
        fileExtension: file.fileExtension,
        fileSize: file.fileSize,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        isFavorite: file.isFavorite,
        isPinned: file.isPinned,
        isArchived: file.isArchived,
        isDeleted: file.isDeleted,
        usedCount: file.usedCount,
        modifiedAt: file.modifiedAt,
        tags: fileTags,
      );
    }).toList();
  }

  /// Подсчитывает количество отфильтрованных заметок
  /// Подсчитывает количество отфильтрованных файлов
  @override
  Future<int> countFiltered(FilesFilter filter) async {
    // Создаем запрос для подсчета
    final query = selectOnly(files)..addColumns([files.id.count()]);

    // Применяем те же фильтры
    if (_buildWhereExpression(filter) != null) {
      query.where(_buildWhereExpression(filter)!);
    }

    // Выполняем запрос
    final result = await query.getSingle();
    return result.read(files.id.count()) ?? 0;
  }

  /// Построить WHERE выражение на основе фильтра
  Expression<bool>? _buildWhereExpression(FilesFilter filter) {
    final expressions = <Expression<bool>>[];

    // Применяем базовые фильтры
    _applyBaseFilters(filter.base, expressions);

    // Применяем специфичные для файлов фильтры
    _applyFileSpecificFilters(filter, expressions);

    if (expressions.isEmpty) return null;

    return expressions.reduce((a, b) => a & b);
  }

  /// Применить базовые фильтры из BaseFilter
  void _applyBaseFilters(BaseFilter base, List<Expression<bool>> expressions) {
    // Фильтр по поисковому запросу
    if (base.query.isNotEmpty) {
      final queryLower = base.query.toLowerCase();
      expressions.add(
        files.name.lower().like('%$queryLower%') |
            files.fileName.lower().like('%$queryLower%') |
            files.description.lower().like('%$queryLower%'),
      );
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expressions.add(files.categoryId.isIn(base.categoryIds));
    }

    // Фильтр по тегам (EXISTS subquery)
    if (base.tagIds.isNotEmpty) {
      final tagFilter = existsQuery(
        select(filesTags)..where(
          (t) => t.fileId.equalsExp(files.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expressions.add(tagFilter);
    }

    // Фильтр по дате создания
    if (base.createdAfter != null) {
      expressions.add(files.createdAt.isBiggerOrEqualValue(base.createdAfter!));
    }
    if (base.createdBefore != null) {
      expressions.add(
        files.createdAt.isSmallerOrEqualValue(base.createdBefore!),
      );
    }

    // Фильтр по дате модификации
    if (base.modifiedAfter != null) {
      expressions.add(
        files.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!),
      );
    }
    if (base.modifiedBefore != null) {
      expressions.add(
        files.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!),
      );
    }

    // Фильтр по дате последнего доступа
    if (base.lastUsedAfter != null) {
      expressions.add(
        files.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!) |
            files.lastUsedAt.isNull(),
      );
    }
    if (base.lastUsedBefore != null) {
      expressions.add(
        files.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!) |
            files.lastUsedAt.isNull(),
      );
    }

    // Фильтр по избранным
    if (base.isFavorite != null) {
      expressions.add(files.isFavorite.equals(base.isFavorite!));
    }

    // Фильтр по закрепленным
    if (base.isPinned != null) {
      expressions.add(files.isPinned.equals(base.isPinned!));
    }

    // Фильтр по архивным
    if (base.isArchived != null) {
      expressions.add(files.isArchived.equals(base.isArchived!));
    } else {
      // По умолчанию исключаем архивные
      expressions.add(files.isArchived.equals(false));
    }

    

    // Фильтр по удаленным
    if (base.isDeleted != null) {
      expressions.add(files.isDeleted.equals(base.isDeleted!));
    } else {
      // По умолчанию исключаем удаленные
      expressions.add(files.isDeleted.equals(false));
    }
  }

  /// Применить фильтры, специфичные для файлов
  void _applyFileSpecificFilters(
    FilesFilter filter,
    List<Expression<bool>> expressions,
  ) {
    // Фильтр по расширениям файлов
    if (filter.fileExtensions.isNotEmpty) {
      Expression<bool>? extensionExpression;
      for (final ext in filter.fileExtensions) {
        final condition = files.fileExtension.lower().equals(ext.toLowerCase());
        extensionExpression = extensionExpression == null
            ? condition
            : (extensionExpression | condition);
      }
      if (extensionExpression != null) {
        expressions.add(extensionExpression);
      }
    }

    // Фильтр по MIME типам
    if (filter.mimeTypes.isNotEmpty) {
      Expression<bool>? mimeExpression;
      for (final mime in filter.mimeTypes) {
        final condition = files.mimeType.lower().equals(mime.toLowerCase());
        mimeExpression = mimeExpression == null
            ? condition
            : (mimeExpression | condition);
      }
      if (mimeExpression != null) {
        expressions.add(mimeExpression);
      }
    }

    // Фильтр по имени файла
    if (filter.fileName != null && filter.fileName!.isNotEmpty) {
      final fileNameLower = filter.fileName!.toLowerCase();
      expressions.add(files.fileName.lower().like('%$fileNameLower%'));
    }

    // Фильтр по минимальному размеру файла
    if (filter.minFileSize != null) {
      expressions.add(files.fileSize.isBiggerOrEqualValue(filter.minFileSize!));
    }

    // Фильтр по максимальному размеру файла
    if (filter.maxFileSize != null) {
      expressions.add(
        files.fileSize.isSmallerOrEqualValue(filter.maxFileSize!),
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
      'CAST(COALESCE("files"."recent_score", 1) AS REAL) * '
      'exp(-($nowSeconds - COALESCE("files"."last_used_at", "files"."created_at")) / $windowSeconds.0)',
    );
  }

  /// Построить ORDER BY выражение
  List<OrderingTerm> _buildOrderBy(FilesFilter filter) {
    final orderTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderTerms.add(
      OrderingTerm(expression: files.isPinned, mode: OrderingMode.desc),
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
      // Используем специфичное поле для файлов
      switch (filter.sortField!) {
        case FilesSortField.name:
          orderTerms.add(OrderingTerm(expression: files.name, mode: mode));
          break;
        case FilesSortField.fileName:
          orderTerms.add(OrderingTerm(expression: files.fileName, mode: mode));
          break;
        case FilesSortField.fileSize:
          orderTerms.add(OrderingTerm(expression: files.fileSize, mode: mode));
          break;
        case FilesSortField.fileExtension:
          orderTerms.add(
            OrderingTerm(expression: files.fileExtension, mode: mode),
          );
          break;
        case FilesSortField.mimeType:
          orderTerms.add(OrderingTerm(expression: files.mimeType, mode: mode));
          break;
        case FilesSortField.createdAt:
          orderTerms.add(OrderingTerm(expression: files.createdAt, mode: mode));
          break;
        case FilesSortField.modifiedAt:
          orderTerms.add(
            OrderingTerm(expression: files.modifiedAt, mode: mode),
          );
          break;
        case FilesSortField.lastAccessed:
          orderTerms.add(
            OrderingTerm(expression: files.lastUsedAt, mode: mode),
          );
          break;
      }
    } else {
      // Используем базовый sortBy из BaseFilter
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          orderTerms.add(OrderingTerm(expression: files.createdAt, mode: mode));
          break;
        case SortBy.modifiedAt:
          orderTerms.add(
            OrderingTerm(expression: files.modifiedAt, mode: mode),
          );
          break;
        case SortBy.lastUsedAt:
          orderTerms.add(
            OrderingTerm(expression: files.lastUsedAt, mode: mode),
          );
          break;
        case SortBy.recentScore:
          final windowDays = filter.base.frequencyWindowDays ?? 7;
          final scoreExpr = _calculateDynamicScore(windowDays);
          orderTerms.add(OrderingTerm(expression: scoreExpr, mode: mode));
          break;
      }
    }

    return orderTerms;
  }

  /// Загружает теги для списка файлов (максимум 10 тегов на файл)
  Future<Map<String, List<TagInCardDto>>> _loadTagsForFiles(
    List<String> fileIds,
  ) async {
    if (fileIds.isEmpty) return {};

    // Запрос для получения тегов со связями
    final query = select(filesTags).join([
      innerJoin(tags, tags.id.equalsExp(filesTags.tagId)),
    ])..where(filesTags.fileId.isIn(fileIds));

    // Группируем теги по fileId
    final tagsMap = <String, List<TagInCardDto>>{};

    // Обрабатываем результаты
    final results = await query.get();

    for (final row in results) {
      final fileTag = row.readTable(filesTags);
      final tag = row.readTable(tags);

      final fileId = fileTag.fileId;

      if (!tagsMap.containsKey(fileId)) {
        tagsMap[fileId] = [];
      }

      // Ограничиваем максимум 10 тегами
      if (tagsMap[fileId]!.length < 10) {
        tagsMap[fileId]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }

    return tagsMap;
  }
}
