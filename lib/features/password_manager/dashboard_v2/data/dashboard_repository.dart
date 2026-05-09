import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:result_dart/result_dart.dart';

import '../models/dashboard_entity_type.dart';
import '../models/dashboard_query.dart';

typedef DashboardLoadResult = ({
  List<BaseCardDto> items,
  int totalCount,
});

abstract interface class DashboardRepository {
  Future<ResultDart<DashboardLoadResult, AppError>> load(DashboardQuery query);

  Future<ResultDart<bool, AppError>> setFavorite({
    required DashboardEntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> setPinned({
    required DashboardEntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> setArchived({
    required DashboardEntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> softDelete({
    required DashboardEntityType entityType,
    required String id,
  });
}
