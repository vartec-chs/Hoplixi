import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/models/db_state.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';

final currentStoreSyncProvider =
    AsyncNotifierProvider<CurrentStoreSyncNotifier, StoreSyncStatus>(
      CurrentStoreSyncNotifier.new,
    );

final currentStoreSyncSnapshotProvider =
    NotifierProvider<CurrentStoreSyncSnapshotNotifier, StoreSyncStatus?>(
      CurrentStoreSyncSnapshotNotifier.new,
    );

class CurrentStoreSyncSnapshotNotifier extends Notifier<StoreSyncStatus?> {
  @override
  StoreSyncStatus? build() => null;

  void setStatus(StoreSyncStatus? nextStatus) {
    state = nextStatus;
  }

  void clear() {
    state = null;
  }
}

final closeStoreSnapshotSyncCoordinatorProvider =
    Provider<CloseStoreSnapshotSyncCoordinator>(
      (ref) => CloseStoreSnapshotSyncCoordinator(ref),
    );

final currentStoreSyncManualReauthIssueProvider =
    NotifierProvider<
      CurrentStoreSyncManualReauthIssueNotifier,
      CurrentStoreSyncManualReauthIssue?
    >(CurrentStoreSyncManualReauthIssueNotifier.new);

// TODO: В будущем, если появятся другие виды проблем с синхронизацией, требующих вмешательства пользователя, можно будет расширить CurrentStoreSyncManualReauthIssue до более общего CurrentStoreSyncIssue с разными типами (например, manualReauthRequired, missingToken, permissionDenied и т.д.) и соответствующими данными для каждой проблемы. Сейчас же для простоты реализован только один тип проблемы - требующий ручной реавторизации.
enum CurrentStoreSyncIssueKind { manualReauthRequired, missingToken }

class CurrentStoreSyncManualReauthIssue {
  const CurrentStoreSyncManualReauthIssue({
    required this.kind,
    required this.tokenId,
    required this.provider,
    this.storeUuid,
    this.storePath,
    this.tokenLabel,
    this.description,
  });

  final CurrentStoreSyncIssueKind kind;
  final String tokenId;
  final CloudSyncProvider provider;
  final String? storeUuid;
  final String? storePath;
  final String? tokenLabel;
  final String? description;

  String get dedupeKey =>
      '${kind.name}|${storeUuid ?? ''}|${storePath ?? ''}|$tokenId|${provider.id}|${description ?? ''}';
}

class CurrentStoreSyncManualReauthIssueNotifier
    extends Notifier<CurrentStoreSyncManualReauthIssue?> {
  @override
  CurrentStoreSyncManualReauthIssue? build() => null;

  void report(CurrentStoreSyncManualReauthIssue issue) {
    state = issue;
  }

  void clear() {
    state = null;
  }
}

class CurrentStoreSyncNotifier extends AsyncNotifier<StoreSyncStatus> {
  @override
  Future<StoreSyncStatus> build() async {
    final storeState = await ref.watch(mainStoreProvider.future);
    final status = await _loadCurrentStatus(storeState, useWatch: true);
    _publishSyncSnapshot(status);
    _syncCloseStoreUploadPromptRequirement(status);
    return status;
  }

