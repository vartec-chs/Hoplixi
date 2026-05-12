import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/main_db/core/old/models/dto/index.dart';
import 'package:result_dart/result_dart.dart';

import '../models/entity_type.dart';
import '../models/dashboard_query.dart';

typedef DashboardLoadResult = ({List<BaseCardDto> items, int totalCount});

abstract interface class DashboardRepository {
  Future<ResultDart<DashboardLoadResult, AppError>> load(DashboardQuery query);

  Future<ResultDart<bool, AppError>> setFavorite({
    required EntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> setPinned({
    required EntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> setArchived({
    required EntityType entityType,
    required String id,
    required bool value,
  });

  Future<ResultDart<bool, AppError>> softDelete({
    required EntityType entityType,
    required String id,
  });

  Future<ResultDart<bool, AppError>> restore({
    required EntityType entityType,
    required String id,
  });

  Future<ResultDart<bool, AppError>> permanentDelete({
    required EntityType entityType,
    required String id,
  });

  AsyncResultDart<int, AppError> bulkSetFavorite({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSetPinned({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSetArchived({
    required EntityType entityType,
    required List<String> ids,
    required bool value,
  });

  AsyncResultDart<int, AppError> bulkSoftDelete({
    required EntityType entityType,
    required List<String> ids,
  });

  AsyncResultDart<int, AppError> bulkPermanentDelete({
    required EntityType entityType,
    required List<String> ids,
  });

  AsyncResultDart<int, AppError> bulkAssignCategory({
    required EntityType entityType,
    required List<String> ids,
    required String? categoryId,
  });

  AsyncResultDart<bool, AppError> bulkAssignTags({
    required EntityType entityType,
    required List<String> ids,
    required List<String> tagIds,
  });
}
