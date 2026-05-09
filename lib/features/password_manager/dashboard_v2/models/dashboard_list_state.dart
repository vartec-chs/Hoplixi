import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/main_db/core/models/dto/index.dart';

final class DashboardListState {
  const DashboardListState({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    this.isLoadingMore = false,
    this.lastError,
  });

  factory DashboardListState.empty({required int pageSize}) {
    return DashboardListState(
      items: const <BaseCardDto>[],
      totalCount: 0,
      page: 0,
      pageSize: pageSize,
    );
  }

  final List<BaseCardDto> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool isLoadingMore;
  final AppError? lastError;

  bool get hasMore => items.length < totalCount;
  bool get isEmpty => items.isEmpty;

  DashboardListState copyWith({
    List<BaseCardDto>? items,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? isLoadingMore,
    AppError? lastError,
    bool clearLastError = false,
  }) {
    return DashboardListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }
}
