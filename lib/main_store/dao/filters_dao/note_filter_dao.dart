import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/note_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/notes_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'note_filter_dao.g.dart';

@DriftAccessor(tables: [Notes, Categories, NotesTags, Tags])
class NoteFilterDao extends DatabaseAccessor<MainStore>
    with _$NoteFilterDaoMixin
    implements FilterDao<NotesFilter, NoteCardDto> {
  NoteFilterDao(super.db);

  /// Основной метод для получения отфильтрованных заметок
  @override
  Future<List<NoteCardDto>> getFiltered(NotesFilter filter) async {
    // Создаем базовый запрос с join к категориям
    final query = select(notes).join([
      leftOuterJoin(categories, categories.id.equalsExp(notes.categoryId)),
    ]);

    // Применяем все фильтры
    query.where(_buildWhereExpression(filter));

    // Применяем сортировку
    query.orderBy(_buildOrderBy(filter));

    // Применяем limit и offset
    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset);
    }

    // Выполняем запрос и маппим результаты
    final results = await query.get();

    // Собираем ID всех заметок для загрузки тегов
    final noteIds = results.map((row) => row.readTable(notes).id).toList();

    // Загружаем теги для всех заметок (максимум 10 на заметку)
    final tagsMap = await _loadTagsForNotes(noteIds);

    return results.map((row) {
      final note = row.readTable(notes);
      final category = row.readTableOrNull(categories);

      // Получаем теги для текущей заметки (максимум 10)
      final noteTags = tagsMap[note.id] ?? [];

      return NoteCardDto(
        id: note.id,
        title: note.title,
        description: note.description,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        isFavorite: note.isFavorite,
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isDeleted: note.isDeleted,
        usedCount: note.usedCount,
        modifiedAt: note.modifiedAt,
        tags: noteTags,
      );
    }).toList();
  }

  /// Подсчитывает количество отфильтрованных заметок
  @override
  Future<int> countFiltered(NotesFilter filter) async {
    final query = selectOnly(notes)..addColumns([notes.id.count()]);

    // Применяем все фильтры
    query.where(_buildWhereExpression(filter));

    // Выполняем запрос
    final result = await query.getSingle();
    return result.read(notes.id.count()) ?? 0;
  }

  /// Строит WHERE выражение на основе всех фильтров
  Expression<bool> _buildWhereExpression(NotesFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Применяем базовые фильтры
    expression = expression & _applyBaseFilters(filter.base);

    // Применяем специфичные фильтры для заметок
    expression = expression & _applyNoteSpecificFilters(filter);

    return expression;
  }

  /// Применяет базовые фильтры из BaseFilter
  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expression = const Constant(true);

    // Поисковый запрос по нескольким полям
    if (base.query.isNotEmpty) {
      final query = base.query.toLowerCase();
      expression =
          expression &
          (notes.title.lower().like('%$query%') |
              notes.description.lower().like('%$query%') |
              notes.content.lower().like('%$query%'));
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expression = expression & notes.categoryId.isIn(base.categoryIds);
    }

    // Фильтр по тегам (требует подзапрос)
    if (base.tagIds.isNotEmpty) {
      // Используем EXISTS для проверки наличия тегов
      final tagExists = existsQuery(
        select(notesTags)..where(
          (nt) => nt.noteId.equalsExp(notes.id) & nt.tagId.isIn(base.tagIds),
        ),
      );

      expression = expression & tagExists;
    }

    // Булевы флаги
    if (base.isFavorite != null) {
      expression = expression & notes.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expression = expression & notes.isArchived.equals(base.isArchived!);
    } else {
      // По умолчанию исключаем архивные
      expression = expression & notes.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expression = expression & notes.isDeleted.equals(base.isDeleted!);
    } else {
      // По умолчанию исключаем удалённые
      expression = expression & notes.isDeleted.equals(false);
    }

    if (base.isPinned != null) {
      expression = expression & notes.isPinned.equals(base.isPinned!);
    }

    if (base.hasNotes != null) {
      // Для заметок этот фильтр не применим, так как все записи - это заметки
      // Но оставляем для совместимости с BaseFilter
    }

    // Фильтр по частоте использования
    if (base.isFrequentlyUsed != null) {
      expression =
          expression &
          (base.isFrequentlyUsed!
              ? notes.usedCount.isBiggerOrEqualValue(
                  MainConstants.frequentlyUsedThreshold,
                )
              : notes.usedCount.isSmallerThanValue(
                  MainConstants.frequentlyUsedThreshold,
                ));
    }

    // Диапазоны дат создания
    if (base.createdAfter != null) {
      expression =
          expression & notes.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }

    if (base.createdBefore != null) {
      expression =
          expression &
          notes.createdAt.isSmallerOrEqualValue(base.createdBefore!);
    }

    // Диапазоны дат модификации
    if (base.modifiedAfter != null) {
      expression =
          expression &
          notes.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!);
    }

    if (base.modifiedBefore != null) {
      expression =
          expression &
          notes.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!);
    }

    // Диапазоны дат последнего доступа
    if (base.lastUsedAfter != null) {
      expression =
          expression &
          notes.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!);
    }

    if (base.lastUsedBefore != null) {
      expression =
          expression &
          notes.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!);
    }

    // Диапазоны счетчика использований
    if (base.minUsedCount != null) {
      expression =
          expression & notes.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }

    if (base.maxUsedCount != null) {
      expression =
          expression &
          notes.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }

    return expression;
  }

  /// Применяет специфичные фильтры для заметок
  Expression<bool> _applyNoteSpecificFilters(NotesFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Фильтр по заголовку
    if (filter.title != null) {
      expression =
          expression &
          notes.title.lower().like('%${filter.title!.toLowerCase()}%');
    }

    // Фильтр по содержимому
    if (filter.content != null) {
      expression =
          expression &
          notes.content.lower().like('%${filter.content!.toLowerCase()}%');
    }

    // Наличие описания
    if (filter.hasDescription != null) {
      expression =
          expression &
          (filter.hasDescription!
              ? notes.description.isNotNull()
              : notes.description.isNull());
    }

    // Наличие deltaJson (Quill формат)
    if (filter.hasDeltaJson != null) {
      expression =
          expression &
          (filter.hasDeltaJson!
              ? notes.deltaJson.isNotNull()
              : notes.deltaJson.isNull());
    }

    // Фильтр по длине контента
    if (filter.minContentLength != null) {
      expression =
          expression &
          notes.content.length.isBiggerOrEqualValue(filter.minContentLength!);
    }

    if (filter.maxContentLength != null) {
      expression =
          expression &
          notes.content.length.isSmallerOrEqualValue(filter.maxContentLength!);
    }

    return expression;
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
      'CAST(COALESCE("notes"."recent_score", 1) AS REAL) * '
      'exp(-($nowSeconds - COALESCE("notes"."last_used_at", "notes"."created_at")) / $windowSeconds.0)',
    );
  }

  /// Строит список OrderingTerm для сортировки
  List<OrderingTerm> _buildOrderBy(NotesFilter filter) {
    final orderingTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderingTerms.add(
      OrderingTerm(expression: notes.isPinned, mode: OrderingMode.desc),
    );

    // Основная сортировка
    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    // Если установлен фильтр по часто используемым, применяем динамическую сортировку
    if (filter.base.isFrequentlyUsed == true) {
      final windowDays = filter.base.frequencyWindowDays ?? 7;
      final scoreExpr = _calculateDynamicScore(windowDays);
      orderingTerms.add(OrderingTerm(expression: scoreExpr, mode: mode));
      return orderingTerms;
    }

    if (filter.sortField != null) {
      // Используем специфичное поле для заметок
      switch (filter.sortField!) {
        case NotesSortField.title:
          orderingTerms.add(OrderingTerm(expression: notes.title, mode: mode));
          break;
        case NotesSortField.description:
          orderingTerms.add(
            OrderingTerm(expression: notes.description, mode: mode),
          );
          break;
        case NotesSortField.contentLength:
          orderingTerms.add(
            OrderingTerm(expression: notes.content.length, mode: mode),
          );
          break;
        case NotesSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.createdAt, mode: mode),
          );
          break;
        case NotesSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.modifiedAt, mode: mode),
          );
          break;
        case NotesSortField.lastAccessed:
          orderingTerms.add(
            OrderingTerm(expression: notes.lastUsedAt, mode: mode),
          );
          break;
      }
    } else {
      // Используем базовый sortBy из BaseFilter
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.createdAt, mode: mode),
          );
          break;
        case SortBy.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.modifiedAt, mode: mode),
          );
          break;
        case SortBy.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: notes.lastUsedAt, mode: mode),
          );
          break;
        case SortBy.recentScore:
          final windowDays = filter.base.frequencyWindowDays ?? 7;
          final scoreExpr = _calculateDynamicScore(windowDays);
          orderingTerms.add(OrderingTerm(expression: scoreExpr, mode: mode));
          break;
      }
    }

    return orderingTerms;
  }

  /// Загружает теги для списка заметок (максимум 10 тегов на заметку)
  Future<Map<String, List<TagInCardDto>>> _loadTagsForNotes(
    List<String> noteIds,
  ) async {
    if (noteIds.isEmpty) return {};

    // Запрос для получения тегов со связями
    final query = select(notesTags).join([
      innerJoin(tags, tags.id.equalsExp(notesTags.tagId)),
    ])..where(notesTags.noteId.isIn(noteIds));

    // Группируем теги по noteId
    final tagsMap = <String, List<TagInCardDto>>{};

    // Обрабатываем результаты с учетом лимита
    final results = await query.get();

    for (final row in results) {
      final noteTag = row.readTable(notesTags);
      final tag = row.readTable(tags);

      final noteId = noteTag.noteId;

      if (!tagsMap.containsKey(noteId)) {
        tagsMap[noteId] = [];
      }

      // Ограничиваем максимум 10 тегами
      if (tagsMap[noteId]!.length < 10) {
        tagsMap[noteId]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }

    return tagsMap;
  }
}
