import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/dao/filters_dao/filter.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';
import 'package:hoplixi/main_store/models/filter/base_filter.dart';
import 'package:hoplixi/main_store/models/filter/otps_filter.dart';
import 'package:hoplixi/main_store/tables/index.dart';

part 'otp_filter_dao.g.dart';

@DriftAccessor(tables: [Otps, Categories, OtpsTags, Tags])
class OtpFilterDao extends DatabaseAccessor<MainStore>
    with _$OtpFilterDaoMixin
    implements FilterDao<OtpsFilter, OtpCardDto> {
  OtpFilterDao(super.db);

  /// Основной метод для получения отфильтрованных OTP записей
  @override
  Future<List<OtpCardDto>> getFiltered(OtpsFilter filter) async {
    // Создаем базовый запрос с join к категориям
    final query = select(otps).join([
      leftOuterJoin(categories, categories.id.equalsExp(otps.categoryId)),
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

    // Собираем ID всех OTP для загрузки тегов
    final otpIds = results.map((row) => row.readTable(otps).id).toList();

    // Загружаем теги для всех OTP одним запросом
    final tagsMap = await _loadTagsForOtps(otpIds);

    return results.map((row) {
      final otp = row.readTable(otps);
      final category = row.readTableOrNull(categories);

      return OtpCardDto(
        id: otp.id,
        issuer: otp.issuer,
        accountName: otp.accountName,
        type: otp.type.name,
        digits: otp.digits,
        period: otp.period,
        category: category != null
            ? CategoryInCardDto(
                id: category.id,
                name: category.name,
                type: category.type.name,
                color: category.color,
                iconId: category.iconId,
              )
            : null,
        tags: tagsMap[otp.id] ?? [],
        isFavorite: otp.isFavorite,
        isPinned: otp.isPinned,
        isArchived: otp.isArchived,
        isDeleted: otp.isDeleted,
        usedCount: otp.usedCount,
        modifiedAt: otp.modifiedAt,
      );
    }).toList();
  }

  /// Загружает теги для списка OTP одним запросом
  Future<Map<String, List<TagInCardDto>>> _loadTagsForOtps(
    List<String> otpIds,
  ) async {
    if (otpIds.isEmpty) return {};

    final query = select(otpsTags).join([
      innerJoin(tags, tags.id.equalsExp(otpsTags.tagId)),
    ])..where(otpsTags.otpId.isIn(otpIds));

    final results = await query.get();

    final Map<String, List<TagInCardDto>> tagsMap = {};

    for (final row in results) {
      final otpTag = row.readTable(otpsTags);
      final tag = row.readTable(tags);

      final tagDto = TagInCardDto(id: tag.id, name: tag.name, color: tag.color);

      tagsMap.putIfAbsent(otpTag.otpId, () => []).add(tagDto);
    }

    return tagsMap;
  }

  /// Подсчитывает количество отфильтрованных паролей
  @override
  Future<int> countFiltered(OtpsFilter filter) async {
    // Создаем запрос для подсчета
    final query = selectOnly(otps)..addColumns([otps.id.count()]);

    // Применяем те же фильтры
    query.where(_buildWhereExpression(filter));

    // Выполняем запрос
    final result = await query.getSingle();
    return result.read(otps.id.count()) ?? 0;
  }

  /// Строит WHERE выражение на основе всех фильтров
  Expression<bool> _buildWhereExpression(OtpsFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Применяем базовые фильтры
    expression = expression & _applyBaseFilters(filter.base);

    // Применяем специфичные фильтры для OTP
    expression = expression & _applyOtpSpecificFilters(filter);

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
          (otps.issuer.lower().like('%$query%') |
              otps.accountName.lower().like('%$query%') |
              otps.notes.lower().like('%$query%'));
    }

    // Фильтр по категориям
    if (base.categoryIds.isNotEmpty) {
      expression = expression & otps.categoryId.isIn(base.categoryIds);
    }

    // Фильтр по тегам (требует подзапрос)
    if (base.tagIds.isNotEmpty) {
      // Используем EXISTS для проверки наличия тегов
      final tagExists = existsQuery(
        select(otpsTags)..where(
          (ot) => ot.otpId.equalsExp(otps.id) & ot.tagId.isIn(base.tagIds),
        ),
      );

      expression = expression & tagExists;
    }

    // Булевы флаги
    if (base.isFavorite != null) {
      expression = expression & otps.isFavorite.equals(base.isFavorite!);
    }

    if (base.isArchived != null) {
      expression = expression & otps.isArchived.equals(base.isArchived!);
    } else {
      // По умолчанию исключаем архивные
      expression = expression & otps.isArchived.equals(false);
    }

    if (base.isDeleted != null) {
      expression = expression & otps.isDeleted.equals(base.isDeleted!);
    } else {
      // По умолчанию исключаем удалённые
      expression = expression & otps.isDeleted.equals(false);
    }

    if (base.isPinned != null) {
      expression = expression & otps.isPinned.equals(base.isPinned!);
    }

    if (base.hasNotes != null) {
      expression =
          expression &
          (base.hasNotes! ? otps.notes.isNotNull() : otps.notes.isNull());
    }

    // Фильтр по частоте использования
    if (base.isFrequentlyUsed != null) {
      expression =
          expression &
          (base.isFrequentlyUsed!
              ? otps.usedCount.isBiggerOrEqualValue(
                  MainConstants.frequentlyUsedThreshold,
                )
              : otps.usedCount.isSmallerThanValue(
                  MainConstants.frequentlyUsedThreshold,
                ));
    }

    // Диапазоны дат создания
    if (base.createdAfter != null) {
      expression =
          expression & otps.createdAt.isBiggerOrEqualValue(base.createdAfter!);
    }

    if (base.createdBefore != null) {
      expression =
          expression &
          otps.createdAt.isSmallerOrEqualValue(base.createdBefore!);
    }

    // Диапазоны дат модификации
    if (base.modifiedAfter != null) {
      expression =
          expression &
          otps.modifiedAt.isBiggerOrEqualValue(base.modifiedAfter!);
    }

    if (base.modifiedBefore != null) {
      expression =
          expression &
          otps.modifiedAt.isSmallerOrEqualValue(base.modifiedBefore!);
    }

    // Диапазоны дат последнего доступа
    if (base.lastUsedAfter != null) {
      expression =
          expression &
          otps.lastUsedAt.isBiggerOrEqualValue(base.lastUsedAfter!);
    }

    if (base.lastUsedBefore != null) {
      expression =
          expression &
          otps.lastUsedAt.isSmallerOrEqualValue(base.lastUsedBefore!);
    }

    // Диапазоны счетчика использований
    if (base.minUsedCount != null) {
      expression =
          expression & otps.usedCount.isBiggerOrEqualValue(base.minUsedCount!);
    }

    if (base.maxUsedCount != null) {
      expression =
          expression & otps.usedCount.isSmallerOrEqualValue(base.maxUsedCount!);
    }

    return expression;
  }

  /// Применяет специфичные фильтры для OTP
  Expression<bool> _applyOtpSpecificFilters(OtpsFilter filter) {
    Expression<bool> expression = const Constant(true);

    // Фильтр по типам OTP (TOTP, HOTP)
    if (filter.types.isNotEmpty) {
      final typeExpressions = filter.types
          .map((type) => otps.type.equals(type.name))
          .reduce((a, b) => a | b);
      expression = expression & typeExpressions;
    }

    // Фильтр по алгоритмам
    if (filter.algorithms.isNotEmpty) {
      final algorithmExpressions = filter.algorithms
          .map((algorithm) => otps.algorithm.equals(algorithm.name))
          .reduce((a, b) => a | b);
      expression = expression & algorithmExpressions;
    }

    // Фильтр по издателю (issuer)
    if (filter.issuer != null) {
      expression =
          expression &
          otps.issuer.lower().like('%${filter.issuer!.toLowerCase()}%');
    }

    // Фильтр по имени аккаунта
    if (filter.accountName != null) {
      expression =
          expression &
          otps.accountName.lower().like(
            '%${filter.accountName!.toLowerCase()}%',
          );
    }

    // Фильтр по количеству цифр
    if (filter.digits.isNotEmpty) {
      expression = expression & otps.digits.isIn(filter.digits);
    }

    // Фильтр по периоду
    if (filter.periods.isNotEmpty) {
      expression = expression & otps.period.isIn(filter.periods);
    }

    // Фильтр по кодировке секрета
    if (filter.secretEncodings.isNotEmpty) {
      final encodingExpressions = filter.secretEncodings
          .map((encoding) => otps.secretEncoding.equals(encoding.name))
          .reduce((a, b) => a | b);
      expression = expression & encodingExpressions;
    }

    // Наличие связи с паролем
    if (filter.hasPasswordLink != null) {
      expression =
          expression &
          (filter.hasPasswordLink!
              ? otps.passwordId.isNotNull()
              : otps.passwordId.isNull());
    }

    // Наличие заметок
    if (filter.hasNotes != null) {
      expression =
          expression &
          (filter.hasNotes! ? otps.notes.isNotNull() : otps.notes.isNull());
    }

    return expression;
  }

  /// Вычисляет динамический score для сортировки по активности
  /// Формула: recent_score * exp(-(current_time - last_used_at) / window_days)
  Expression<double> _calculateDynamicScore(int windowDays) {
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch / 1000.0; // в секундах
    final windowSeconds = windowDays * 24 * 60 * 60;

    // recent_score * exp(-(now - last_used_at) / window_seconds)
    final timeDiff =
        Variable<double>(nowMillis) - otps.lastUsedAt.unixepoch.cast<double>();
    final expDecay = CustomExpression<double>(
      'EXP(-($timeDiff) / $windowSeconds)',
    );

    return otps.recentScore.cast<double>() * expDecay;
  }

  /// Строит список OrderingTerm для сортировки
  List<OrderingTerm> _buildOrderBy(OtpsFilter filter) {
    final orderingTerms = <OrderingTerm>[];

    // Закрепленные записи всегда сверху
    orderingTerms.add(
      OrderingTerm(expression: otps.isPinned, mode: OrderingMode.desc),
    );

    // Основная сортировка
    final mode = filter.base.sortDirection == SortDirection.asc
        ? OrderingMode.asc
        : OrderingMode.desc;

    if (filter.sortField != null) {
      // Используем специфичное поле для OTP
      switch (filter.sortField!) {
        case OtpsSortField.issuer:
          orderingTerms.add(OrderingTerm(expression: otps.issuer, mode: mode));
          break;
        case OtpsSortField.accountName:
          orderingTerms.add(
            OrderingTerm(expression: otps.accountName, mode: mode),
          );
          break;
        case OtpsSortField.type:
          orderingTerms.add(OrderingTerm(expression: otps.type, mode: mode));
          break;
        case OtpsSortField.algorithm:
          orderingTerms.add(
            OrderingTerm(expression: otps.algorithm, mode: mode),
          );
          break;
        case OtpsSortField.digits:
          orderingTerms.add(OrderingTerm(expression: otps.digits, mode: mode));
          break;
        case OtpsSortField.period:
          orderingTerms.add(OrderingTerm(expression: otps.period, mode: mode));
          break;
        case OtpsSortField.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: otps.createdAt, mode: mode),
          );
          break;
        case OtpsSortField.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: otps.modifiedAt, mode: mode),
          );
          break;
        case OtpsSortField.lastAccessed:
          orderingTerms.add(
            OrderingTerm(expression: otps.lastUsedAt, mode: mode),
          );
          break;
      }
    } else {
      // Используем базовый sortBy из BaseFilter
      switch (filter.base.sortBy) {
        case SortBy.createdAt:
          orderingTerms.add(
            OrderingTerm(expression: otps.createdAt, mode: mode),
          );
          break;
        case SortBy.modifiedAt:
          orderingTerms.add(
            OrderingTerm(expression: otps.modifiedAt, mode: mode),
          );
          break;
        case SortBy.lastUsedAt:
          orderingTerms.add(
            OrderingTerm(expression: otps.lastUsedAt, mode: mode),
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
}
