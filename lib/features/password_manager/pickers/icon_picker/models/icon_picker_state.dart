import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';

part 'icon_picker_state.freezed.dart';

@freezed
sealed class IconPickerState with _$IconPickerState {
  const factory IconPickerState({
    required List<IconCardDto> items,
    required bool hasMore,
    required bool isLoading,
    required Object? error,
    required int currentPage,
  }) = _IconPickerState;

  factory IconPickerState.initial() {
    return const IconPickerState(
      items: [],
      hasMore: true,
      isLoading: false,
      error: null,
      currentPage: 0,
    );
  }
}
