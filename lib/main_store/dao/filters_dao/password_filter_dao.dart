import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/password_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/passwords_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'password_filter_dao.g.dart';

@DriftAccessor(tables: [Passwords, Categories, Tags, PasswordsTags])
class PasswordFilterDao extends DatabaseAccessor<MainStore>
    with _$PasswordFilterDaoMixin
    implements FilterDao<PasswordsFilter, PasswordCardDto> {
  PasswordFilterDao(super.db);

  /// Основной метод для получения отфильтрованных паролей
  @override
  Future<List<PasswordCardDto>> getFiltered(PasswordsFilter filter) async {
    // Создаем базовый запрос с join к категориям
    final query = select(passwords).join([
      leftOuterJoin(categories, categories.id.equalsExp(passwords.categoryId)),
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

    // Собираем ID всех паролей для загрузки тегов
    final passwordIds = results
        .map((row) => row.readTable(passwords).id)
        .toList();

    // Загружаем теги для всех паролей (максимум 10 на пароль)
    final tagsMap = await _loadTagsForPasswords(passwordIds);

    return results.map((row) {
      final password = row.readTable(passwords);
      final category = row.readTableOrNull(categories);

      // Получаем теги для текущего пароля (максимум 10)
      final passwordTags = tagsMap[password.id] ?? [];

      return PasswordCardDto(
        id: password.id,
        name: password.name,
        login: password.login,
        email: password.email,
        url: password.url,
        isArchived: password.isArchived,
        description: password.description,
        isDeleted: password.isDeleted,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        isFavorite: password.isFavorite,
        isPinned: password.isPinned,
        usedCount: password.usedCount,
        modifiedAt: password.modifiedAt,
        createdAt: password.createdAt,
        tags: passwordTags,
      );
    }).toList();
  }

  /// Подсчитывает количество отфильтрованных паролей
  @override
  Future<int> countFiltered(PasswordsFilter filter) async {
    // Создаем запрос для подсчета
    final query = selectOnly(passwords)..addColumns([passwords.id.count()]);

    // Применяем те же фильтры
    query.where(_buildWhereExpression(filter));

    // Выполняем запрос
    final result = await query.getSingle();
    return result.read(passwords.id.count()) ?? 0;
  }

  /// Строит WHERE выражение на основе всех фильтров
  Expression<bool> _buildWhereExpression(PasswordsFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Применяем базовые фильтры
    expression = expression & _applyBaseFilters(filter.base);

    // Применяем специфичные фильтры для паролей
    expression = expression & _applyPasswordSpecificFilters(filter);

    return expression;
  }

  /// Применяет базовые фильтры из BaseFilter
  Expression<bool> _applyBaseFilters(BaseFilter base) {
    Expression<bool> expression = const Constant(true);

    // Если не указан явный фильтр по isDeleted, исключаем удалённые
    if (base.isDeleted == null) {
      expression = expression & passwords.isDeleted.equals(false);
    }

    // Поисковый запрос по нескольким полям
    if (base.query.isNotEmpty) {
      final query = base.query.toLowerCase();
      expression =
          expression &
          (passwords.name.lower().like('%$query%') |
              passwords.login.lower().like('%$query%') |
              passwords.email.lower().like('%$query%') |
              passwords.url.lower().like('%$query%') |
              passwords.description.lower().like('%$query%') |
              passwords.notes.lower().like('%$query%'));
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expression = expression & passwords.categoryId.isIn(base.categoryIds);
    }

    // Фильтр по тегам (требует подзапрос)
    if (base.tagIds.isNotEmpty) {
      // Используем EXISTS для проверки наличия тегов
      final tagExists = existsQuery(
        select(passwordsTags)..where(
          (pt) =>
              pt.passwordId.equalsExp(passwords.id) &
              pt.tagId.isIn(base.tagIds),
        ),
      );

      expression = expression & tagExists;
    }

    // Булевы флаги
    if (base.isFavorite != null) {
      expression = expression & passwords.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expression = expression & passwords.isArchived.equals(base.isArchived!);
    } else {
      // По умолчанию исключаем архивные
      expression = expression & passwords.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expression = expression & passwords.isDeleted.equals(base.isDeleted!);
    }

    // isPinned фильтр игнорируется - закрепленные записи всегда показываются первыми

    if (base.hasNotes != null) {
      expression =
          expression &
          (base.hasNotes!
              ? passwords.notes.isNotNull()
              : passwords.notes.isNull());
    }

    // Фильтр по частоте использования
    // if (base.isFrequentlyUsed != null) {
    //   expression =
    //       expression &
    //       (base.isFrequentlyUsed!
    //           ? passwords.usedCount.isBiggerOrEqualValue(
    //               MainConstants.frequentlyUsedThreshold,
    //             )
    //           : passwords.usedCount.isSmallerThanValue(
    //               MainConstants.frequentlyUsedThreshold,
    //             ));
    // }

    // Диапазоны дат создания
    if (base.createdAfter != null) {
      expression =
          expression &
          passwords.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }

    if (base.createdBefore != null) {
      expression =
          expression &
          passwords.createdAt.isSmallerOrEqualValue(base.createdBefore!);
    }

    // Диапазоны дат модификации
    if (base.modifiedAfter != null) {
      expression =
          expression &
          passwords.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!);
    }

    if (base.modifiedBefore != null) {
      expression =
          expression &
          passwords.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!);
    }

    // Диапазоны дат последнего доступа
    if (base.lastUsedAfter != null) {
      expression =
          expression &
          passwords.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!);
    }

    if (base.lastUsedBefore != null) {
      expression =
          expression &
          passwords.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!);
    }

    // Диапазоны счетчика использований
    if (base.minUsedCount != null) {
      expression =
          expression &
          passwords.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }

    if (base.maxUsedCount != null) {
      expression =
          expression &
          passwords.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }

    return expression;
  }

  /// Применяет специфичные фильтры для паролей
  Expression<bool> _applyPasswordSpecificFilters(PasswordsFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Фильтр по имени
    if (filter.name != null) {
      expression =
          expression &
          passwords.name.lower().like('%${filter.name!.toLowerCase()}%');
    }

    // Фильтр по логину
    if (filter.login != null) {
      expression =
          expression &
          passwords.login.lower().like('%${filter.login!.toLowerCase()}%');
    }

    // Фильтр по email
    if (filter.email != null) {
      expression =
          expression &
          passwords.email.lower().like('%${filter.email!.toLowerCase()}%');
    }

    // Фильтр по URL
    if (filter.url != null) {
      expression =
          expression &
          passwords.url.lower().like('%${filter.url!.toLowerCase()}%');
    }

    // Наличие описания
    if (filter.hasDescription != null) {
      expression =
          expression &
          (filter.hasDescription!
              ? passwords.description.isNotNull()
              : passwords.description.isNull());
    }

    // Наличие заметок
    if (filter.hasNotes != null) {
      expression =
          expression &
          (filter.hasNotes!
              ? passwords.notes.isNotNull()
              : passwords.notes.isNull());
    }

    // Наличие URL
    if (filter.hasUrl != null) {
      expression =
          expression &
          (filter.hasUrl! ? passwords.url.isNotNull() : passwords.url.isNull());
    }

    // Наличие логина
    if (filter.hasLogin != null) {
      expression =
          expression &
          (filter.hasLogin!
              ? passwords.login.isNotNull()
              : passwords.login.isNull());
    }

    // Наличие email
    if (filter.hasEmail != null) {
      expression =
          expression &
          (filter.hasEmail!
              ? passwords.email.isNotNull()
              : passwords.email.isNull());
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
      'CAST(COALESCE("passwords"."recent_score", 1) AS REAL) * '
      'exp(-($nowSeconds - COALESCE("passwords"."last_used_at", "passwords"."created_at")) / $windowSeconds.0)',
    );
  }

  /// Строит список OrderingTerm для сортировки
  List<OrderingTerm> _buildOrderBy(PasswordsFilter filter) {
    final orderingTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderingTerms.add(
      OrderingTerm(expression: passwords.isPinned, mode: OrderingMode.desc),
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

    // Используем sortBy из BaseFilter, если sortField не указан
    if (filter.sortField != null) {
      switch (filter.sortField!) {
        case PasswordsSortField.name:
          orderingTerms.add(
            OrderingTerm(expression: passwords.name, mode: mode),
          );
          break;
        case PasswordsSortField.login:
          orderingTerms.add(
            OrderingTerm(expression: passwords.login, mode: mode),
          );
          break;
        case PasswordsSortField.email:
          orderingTerms.add(
            OrderingTerm(expression: passwords.email, mode: mode),
          );
          break;
        case PasswordsSortField.url:
          orderingTerms.add(
            OrderingTerm(expression: passwords.url, mode: mode),
          );
          break;
        case PasswordsSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.createdAt, mode: mode),
          );
          break;
        case PasswordsSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.modifiedAt, mode: mode),
          );
          break;
        case PasswordsSortField.lastAccessed:
          orderingTerms.add(
            OrderingTerm(expression: passwords.lastUsedAt, mode: mode),
          );
          break;
      }
    } else {
      // Используем sortBy из BaseFilter
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.createdAt, mode: mode),
          );
          break;
        case SortBy.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.modifiedAt, mode: mode),
          );
          break;
        case SortBy.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: passwords.lastUsedAt, mode: mode),
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

  /// Загружает теги для списка паролей (максимум 10 тегов на пароль)
  Future<Map<String, List<TagInCardDto>>> _loadTagsForPasswords(
    List<String> passwordIds,
  ) async {
    if (passwordIds.isEmpty) return {};

    // Запрос для получения тегов со связями с LIMIT 10 на пароль
    final query = select(passwordsTags).join([
      innerJoin(tags, tags.id.equalsExp(passwordsTags.tagId)),
    ])..where(passwordsTags.passwordId.isIn(passwordIds));

    // Группируем теги по passwordId
    final tagsMap = <String, List<TagInCardDto>>{};

    // Обрабатываем результаты с учетом лимита
    final results = await query.get();

    for (final row in results) {
      final passwordTag = row.readTable(passwordsTags);
      final tag = row.readTable(tags);

      final passwordId = passwordTag.passwordId;

      if (!tagsMap.containsKey(passwordId)) {
        tagsMap[passwordId] = [];
      }

      // Ограничиваем максимум 10 тегами
      if (tagsMap[passwordId]!.length < 10) {
        tagsMap[passwordId]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }

    return tagsMap;
  }
}