  Future<void> loadStatus({bool rethrowOnError = false}) async {
    final previous = state.value;
    state = const AsyncLoading();
    try {
      final storeState = await ref.read(mainStoreProvider.future);
      final next = await _loadCurrentStatus(storeState, useWatch: false);
      _setSyncState(next);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      if (rethrowOnError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  Future<void> connect(String tokenId) async {
    final current = await future;
    final storeUuid = current.storeUuid;
    if (storeUuid == null) {
      throw StateError('Store UUID is unavailable.');
    }

    final token = await _loadToken(tokenId);
    if (token == null) {
      throw StateError('OAuth token was not found.');
    }

    final bindingService = ref.read(storeSyncBindingServiceProvider);
    final syncService = ref.read(snapshotSyncServiceProvider);
    await bindingService.saveBinding(
      storeUuid: storeUuid,
      tokenId: token.id,
      provider: token.provider,
    );
    final savedBinding = await bindingService.getByStoreUuid(storeUuid);
    try {
      await syncService.initializeRemoteLayout(
        tokenId: token.id,
        storeUuid: storeUuid,
      );
      await loadStatus(rethrowOnError: true);
      if (state.value?.compareResult ==
          StoreVersionCompareResult.remoteMissing) {
        ref
            .read(mainStoreProvider.notifier)
            .markSnapshotUploadOnCloseRequired();
      }
      _syncCloseStoreUploadPromptRequirement(state.value);
    } catch (error, stackTrace) {
      _reportManualReauthIfNeeded(
        error,
        binding: savedBinding,
        token: token,
        storeUuid: storeUuid,
        storePath: current.storePath,
      );
      if (_canKeepBindingAfterConnectProbeError(error) &&
          savedBinding != null) {
        final next = current.copyWith(
          binding: savedBinding,
          token: token,
          clearRemoteManifest: true,
          clearPendingConflict: true,
          compareResult: StoreVersionCompareResult.remoteMissing,
          lastResultType: SnapshotSyncResultType.idle,
        );
        _setSyncState(next);
        return;
      }
      if (current.binding != null) {
        await bindingService.saveBinding(
          storeUuid: current.binding!.storeUuid,
          tokenId: current.binding!.tokenId,
          provider: current.binding!.provider,
        );
      } else {
        await bindingService.deleteBinding(storeUuid);
      }
      _setSyncState(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool _canKeepBindingAfterConnectProbeError(Object error) {
    return switch (error) {
      _ when error is CloudStorageException =>
        error.type == CloudStorageExceptionType.network ||
            error.type == CloudStorageExceptionType.timeout,
      _ => false,
    };
  }

  Future<void> disconnect() async {
    final current = await future;
    final storeUuid = current.storeUuid;
    if (storeUuid == null) {
      return;
    }

    await ref.read(storeSyncBindingServiceProvider).deleteBinding(storeUuid);
    _setSyncState(
      current.copyWith(
        clearBinding: true,
        clearToken: true,
        clearRemoteManifest: true,
        clearPendingConflict: true,
        compareResult: StoreVersionCompareResult.remoteMissing,
      ),
    );
    await loadStatus();
  }

  void _syncCloseStoreUploadPromptRequirement(StoreSyncStatus? status) {
    ref
        .read(mainStoreProvider.notifier)
        .syncPendingSnapshotUploadPrompt(
          storeUuid: status?.storeUuid,
          hasBinding: status?.binding != null,
          compareResult: status?.compareResult,
        );
  }

  void _setSyncState(StoreSyncStatus next) {
    state = AsyncData(next);
    _publishSyncSnapshot(next);
    _syncCloseStoreUploadPromptRequirement(next);
  }

  void _publishSyncSnapshot(StoreSyncStatus next) {
    ref.read(currentStoreSyncSnapshotProvider.notifier).setStatus(next);
  }

  Future<void> syncNow() async {
    final current = await future;
    final binding = current.binding;
    final token = current.token;
    final storePath = current.storePath;
    if (binding == null || token == null || storePath == null) {
      throw StateError('Cloud sync is not connected.');
    }

    final manager = await ref.read(mainStoreManagerProvider.future);
    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );
    final syncService = ref.read(snapshotSyncServiceProvider);

    if (current.compareResult == StoreVersionCompareResult.conflict) {
      _setSyncState(
        current.copyWith(
          pendingConflict:
              current.pendingConflict ??
              (current.remoteManifest == null || current.localManifest == null
                  ? null
                  : SnapshotSyncConflict(
                      localManifest: current.localManifest!,
                      remoteManifest: current.remoteManifest!,
                    )),
          lastResultType: SnapshotSyncResultType.conflict,
        ),
      );
      return;
    }

    if (current.compareResult == StoreVersionCompareResult.remoteNewer) {
      final downloadInProgressState = current.copyWith(
        isStoreOpen: false,
        storePath: storePath,
        storeUuid: binding.storeUuid,
        binding: binding,
        token: token,
        clearPendingConflict: true,
        requiresUnlockToApply: false,
        isApplyingRemoteUpdate: true,
        syncProgress: _initialDownloadProgress(),
        isSyncInProgress: true,
      );
      _setSyncState(downloadInProgressState);
      try {
        await ref
            .read(mainStoreProvider.notifier)
            .lockStore(skipSnapshotSync: true);
        final result = await _runProgressStream(
          baseState: downloadInProgressState,
          stream: syncService.resolveConflictWithProgress(
            storePath: storePath,
            storeInfo: storeInfo,
            binding: binding,
            resolution: SnapshotConflictResolution.downloadRemote,
            lockBeforeDownload: true,
          ),
          binding: binding,
          token: token,
          storePath: storePath,
        );
        _setSyncState(
          _buildLockedDownloadedStatus(
            current: current,
            binding: binding,
            token: token,
            storePath: storePath,
            result: result,
          ),
        );
        return;
      } catch (error, stackTrace) {
        _setSyncState(
          downloadInProgressState.copyWith(
            isApplyingRemoteUpdate: false,
            clearSyncProgress: true,
            isSyncInProgress: false,
          ),
        );
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    final result = await _runProgressStream(
      baseState: current.copyWith(
        clearPendingConflict: true,
        clearSyncProgress: true,
        isSyncInProgress: false,
      ),
      stream: syncService.syncWithProgress(
        storePath: storePath,
        storeInfo: storeInfo,
        binding: binding,
      ),
      binding: binding,
      token: token,
      storePath: storePath,
    );

    if (result.type == SnapshotSyncResultType.conflict) {
      _setSyncState(
        current.copyWith(
          localManifest: result.localManifest,
          remoteManifest: result.remoteManifest,
          pendingConflict: result.conflict,
          compareResult: StoreVersionCompareResult.conflict,
          lastResultType: SnapshotSyncResultType.conflict,
          clearSyncProgress: true,
          isSyncInProgress: false,
        ),
      );
      return;
    }

    _setSyncState(
      await _reloadStatusWithoutLoading(
        lastResultType: result.type,
        clearPendingConflict: true,
      ),
    );
  }

  Future<SnapshotSyncResult> syncBeforeClose({
    required StoreSyncStatus status,
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
  }) async {
    return ref
        .read(closeStoreSnapshotSyncCoordinatorProvider)
        .syncBeforeClose(
          status: status,
          storePath: storePath,
          storeInfo: storeInfo,
          binding: binding,
          token: token,
          onStatusChanged: (nextState) {
            _setSyncState(nextState);
          },
        );
  }

  Future<void> resolveConflictWithUpload() async {
    await _resolveConflict(SnapshotConflictResolution.uploadLocal);
  }

  Future<void> resolveConflictWithDownload() async {
    await _resolveConflict(SnapshotConflictResolution.downloadRemote);
  }

  Future<void> _resolveConflict(SnapshotConflictResolution resolution) async {
    final current = await future;
    final binding = current.binding;
    final token = current.token;
    final storePath = current.storePath;
    if (binding == null || token == null || storePath == null) {
      throw StateError('Cloud sync is not connected.');
    }

    final manager = await ref.read(mainStoreManagerProvider.future);
    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );
    final syncService = ref.read(snapshotSyncServiceProvider);

    final requiresUnlock =
        resolution == SnapshotConflictResolution.downloadRemote;
    final progressBaseState = requiresUnlock
        ? current.copyWith(
            isStoreOpen: false,
            storePath: storePath,
            storeUuid: binding.storeUuid,
            binding: binding,
            token: token,
            clearPendingConflict: true,
            requiresUnlockToApply: false,
            isApplyingRemoteUpdate: true,
            syncProgress: _initialDownloadProgress(),
            isSyncInProgress: true,
          )
        : current.copyWith(
            clearPendingConflict: true,
            clearSyncProgress: true,
            isSyncInProgress: false,
          );
    if (requiresUnlock) {
      _setSyncState(progressBaseState);
      try {
        await ref
            .read(mainStoreProvider.notifier)
            .lockStore(skipSnapshotSync: true);
      } catch (error, stackTrace) {
        _setSyncState(
          progressBaseState.copyWith(
            isApplyingRemoteUpdate: false,
            clearSyncProgress: true,
            isSyncInProgress: false,
          ),
        );
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    final result = await _runProgressStream(
      baseState: progressBaseState,
      stream: syncService.resolveConflictWithProgress(
        storePath: storePath,
        storeInfo: storeInfo,
        binding: binding,
        resolution: resolution,
        lockBeforeDownload: requiresUnlock,
      ),
      binding: binding,
      token: token,
      storePath: storePath,
    );

    if (requiresUnlock) {
      _setSyncState(
        _buildLockedDownloadedStatus(
          current: current,
          binding: binding,
          token: token,
          storePath: storePath,
          result: result,
        ),
      );
      return;
    }

    _setSyncState(
      await _reloadStatusWithoutLoading(
        lastResultType: result.type,
        clearPendingConflict: true,
      ),
    );
  }

  Future<SnapshotSyncResult> _consumeProgressStream({
    required StoreSyncStatus baseState,
    required Stream<SnapshotSyncProgressEvent> stream,
  }) async {
    SnapshotSyncResult? result;
    await for (final event in stream) {
      if (event is SnapshotSyncProgressUpdate) {
        _setSyncState(
          baseState.copyWith(
            syncProgress: event.progress,
            isSyncInProgress: true,
          ),
        );
        continue;
      }
      if (event is SnapshotSyncProgressResult) {
        result = event.result;
      }
    }

    if (result == null) {
      throw StateError('Snapshot sync stream completed without a result.');
    }
    return result;
  }

  Future<SnapshotSyncResult> _runProgressStream({
    required StoreSyncStatus baseState,
    required Stream<SnapshotSyncProgressEvent> stream,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    required String storePath,
  }) async {
    try {
      return await _consumeProgressStream(baseState: baseState, stream: stream);
    } catch (error, stackTrace) {
      _reportManualReauthIfNeeded(
        error,
        binding: binding,
        token: token,
        storeUuid: binding.storeUuid,
        storePath: storePath,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<StoreSyncStatus> _reloadStatusWithoutLoading({
    required SnapshotSyncResultType lastResultType,
    bool clearPendingConflict = false,
  }) async {
    final storeState = await ref.read(mainStoreProvider.future);
    final refreshed = await _loadCurrentStatus(storeState, useWatch: false);
    return refreshed.copyWith(
      lastResultType: lastResultType,
      clearPendingConflict: clearPendingConflict,
      clearSyncProgress: true,
      isSyncInProgress: false,
      isApplyingRemoteUpdate: false,
    );
  }

  StoreSyncStatus _buildLockedDownloadedStatus({
    required StoreSyncStatus current,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    required String storePath,
    required SnapshotSyncResult result,
  }) {
    return StoreSyncStatus(
      isStoreOpen: false,
      storePath: storePath,
      storeUuid: binding.storeUuid,
      storeName: current.storeName,
      binding: binding,
      token: token,
      localManifest: result.localManifest,
      remoteManifest: result.remoteManifest,
      compareResult: StoreVersionCompareResult.same,
      lastResultType: result.type,
      requiresUnlockToApply: true,
      isApplyingRemoteUpdate: false,
      isSyncInProgress: false,
    );
  }

  SnapshotSyncProgress _initialDownloadProgress() {
    return const SnapshotSyncProgress(
      stage: SnapshotSyncStage.preparingLocalSnapshot,
      stepIndex: 1,
      totalSteps: 6,
      title: 'Подготовка локального снимка',
      description: 'Подготавливаем применение удалённого snapshot.',
    );
  }

  Future<AuthTokenEntry?> _loadToken(String tokenId) {
    return ref.read(authTokensProvider.notifier).getTokenById(tokenId);
  }

  Future<StoreSyncStatus> _loadCurrentStatus(
    DatabaseState storeState, {
    required bool useWatch,
  }) async {
    if (!storeState.isOpen) {
      return StoreSyncStatus(
        isStoreOpen: false,
        storePath: storeState.path,
        storeName: storeState.name,
      );
    }

    final manager = useWatch
        ? await ref.watch(mainStoreManagerProvider.future)
        : await ref.read(mainStoreManagerProvider.future);

    final storeInfoResult = await manager.getStoreInfo();
    final storeInfo = storeInfoResult.fold(
      (info) => info,
      (error) => throw error,
    );

    final bindingService = ref.read(storeSyncBindingServiceProvider);
    var binding = await bindingService.getByStoreUuid(storeInfo.id);
    final token = binding == null ? null : await _loadToken(binding.tokenId);
    if (binding != null && token == null) {
      _reportMissingTokenBindingIssue(
        binding: binding,
        storeUuid: storeInfo.id,
        storePath: manager.currentStorePath,
      );
      await bindingService.deleteBinding(storeInfo.id);
      binding = null;
    }

    final syncService = ref.read(snapshotSyncServiceProvider);
    final skipRemoteCheck =
        useWatch &&
        binding != null &&
        token != null &&
        !await _hasInternetAccess();
    try {
      return await syncService.loadStatus(
        storePath: manager.currentStorePath!,
        storeInfo: storeInfo,
        binding: binding,
        token: token,
        skipRemoteManifestCheck: skipRemoteCheck,
        remoteCheckSkippedOffline: skipRemoteCheck,
      );
    } catch (error, stackTrace) {
      _reportManualReauthIfNeeded(
        error,
        binding: binding,
        token: token,
        storeUuid: storeInfo.id,
        storePath: manager.currentStorePath,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      return await ref.read(internetConnectionProvider).hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  void _reportManualReauthIfNeeded(
    Object error, {
    StoreSyncBinding? binding,
    AuthTokenEntry? token,
    String? storeUuid,
    String? storePath,
  }) {
    final issue = _buildManualReauthIssue(
      error,
      binding: binding,
      token: token,
      storeUuid: storeUuid,
      storePath: storePath,
    );
    if (issue == null) {
      return;
    }
    ref.read(currentStoreSyncManualReauthIssueProvider.notifier).report(issue);
  }

  void _reportMissingTokenBindingIssue({
    required StoreSyncBinding binding,
    String? storeUuid,
    String? storePath,
  }) {
    ref
        .read(currentStoreSyncManualReauthIssueProvider.notifier)
        .report(
          CurrentStoreSyncManualReauthIssue(
            kind: CurrentStoreSyncIssueKind.missingToken,
            tokenId: binding.tokenId,
            provider: binding.provider,
            storeUuid: storeUuid ?? binding.storeUuid,
            storePath: storePath,
            description:
                'Привязка cloud sync найдена, но связанный OAuth-токен больше не доступен на этом устройстве.',
          ),
        );
  }

  CurrentStoreSyncManualReauthIssue? _buildManualReauthIssue(
    Object error, {
    StoreSyncBinding? binding,
    AuthTokenEntry? token,
    String? storeUuid,
    String? storePath,
  }) {
    if (error is! CloudStorageException ||
        error.type != CloudStorageExceptionType.unauthorized) {
      return null;
    }

    final tokenId = token?.id ?? binding?.tokenId;
    final provider = token?.provider ?? binding?.provider ?? error.provider;
    if (tokenId == null || provider == null) {
      return null;
    }

    final description = switch (error.cause) {
      CloudSyncHttpException(type: CloudSyncHttpExceptionType.refreshFailed) =>
        'Не удалось автоматически обновить OAuth-токен. Требуется повторная ручная авторизация.',
      CloudSyncHttpException(type: CloudSyncHttpExceptionType.unauthorized) =>
        'Облачный провайдер отклонил текущий токен. Требуется повторная ручная авторизация.',
      _ =>
        'Доступ к облачному провайдеру больше не подтверждается. Требуется повторная ручная авторизация.',
    };

    return CurrentStoreSyncManualReauthIssue(
      kind: CurrentStoreSyncIssueKind.manualReauthRequired,
      tokenId: tokenId,
      provider: provider,
      storeUuid: storeUuid ?? binding?.storeUuid,
      storePath: storePath,
      tokenLabel: token?.displayLabel,
      description: description,
    );
  }
}

class CloseStoreSnapshotSyncCoordinator {
  const CloseStoreSnapshotSyncCoordinator(this.ref);

  final Ref ref;

  Future<SnapshotSyncResult> syncBeforeClose({
    required StoreSyncStatus status,
    required String storePath,
    required StoreInfoDto storeInfo,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    void Function(StoreSyncStatus state)? onStatusChanged,
  }) async {
    final syncService = ref.read(snapshotSyncServiceProvider);
    final baseState = status.copyWith(
      isStoreOpen: true,
      storePath: storePath,
      storeUuid: binding.storeUuid,
      storeName: status.storeName ?? storeInfo.name,
      binding: binding,
      token: token,
      clearPendingConflict: true,
      clearSyncProgress: true,
      isSyncInProgress: false,
      isApplyingRemoteUpdate: false,
      requiresUnlockToApply: false,
    );

    onStatusChanged?.call(baseState);

    final result = await _runProgressStream(
      baseState: baseState,
      stream: syncService.syncWithProgress(
        storePath: storePath,
        storeInfo: storeInfo,
        binding: binding,
      ),
      binding: binding,
      token: token,
      storePath: storePath,
      onStatusChanged: onStatusChanged,
    );

    onStatusChanged?.call(
      baseState.copyWith(
        localManifest: result.localManifest,
        remoteManifest: result.remoteManifest,
        lastResultType: result.type,
        clearSyncProgress: true,
        isSyncInProgress: false,
      ),
    );

    return result;
  }

  Future<SnapshotSyncResult> _consumeProgressStream({
    required StoreSyncStatus baseState,
    required Stream<SnapshotSyncProgressEvent> stream,
    void Function(StoreSyncStatus state)? onStatusChanged,
  }) async {
    SnapshotSyncResult? result;
    await for (final event in stream) {
      if (event is SnapshotSyncProgressUpdate) {
        onStatusChanged?.call(
          baseState.copyWith(
            syncProgress: event.progress,
            isSyncInProgress: true,
          ),
        );
        continue;
      }
      if (event is SnapshotSyncProgressResult) {
        result = event.result;
      }
    }

    if (result == null) {
      throw StateError('Snapshot sync stream completed without a result.');
    }
    return result;
  }

  Future<SnapshotSyncResult> _runProgressStream({
    required StoreSyncStatus baseState,
    required Stream<SnapshotSyncProgressEvent> stream,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    required String storePath,
    void Function(StoreSyncStatus state)? onStatusChanged,
  }) async {
    try {
      return await _consumeProgressStream(
        baseState: baseState,
        stream: stream,
        onStatusChanged: onStatusChanged,
      );
    } catch (error, stackTrace) {
      _reportManualReauthIfNeeded(
        ref,
        error,
        binding: binding,
        token: token,
        storeUuid: binding.storeUuid,
        storePath: storePath,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

void _reportManualReauthIfNeeded(
  Ref ref,
  Object error, {
  StoreSyncBinding? binding,
  AuthTokenEntry? token,
  String? storeUuid,
  String? storePath,
}) {
  final issue = _buildManualReauthIssue(
    error,
    binding: binding,
    token: token,
    storeUuid: storeUuid,
    storePath: storePath,
  );
  if (issue == null) {
    return;
  }
  ref.read(currentStoreSyncManualReauthIssueProvider.notifier).report(issue);
}

CurrentStoreSyncManualReauthIssue? _buildManualReauthIssue(
  Object error, {
  StoreSyncBinding? binding,
  AuthTokenEntry? token,
  String? storeUuid,
  String? storePath,
}) {
  if (error is! CloudStorageException ||
      error.type != CloudStorageExceptionType.unauthorized) {
    return null;
  }

  final tokenId = token?.id ?? binding?.tokenId;
  final provider = token?.provider ?? binding?.provider ?? error.provider;
  if (tokenId == null || provider == null) {
    return null;
  }

  final description = switch (error.cause) {
    CloudSyncHttpException(type: CloudSyncHttpExceptionType.refreshFailed) =>
      'Не удалось автоматически обновить OAuth-токен. Требуется повторная ручная авторизация.',
    CloudSyncHttpException(type: CloudSyncHttpExceptionType.unauthorized) =>
      'Облачный провайдер отклонил текущий токен. Требуется повторная ручная авторизация.',
    _ =>
      'Доступ к облачному провайдеру больше не подтверждается. Требуется повторная ручная авторизация.',
  };

  return CurrentStoreSyncManualReauthIssue(
    kind: CurrentStoreSyncIssueKind.manualReauthRequired,
    tokenId: tokenId,
    provider: provider,
    storeUuid: storeUuid ?? binding?.storeUuid,
    storePath: storePath,
    tokenLabel: token?.displayLabel,
    description: description,
  );
}
