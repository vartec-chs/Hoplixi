import 'package:hoplixi/db_core/models/dto/index.dart';

/// Общий контракт для DAO, возвращающих отфильтрованные DTO и их количество.
abstract class FilterDao<TFilter, TDto extends BaseCardDto> {
  /// Возвращает список DTO по фильтру.
  Future<List<TDto>> getFiltered(TFilter filter);

  /// Считает количество элементов по фильтру.
  Future<int> countFiltered(TFilter filter);
}
