import 'package:riverpod/riverpod.dart';

final closeSyncTrackingProvider =
    NotifierProvider<CloseSyncTrackingNotifier, CloseSyncTrackingState>(
      CloseSyncTrackingNotifier.new,
    );

class CloseSyncTrackingState {
  CloseSyncTrackingState({
    this.openedModifiedAt,
    this.forceUpload = false,
    this.pendingPrompt = false,
  });

  final DateTime?
  openedModifiedAt; // Время последнего открытия хранилища, для сравнения с текущим временем модификации при попытке закрытия
  final bool
  forceUpload; // Флаг, указывающий, что при закрытии хранилища необходимо загрузить снимок, даже если время модификации не изменилось (например, после успешной загрузки снимка, требующей повторного закрытия)
  final bool
  pendingPrompt; // Флаг, указывающий, что при попытке закрытия хранилища уже отображается запрос на загрузку снимка, чтобы предотвратить показ нескольких запросов при повторных попытках закрытия без изменения состояния
}

class CloseSyncTrackingNotifier extends Notifier<CloseSyncTrackingState> {
  @override
  CloseSyncTrackingState build() {
    return CloseSyncTrackingState();
  }

  // 
  bool hasLogicalChanges(DateTime currentModifiedAt) {
    return state.forceUpload ||
        state.pendingPrompt ||
        state.openedModifiedAt == null ||
        !state.openedModifiedAt!.isAtSameMomentAs(currentModifiedAt.toUtc());
  }

  void start(DateTime initialModifiedAt, {bool forceUpload = false}) {
    state = CloseSyncTrackingState(
      openedModifiedAt: initialModifiedAt.toUtc(),
      forceUpload: forceUpload,
    );
  }

  void reset() {
    state = CloseSyncTrackingState();
  }

  void markUploadRequired() {
    state = CloseSyncTrackingState(
      openedModifiedAt: state.openedModifiedAt,
      forceUpload: true,
      pendingPrompt: state.pendingPrompt,
    );
  }

  void setPendingPrompt(bool pendingPrompt) {
    state = CloseSyncTrackingState(
      openedModifiedAt: state.openedModifiedAt,
      forceUpload: state.forceUpload,
      pendingPrompt: pendingPrompt,
    );
  }

  void markUploadedOrNotNeeded() {
    state = CloseSyncTrackingState(openedModifiedAt: state.openedModifiedAt);
  }
}
