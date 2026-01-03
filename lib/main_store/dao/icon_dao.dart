import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/icons_filter.dart';
import 'package:hoplixi/main_store/tables/icons.dart';
import 'package:uuid/uuid.dart';

part 'icon_dao.g.dart';

@DriftAccessor(tables: [Icons])
class IconDao extends DatabaseAccessor<MainStore> with _$IconDaoMixin {
  IconDao(super.db);

  /// Получить все иконки
  Future<List<IconsData>> getAllIcons() {
    return select(icons).get();
  }

  /// Получить иконку по ID
  Future<IconsData?> getIconById(String id) {
    return (select(icons)..where((i) => i.id.equals(id))).getSingleOrNull();
  }

  /// Получить бинарные данные иконки по ID
  Future<Uint8List?> getIconData(String id) async {
    final query = selectOnly(icons)
      ..where(icons.id.equals(id))
      ..addColumns([icons.data]);
    final result = await query.getSingleOrNull();
    return result?.read(icons.data);
  }

  /// Получить иконку по ID без данных (без поля data)
  Future<IconCardDto?> getIconByIdNotData(String id) async {
    final query = selectOnly(icons)
      ..where(icons.id.equals(id))
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ]);
    final icon = await query.getSingleOrNull();

    if (icon == null) return null;

    return IconCardDto(
      id: icon.read(icons.id)!,
      name: icon.read(icons.name)!,
      type: icon.read(icons.type)!,
      createdAt: icon.read(icons.createdAt)!,
      modifiedAt: icon.read(icons.modifiedAt)!,
    );
  }

  /// Получить иконки в виде карточек
  Future<List<IconCardDto>> getAllIconCards() {
    final query = selectOnly(icons)
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ])
      ..orderBy([OrderingTerm.asc(icons.name)]);

    return query.map((row) {
      return IconCardDto(
        id: row.read(icons.id)!,
        name: row.read(icons.name)!,
        type: row.read(icons.type)!,
        createdAt: row.read(icons.createdAt)!,
        modifiedAt: row.read(icons.modifiedAt)!,
      );
    }).get();
  }

  /// Смотреть все иконки с автообновлением
  Stream<List<IconsData>> watchAllIcons() {
    return (select(icons)..orderBy([(i) => OrderingTerm.asc(i.name)])).watch();
  }

  /// Смотреть иконки карточки с автообновлением
  Stream<List<IconCardDto>> watchIconCards() {
    final query = selectOnly(icons)
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ])
      ..orderBy([OrderingTerm.asc(icons.name)]);

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => IconCardDto(
              id: row.read(icons.id)!,
              name: row.read(icons.name)!,
              type: row.read(icons.type)!,
              createdAt: row.read(icons.createdAt)!,
              modifiedAt: row.read(icons.modifiedAt)!,
            ),
          )
          .toList();
    });
  }

  /// Создать новую иконку
  Future<String> createIcon(CreateIconDto dto) async {
    final id = const Uuid().v4();
    final companion = IconsCompanion.insert(
      id: Value(id),
      name: dto.name,
      type: dto.type,
      data: Uint8List.fromList(dto.data),
    );
    await into(icons).insert(companion);
    return id;
  }

  /// Обновить иконку
  Future<bool> updateIcon(String id, UpdateIconDto dto) {
    final companion = IconsCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      type: dto.type != null
          ? Value(IconTypeX.fromString(dto.type!))
          : const Value.absent(),
      data: dto.data != null
          ? Value(Uint8List.fromList(dto.data!))
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final query = update(icons)..where((i) => i.id.equals(id));
    return query.write(companion).then((rowsAffected) => rowsAffected > 0);
  }

  /// Получить иконки с пагинацией
  Future<List<IconCardDto>> getIconCardsPaginated({
    required int limit,
    required int offset,
  }) {
    final query = selectOnly(icons)
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ])
      ..orderBy([OrderingTerm.asc(icons.name)])
      ..limit(limit, offset: offset);

    return query.map((row) {
      return IconCardDto(
        id: row.read(icons.id)!,
        name: row.read(icons.name)!,
        type: row.read(icons.type)!,
        createdAt: row.read(icons.createdAt)!,
        modifiedAt: row.read(icons.modifiedAt)!,
      );
    }).get();
  }

  /// Удалить иконку
  Future<bool> deleteIcon(String id) async {
    final rowsAffected = await (delete(
      icons,
    )..where((i) => i.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получить отфильтрованные иконки
  Future<List<IconsData>> getIconsFiltered(IconsFilter filter) async {
    var query = selectOnly(icons)
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ]);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where(icons.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where(icons.type.equals(filter.type!));
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where(icons.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where(icons.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where(icons.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where(icons.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([_getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    final rows = await query.get();
    return rows
        .map(
          (row) => IconsData(
            id: row.read(icons.id)!,
            name: row.read(icons.name)!,
            type: IconTypeX.fromString(row.read(icons.type)!),
            data: Uint8List(0), // Empty data for filtered results
            createdAt: row.read(icons.createdAt)!,
            modifiedAt: row.read(icons.modifiedAt)!,
          ),
        )
        .toList();
  }

  /// Смотреть отфильтрованные иконки с автообновлением
  Stream<List<IconsData>> watchIconsFiltered(IconsFilter filter) {
    var query = selectOnly(icons)
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ]);

    // Фильтр по поисковому запросу (название)
    if (filter.query.isNotEmpty) {
      query = query..where(icons.name.like('%${filter.query}%'));
    }

    // Фильтр по типу
    if (filter.type != null) {
      query = query..where(icons.type.equals(filter.type!));
    }

    // Фильтр по дате создания
    if (filter.createdAfter != null) {
      query = query
        ..where(icons.createdAt.isBiggerThanValue(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      query = query
        ..where(icons.createdAt.isSmallerThanValue(filter.createdBefore!));
    }

    // Фильтр по дате изменения
    if (filter.modifiedAfter != null) {
      query = query
        ..where(icons.modifiedAt.isBiggerThanValue(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      query = query
        ..where(icons.modifiedAt.isSmallerThanValue(filter.modifiedBefore!));
    }

    // Сортировка
    query = query..orderBy([_getSortOrderByTerm(filter.sortField)]);

    // Пагинация
    if (filter.limit != null && filter.limit! > 0) {
      query = query..limit(filter.limit!, offset: filter.offset ?? 0);
    }

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => IconsData(
              id: row.read(icons.id)!,
              name: row.read(icons.name)!,
              type: IconTypeX.fromString(row.read(icons.type)!),
              data: Uint8List(0), // Empty data for filtered results
              createdAt: row.read(icons.createdAt)!,
              modifiedAt: row.read(icons.modifiedAt)!,
            ),
          )
          .toList();
    });
  }

  /// Получить отфильтрованные иконки в виде карточек
  Future<List<IconCardDto>> getIconCardsFiltered(IconsFilter filter) async {
    final icons = await getIconsFiltered(filter);
    return icons
        .map(
          (i) => IconCardDto(
            id: i.id,
            name: i.name,
            type: i.type.value,
            createdAt: i.createdAt,
            modifiedAt: i.modifiedAt,
          ),
        )
        .toList();
  }

  /// Смотреть отфильтрованные иконки карточки с автообновлением
  Stream<List<IconCardDto>> watchIconCardsFiltered(IconsFilter filter) {
    return watchIconsFiltered(filter).map(
      (icons) => icons
          .map(
            (i) => IconCardDto(
              id: i.id,
              name: i.name,
              type: i.type.value,
              createdAt: i.createdAt,
              modifiedAt: i.modifiedAt,
            ),
          )
          .toList(),
    );
  }

  /// Получить детальную информацию об иконке
  Future<IconDetailDto?> getIconDetail(String id) async {
    final icon = await getIconById(id);
    if (icon == null) return null;

    return IconDetailDto(
      id: icon.id,
      name: icon.name,
      type: icon.type.value,
      // data: icon.data,
      createdAt: icon.createdAt,
      modifiedAt: icon.modifiedAt,
    );
  }

  /// Получить иконки по типу
  Stream<List<IconCardDto>> watchIconsByType(String type) {
    final query = selectOnly(icons)
      ..addColumns([
        icons.id,
        icons.name,
        icons.type,
        icons.createdAt,
        icons.modifiedAt,
      ])
      ..where(icons.type.equals(type))
      ..orderBy([OrderingTerm.asc(icons.name)]);

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => IconCardDto(
              id: row.read(icons.id)!,
              name: row.read(icons.name)!,
              type: row.read(icons.type)!,
              createdAt: row.read(icons.createdAt)!,
              modifiedAt: row.read(icons.modifiedAt)!,
            ),
          )
          .toList();
    });
  }

  /// Получить тип сортировки для Drift
  OrderingTerm _getSortOrderByTerm(IconsSortField sortField) {
    switch (sortField) {
      case IconsSortField.name:
        return OrderingTerm.asc(icons.name);
      case IconsSortField.type:
        return OrderingTerm.asc(icons.type);
      case IconsSortField.createdAt:
        return OrderingTerm.asc(icons.createdAt);
      case IconsSortField.modifiedAt:
        return OrderingTerm.asc(icons.modifiedAt);
    }
  }
}
