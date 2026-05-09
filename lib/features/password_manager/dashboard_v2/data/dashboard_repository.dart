import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';
import 'package:result_dart/result_dart.dart';

import '../models/dashboard_entity_type.dart';
import '../models/dashboard_query.dart';

typedef DashboardLoadResult = ({List<BaseCardDto> items, int totalCount});

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

  Future<ResultDart<bool, AppError>> restore({
    required DashboardEntityType entityType,
    required String id,
  });

  Future<ResultDart<bool, AppError>> permanentDelete({
    required DashboardEntityType entityType,
    required String id,
  });

  AsyncResultDart<int, AppError> bulkSetFavorite({
    required DashboardEntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSetPinned({
    required DashboardEntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSetArchived({
    required DashboardEntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSoftDelete({
    required DashboardEntityType entityType,
    required List<String> ids,
  });

  AsyncResultDart<int, AppError> bulkPermanentDelete({
    required DashboardEntityType entityType,
    required List<String> ids,
  });

  AsyncResultDart<int, AppError> bulkAssignCategory({
    required DashboardEntityType entityType,
    required List<String> ids,
    required String? categoryId,
  });

  AsyncResultDart<bool, AppError> bulkAssignTags({
    required DashboardEntityType entityType,
    required List<String> ids,
    required List<String> tagIds,
  });
}
