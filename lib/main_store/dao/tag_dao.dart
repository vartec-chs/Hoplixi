import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/tags_filter.dart';
import 'package:hoplixi/main_store/tables/tags.dart';
import 'package:uuid/uuid.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<MainStore> with _$TagDaoMixin {
  TagDao(super.db);

  /// Подсчитать количество элементов с данным тегом
  Future<int> countItemsInTag(String tagId) async {
    // Подсчитываем элементы через таблицы связей many-to-many
    final passwordsCount =
        await (selectOnly(db.passwordsTags)
              ..addColumns([db.passwordsTags.passwordId.count()])
              ..where(db.passwordsTags.tagId.equals(tagId))
              ..join([
                innerJoin(
                  db.passwords,
                  db.passwords.id.equalsExp(db.passwordsTags.passwordId) &
                      db.passwords.isDeleted.equals(false),
                ),
              ]))
            .getSingle()
            .then((row) => row.read(db.passwordsTags.passwordId.count()) ?? 0);

    final notesCount =
        await (selectOnly(db.notesTags)
              ..addColumns([db.notesTags.noteId.count()])
              ..where(db.notesTags.tagId.equals(tagId))
              ..join([
                innerJoin(
                  db.notes,
                  db.notes.id.equalsExp(db.notesTags.noteId) &
                      db.notes.isDeleted.equals(false),
                ),
              ]))
            .getSingle()
            .then((row) => row.read(db.notesTags.noteId.count()) ?? 0);

    final filesCount =
        await (selectOnly(db.filesTags)
              ..addColumns([db.filesTags.fileId.count()])
              ..where(db.filesTags.tagId.equals(tagId))
              ..join([
                innerJoin(
                  db.files,
                  db.files.id.equalsExp(db.filesTags.fileId) &
                      db.files.isDeleted.equals(false),
                ),
              ]))
            .getSingle()
            .then((row) => row.read(db.filesTags.fileId.count()) ?? 0);

    final bankCardsCount =
        await (selectOnly(db.bankCardsTags)
              ..addColumns([db.bankCardsTags.cardId.count()])
              ..where(db.bankCardsTags.tagId.equals(tagId))
              ..join([
                innerJoin(
                  db.bankCards,
                  db.bankCards.id.equalsExp(db.bankCardsTags.cardId) &
                      db.bankCards.isDeleted.equals(false),
                ),
              ]))
            .getSingle()
            .then((row) => row.read(db.bankCardsTags.cardId.count()) ?? 0);

    final otpsCount =
        await (selectOnly(db.otpsTags)
              ..addColumns([db.otpsTags.otpId.count()])
              ..where(db.otpsTags.tagId.equals(tagId))
              ..join([
                innerJoin(
                  db.otps,
                  db.otps.id.equalsExp(db.otpsTags.otpId) &
                      db.otps.isDeleted.equals(false),
                ),
              ]))
            .getSingle()
            .then((row) => row.read(db.otpsTags.otpId.count()) ?? 0);

    return passwordsCount +
        notesCount +
        filesCount +
        bankCardsCount +
        otpsCount;
  }

  /// Получить все теги
  Future<List<TagsData>> getAllTags() {
    return select(tags).get();
  }

  /// Получить тег по ID
  Future<TagsData?> getTagById(String id) {
    return (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Получить теги в виде карточек
  Future<List<TagCardDto>> getAllTagCards() async {
    final tagsList = await (select(
      tags,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

    final result = <TagCardDto>[];
    for (final tag in tagsList) {
      final itemsCount = await countItemsInTag(tag.id);
      result.add(
        TagCardDto(
          id: tag.id,
          name: tag.name,
          type: tag.type.value,
          color: tag.color,
          itemsCount: itemsCount,
        ),
      );
    }
    return result;
  }

  /// Смотреть все теги с автообновлением
  Stream<List<TagsData>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Смотреть теги карточки с автообновлением
  Stream<List<TagCardDto>> watchTagCards() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .asyncMap((tagsList) async {
          final result = <TagCardDto>[];
          for (final tag in tagsList) {
            final itemsCount = await countItemsInTag(tag.id);
            result.add(
              TagCardDto(
                id: tag.id,
                name: tag.name,
                type: tag.type.value,
                color: tag.color,
                itemsCount: itemsCount,
              ),
            );
          }
          return result;
        });
  }

  /// Создать новый тег
  Future<String> createTag(CreateTagDto dto) async {
    final id = const Uuid().v4(); // Генерируем уникальный ID для нового тега
    final companion = TagsCompanion.insert(
      id: Value(id),
      name: dto.name,
      type: TagTypeX.fromString(dto.type),
      color: Value(dto.color ?? 'FFFFFF'),
    );
    await into(tags).insert(companion);
    return id;
  }

  /// Обновить тег
  Future<bool> updateTag(String id, UpdateTagDto dto) {
    final companion = TagsCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      color: dto.color != null ? Value(dto.color!) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final query = update(tags)..where((t) => t.id.equals(id));
    return query.write(companion).then((rowsAffected) => rowsAffected > 0);
  }

  /// Получить теги по типу
  Stream<List<TagCardDto>> watchTagsByType(String type) {
    return (select(tags)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .asyncMap((tagsList) async {
          final result = <TagCardDto>[];
          for (final tag in tagsList) {
            final itemsCount = await countItemsInTag(tag.id);
            result.add(
              TagCardDto(
                id: tag.id,
                name: tag.name,
                type: tag.type.value,
                color: tag.color,
                itemsCount: itemsCount,
              ),
            );
          }
          return result;
        });
  }

  /// Получить теги с пагинацией
  Future<List<TagCardDto>> getTagCardsPaginated({
    required int limit,
    required int offset,
  }) async {
    final tagsList =
        await (select(tags)
              ..orderBy([(t) => OrderingTerm.asc(t.name)])
              ..limit(limit, offset: offset))
            .get();

    final result = <TagCardDto>[];
    for (final tag in tagsList) {
      final itemsCount = await countItemsInTag(tag.id);
      result.add(
        TagCardDto(
          id: tag.id,
          name: tag.name,
          type: tag.type.value,
          color: tag.color,
          itemsCount: itemsCount,
        ),
      );
    }
    return result;
  }

  /// Удалить тег
  Future<bool> deleteTag(String id) async {
    final rowsAffected = await (delete(
      tags,
    )..where((t) => t.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получить отфильтрованные теги
  Future<List<TagsData>> getTagsFiltered(TagsFilter filter) {
    var query = select(tags);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((t) => t.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.types.isNotEmpty) {
      query = query
        ..where((t) => t.type.isIn(filter.types.map((e) => e!.value).toList()));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((t) => t.color.equals(filter.color!));
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((t) => t.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((t) => t.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((t) => t.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((t) => t.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(t) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.get();
  }

  /// Получить теги по списку ID
  Future<List<TagsData>> getTagsByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(tags)..where((t) => t.id.isIn(ids))).get();
  }

  /// Смотреть отфильтрованные теги с автообновлением
  Stream<List<TagsData>> watchTagsFiltered(TagsFilter filter) {
    var query = select(tags);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where((t) => t.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.types.isNotEmpty) {
      query = query
        ..where((t) => t.type.isIn(filter.types.map((e) => e!.value).toList()));
    }

    // Фильтр по цвету
    if (filter.color != null) {
      query = query..where((t) => t.color.equals(filter.color!));
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where((t) => t.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where((t) => t.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where((t) => t.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where((t) => t.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([(t) => _getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.watch();
  }

  /// Получить отфильтрованные теги в виде карточек
  Future<List<TagCardDto>> getTagCardsFiltered(TagsFilter filter) async {
    final tagsList = await getTagsFiltered(filter);
    final result = <TagCardDto>[];
    for (final tag in tagsList) {
      final itemsCount = await countItemsInTag(tag.id);
      result.add(
        TagCardDto(
          id: tag.id,
          name: tag.name,
          type: tag.type.value,
          color: tag.color,
          itemsCount: itemsCount,
        ),
      );
    }
    return result;
  }

  /// Смотреть отфильтрованные теги карточки с автообновлением
  Stream<List<TagCardDto>> watchTagCardsFiltered(TagsFilter filter) {
    return watchTagsFiltered(filter).asyncMap((tagsList) async {
      final result = <TagCardDto>[];
      for (final tag in tagsList) {
        final itemsCount = await countItemsInTag(tag.id);
        result.add(
          TagCardDto(
            id: tag.id,
            name: tag.name,
            type: tag.type.value,
            color: tag.color,
            itemsCount: itemsCount,
          ),
        );
      }
      return result;
    });
  }

  /// Получить тип сортировки для Drift
  OrderingTerm _getSortOrderByTerm(TagsSortField sortField) {
    switch (sortField) {
      case TagsSortField.name:
        return OrderingTerm.asc(tags.name);
      case TagsSortField.type:
        return OrderingTerm.asc(tags.type);
      case TagsSortField.createdAt:
        return OrderingTerm.asc(tags.createdAt);
      case TagsSortField.modifiedAt:
        return OrderingTerm.asc(tags.modifiedAt);
    }
  }
}
