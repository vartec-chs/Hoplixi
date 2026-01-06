import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/models/filter/bank_cards_filter.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'bank_card_filter_dao.g.dart';

@DriftAccessor(tables: [BankCards, Categories, BankCardsTags, Tags])
class BankCardFilterDao extends DatabaseAccessor<MainStore>
    with _$BankCardFilterDaoMixin
    implements FilterDao<BankCardsFilter, BankCardCardDto> {
  BankCardFilterDao(MainStore db) : super(db);

  /// Получить отфильтрованные банковские карты
  @override
  Future<List<BankCardCardDto>> getFiltered(BankCardsFilter filter) async {
    final query = select(bankCards).join([
      leftOuterJoin(categories, categories.id.equalsExp(bankCards.categoryId)),
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

    // Собираем ID всех карт для загрузки тегов
    final cardIds = results.map((row) => row.readTable(bankCards).id).toList();

    // Загружаем теги для всех карт (максимум 10 на карту)
    final tagsMap = await _loadTagsForBankCards(cardIds);

    return results.map((row) {
      final card = row.readTable(bankCards);
      final category = row.readTableOrNull(categories);

      // Получаем теги для текущей карты (максимум 10)
      final cardTags = tagsMap[card.id] ?? [];

      return BankCardCardDto(
        id: card.id,
        name: card.name,
        cardholderName: card.cardholderName,
        cardNumber: card.cardNumber,
        expiryMonth: card.expiryMonth,
        expiryYear: card.expiryYear,
        cardType: card.cardType?.value,
        cardNetwork: card.cardNetwork?.value,
        bankName: card.bankName,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        isFavorite: card.isFavorite,
        isPinned: card.isPinned,
        isArchived: card.isArchived,
        isDeleted: card.isDeleted,
        usedCount: card.usedCount,
        modifiedAt: card.modifiedAt,
        tags: cardTags,
      );
    }).toList();
  }

  /// Подсчитать количество отфильтрованных банковских карт
  @override
  Future<int> countFiltered(BankCardsFilter filter) async {
    final query = selectOnly(bankCards)..addColumns([bankCards.id.count()]);

    final whereExpression = _buildWhereExpression(filter);
    if (whereExpression != null) {
      query.where(whereExpression);
    }

    final result = await query.getSingle();
    return result.read(bankCards.id.count()) ?? 0;
  }

  /// Построить WHERE выражение на основе фильтра
  Expression<bool>? _buildWhereExpression(BankCardsFilter filter) {
    final expressions = <Expression<bool>>[];

    // Применяем базовые фильтры
    _applyBaseFilters(filter.base, expressions);

    // Применяем специфичные для банковских карт фильтры
    _applyBankCardSpecificFilters(filter, expressions);

    if (expressions.isEmpty) return null;

    return expressions.reduce((a, b) => a & b);
  }

  /// Применить базовые фильтры из BaseFilter
  void _applyBaseFilters(BaseFilter base, List<Expression<bool>> expressions) {
    // Фильтр по поисковому запросу
    if (base.query.isNotEmpty) {
      final queryLower = base.query.toLowerCase();
      expressions.add(
        bankCards.name.lower().like('%$queryLower%') |
            bankCards.cardholderName.lower().like('%$queryLower%') |
            bankCards.bankName.lower().like('%$queryLower%') |
            bankCards.description.lower().like('%$queryLower%') |
            bankCards.notes.lower().like('%$queryLower%'),
      );
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expressions.add(bankCards.categoryId.isIn(base.categoryIds));
    }

    // Фильтр по тегам (EXISTS subquery)
    if (base.tagIds.isNotEmpty) {
      final tagFilter = existsQuery(
        select(bankCardsTags)..where(
          (t) => t.cardId.equalsExp(bankCards.id) & t.tagId.isIn(base.tagIds),
        ),
      );
      expressions.add(tagFilter);
    }

    // Фильтр по дате создания
    if (base.createdAfter != null) {
      expressions.add(
        bankCards.createdAt.isBiggerOrEqualValue(base.createdAfter!),
      );
    }
    if (base.createdBefore != null) {
      expressions.add(
        bankCards.createdAt.isSmallerOrEqualValue(base.createdBefore!),
      );
    }

    // Фильтр по дате модификации
    if (base.modifiedAfter != null) {
      expressions.add(
        bankCards.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!),
      );
    }
    if (base.modifiedBefore != null) {
      expressions.add(
        bankCards.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!),
      );
    }

    // Фильтр по дате последнего доступа
    if (base.lastUsedAfter != null) {
      expressions.add(
        bankCards.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!) |
            bankCards.lastUsedAt.isNull(),
      );
    }
    if (base.lastUsedBefore != null) {
      expressions.add(
        bankCards.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!) |
            bankCards.lastUsedAt.isNull(),
      );
    }

    // Фильтр по избранным
    if (base.isFavorite != null) {
      expressions.add(bankCards.isFavorite.equals(base.isFavorite!));
    }

    // Фильтр по закрепленным
    if (base.isPinned != null) {
      expressions.add(bankCards.isPinned.equals(base.isPinned!));
    }

    // Фильтр по архивным
    if (base.isArchived != null) {
      expressions.add(bankCards.isArchived.equals(base.isArchived!));
    } else {
      // По умолчанию исключаем архивные
      expressions.add(bankCards.isArchived.equals(false));
    }

    // Фильтр по часто используемым
    if (base.isFrequentlyUsed != null) {
      if (base.isFrequentlyUsed!) {
        expressions.add(
          bankCards.usedCount.isBiggerOrEqualValue(
            MainConstants.frequentlyUsedThreshold,
          ),
        );
      } else {
        expressions.add(
          bankCards.usedCount.isSmallerThanValue(
            MainConstants.frequentlyUsedThreshold,
          ),
        );
      }
    }

    // Фильтр по удаленным
    if (base.isDeleted != null) {
      expressions.add(bankCards.isDeleted.equals(base.isDeleted!));
    } else {
      // По умолчанию исключаем удаленные
      expressions.add(bankCards.isDeleted.equals(false));
    }
  }

  /// Применить фильтры, специфичные для банковских карт
  void _applyBankCardSpecificFilters(
    BankCardsFilter filter,
    List<Expression<bool>> expressions,
  ) {
    // Фильтр по типам карт
    if (filter.cardTypes.isNotEmpty) {
      Expression<bool>? typeExpression;
      for (final type in filter.cardTypes) {
        final condition = bankCards.cardType.equalsValue(type);
        typeExpression = typeExpression == null
            ? condition
            : (typeExpression | condition);
      }
      if (typeExpression != null) {
        expressions.add(typeExpression);
      }
    }

    // Фильтр по сетям карт
    if (filter.cardNetworks.isNotEmpty) {
      Expression<bool>? networkExpression;
      for (final network in filter.cardNetworks) {
        final condition = bankCards.cardNetwork.equalsValue(network);
        networkExpression = networkExpression == null
            ? condition
            : (networkExpression | condition);
      }
      if (networkExpression != null) {
        expressions.add(networkExpression);
      }
    }

    // Фильтр по названию банка
    if (filter.bankName != null && filter.bankName!.isNotEmpty) {
      final bankNameLower = filter.bankName!.toLowerCase();
      expressions.add(bankCards.bankName.lower().contains(bankNameLower));
    }

    // Фильтр по имени держателя карты
    if (filter.cardholderName != null && filter.cardholderName!.isNotEmpty) {
      final cardholderLower = filter.cardholderName!.toLowerCase();
      expressions.add(
        bankCards.cardholderName.lower().contains(cardholderLower),
      );
    }

    // Фильтр по истекшему сроку действия
    if (filter.hasExpiryDatePassed != null) {
      final now = DateTime.now();
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString().padLeft(2, '0');

      if (filter.hasExpiryDatePassed!) {
        // Карты с истекшим сроком: год < текущего ИЛИ (год = текущему И месяц < текущего)
        expressions.add(
          bankCards.expiryYear.isSmallerThanValue(currentYear) |
              (bankCards.expiryYear.equals(currentYear) &
                  bankCards.expiryMonth.isSmallerThanValue(currentMonth)),
        );
      } else {
        // Карты с активным сроком: год > текущего ИЛИ (год = текущему И месяц >= текущего)
        expressions.add(
          bankCards.expiryYear.isBiggerThanValue(currentYear) |
              (bankCards.expiryYear.equals(currentYear) &
                  bankCards.expiryMonth.isBiggerOrEqualValue(currentMonth)),
        );
      }
    }

    // Фильтр по истекающим скоро картам (в течение 3 месяцев)
    if (filter.isExpiringSoon != null && filter.isExpiringSoon!) {
      final now = DateTime.now();
      final threeMonthsLater = now.add(const Duration(days: 90));
      final futureYear = threeMonthsLater.year.toString();
      final futureMonth = threeMonthsLater.month.toString().padLeft(2, '0');
      final currentYear = now.year.toString();
      final currentMonth = now.month.toString().padLeft(2, '0');

      // Карты истекают скоро: не истекли И (год < будущего ИЛИ (год = будущему И месяц <= будущего))
      expressions.add(
        (bankCards.expiryYear.isBiggerThanValue(currentYear) |
                (bankCards.expiryYear.equals(currentYear) &
                    bankCards.expiryMonth.isBiggerOrEqualValue(currentMonth))) &
            (bankCards.expiryYear.isSmallerThanValue(futureYear) |
                (bankCards.expiryYear.equals(futureYear) &
                    bankCards.expiryMonth.isSmallerOrEqualValue(futureMonth))),
      );
    }
  }

  /// Вычисляет динамический score для сортировки по активности
  /// Формула: recent_score * exp(-(current_time - last_used_at) / window_days)
  Expression<double> _calculateDynamicScore(int windowDays) {
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch / 1000.0; // в секундах
    final windowSeconds = windowDays * 24 * 60 * 60;

    // recent_score * exp(-(now - last_used_at) / window_seconds)
    // Если last_used_at == null, используем created_at
    final lastUsedOrCreated = CustomExpression<double>(
      'COALESCE(unixepoch("last_used_at"), unixepoch("created_at"))',
    );
    final timeDiff = Variable<double>(nowMillis) - lastUsedOrCreated;
    final expDecay = CustomExpression<double>(
      'EXP(-($timeDiff) / $windowSeconds)',
    );

    return bankCards.recentScore.cast<double>() * expDecay;
  }

  /// Построить ORDER BY выражение
  List<OrderingTerm> _buildOrderBy(BankCardsFilter filter) {
    final orderingTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderingTerms.add(
      OrderingTerm(expression: bankCards.isPinned, mode: OrderingMode.desc),
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
      // Используем специфичное поле для банковских карт
      switch (filter.sortField!) {
        case BankCardsSortField.name:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.name, mode: mode),
          );
          break;
        case BankCardsSortField.cardholderName:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.cardholderName, mode: mode),
          );
          break;
        case BankCardsSortField.bankName:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.bankName, mode: mode),
          );
          break;
        case BankCardsSortField.expiryDate:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.expiryYear, mode: mode),
          );
          orderingTerms.add(
            OrderingTerm(expression: bankCards.expiryMonth, mode: mode),
          );
          break;
        case BankCardsSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.createdAt, mode: mode),
          );
          break;
        case BankCardsSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.modifiedAt, mode: mode),
          );
          break;
        case BankCardsSortField.lastAccessed:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.lastUsedAt, mode: mode),
          );
          break;
      }
    } else {
      // Используем sortBy из BaseFilter
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.createdAt, mode: mode),
          );
          break;
        case SortBy.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.modifiedAt, mode: mode),
          );
          break;
        case SortBy.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: bankCards.lastUsedAt, mode: mode),
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

  /// Загружает теги для списка банковских карт (максимум 10 тегов на карту)
  Future<Map<String, List<TagInCardDto>>> _loadTagsForBankCards(
    List<String> cardIds,
  ) async {
    if (cardIds.isEmpty) return {};

    // Запрос для получения тегов со связями
    final query = select(bankCardsTags).join([
      innerJoin(tags, tags.id.equalsExp(bankCardsTags.tagId)),
    ])..where(bankCardsTags.cardId.isIn(cardIds));

    // Группируем теги по cardId
    final tagsMap = <String, List<TagInCardDto>>{};

    // Обрабатываем результаты с учетом лимита
    final results = await query.get();

    for (final row in results) {
      final bankCardTag = row.readTable(bankCardsTags);
      final tag = row.readTable(tags);

      final cardId = bankCardTag.cardId;

      if (!tagsMap.containsKey(cardId)) {
        tagsMap[cardId] = [];
      }

      // Ограничиваем максимум 10 тегами
      if (tagsMap[cardId]!.length < 10) {
        tagsMap[cardId]!.add(
          TagInCardDto(id: tag.id, name: tag.name, color: tag.color),
        );
      }
    }

    return tagsMap;
  }
}
