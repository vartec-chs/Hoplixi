import 'package:flutter_riverpod/flutter_riverpod.dart';

final closeSyncTrackingProvider =
    NotifierProvider<CloseSyncTrackingNotifier, CloseSyncTrackingState>(
      CloseSyncTrackingNotifier.new,
    );

class CloseSyncTrackingState {
  CloseSyncTrackingState({
    this.openedModifiedAt,
    this.forceUpload = false,
    this.pendingPrompt = false,
    this.uploadRequiredStoreUuid,
    this.uploadRequiredStorePath,
  });

  final DateTime?
  openedModifiedAt; // Время последнего открытия хранилища, для сравнения с текущим временем модификации при попытке закрытия
  final bool
  forceUpload; // Флаг, указывающий, что при закрытии хранилища необходимо загрузить снимок, даже если время модификации не изменилось (например, после успешной загрузки снимка, требующей повторного закрытия)
  final bool
  pendingPrompt; // Флаг, указывающий, что при попытке закрытия хранилища уже отображается запрос на загрузку снимка, чтобы предотвратить показ нескольких запросов при повторных попытках закрытия без изменения состояния
  final String? uploadRequiredStoreUuid;
  final String? uploadRequiredStorePath;

  bool hasLogicalChanges(DateTime currentModifiedAt) {
    final currentModifiedAtUtc = currentModifiedAt.toUtc();
    return forceUpload ||
        pendingPrompt ||
        openedModifiedAt == null ||
        !openedModifiedAt!.isAtSameMomentAs(currentModifiedAtUtc);
  }
}

class CloseSyncTrackingNotifier extends Notifier<CloseSyncTrackingState> {
  @override
  CloseSyncTrackingState build() {
    return CloseSyncTrackingState();
  }

  bool hasLogicalChanges(DateTime currentModifiedAt) {
    return state.hasLogicalChanges(currentModifiedAt);
  }

  void start(
    DateTime initialModifiedAt, {
    String? storeUuid,
    String? storePath,
    bool forceUpload = false,
  }) {
    final hasMatchingPendingUpload =
        state.forceUpload &&
        state.uploadRequiredStoreUuid != null &&
        state.uploadRequiredStoreUuid == storeUuid &&
        (state.uploadRequiredStorePath == null ||
            state.uploadRequiredStorePath == storePath);

    state = CloseSyncTrackingState(
      openedModifiedAt: initialModifiedAt.toUtc(),
      forceUpload: forceUpload || hasMatchingPendingUpload,
      uploadRequiredStoreUuid: hasMatchingPendingUpload ? storeUuid : null,
      uploadRequiredStorePath: hasMatchingPendingUpload ? storePath : null,
    );
  }

  void reset() {
    state = CloseSyncTrackingState();
  }

  void closeSession() {
    state = CloseSyncTrackingState(
      forceUpload: state.forceUpload,
      uploadRequiredStoreUuid: state.uploadRequiredStoreUuid,
      uploadRequiredStorePath: state.uploadRequiredStorePath,
    );
  }

  void markUploadRequired({String? storeUuid, String? storePath}) {
    state = CloseSyncTrackingState(
      openedModifiedAt: state.openedModifiedAt,
      forceUpload: true,
      pendingPrompt: state.pendingPrompt,
      uploadRequiredStoreUuid: storeUuid ?? state.uploadRequiredStoreUuid,
      uploadRequiredStorePath: storePath ?? state.uploadRequiredStorePath,
    );
  }

  void setPendingPrompt(bool pendingPrompt) {
    state = CloseSyncTrackingState(
      openedModifiedAt: state.openedModifiedAt,
      forceUpload: state.forceUpload,
      pendingPrompt: pendingPrompt,
      uploadRequiredStoreUuid: state.uploadRequiredStoreUuid,
      uploadRequiredStorePath: state.uploadRequiredStorePath,
    );
  }

  void markUploadedOrNotNeeded() {
    state = CloseSyncTrackingState(openedModifiedAt: state.openedModifiedAt);
  }
}
