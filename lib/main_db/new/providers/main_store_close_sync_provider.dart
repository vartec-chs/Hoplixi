import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/errors/errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/new/models/main_store_close_sync_state.dart';
import 'package:hoplixi/main_db/new/providers/close_sync_tracking_provider.dart';
import 'package:hoplixi/main_db/new/services/main_store_close_sync_service.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:result_dart/result_dart.dart';
import 'package:typed_prefs/typed_prefs.dart';

final mainStoreCloseSyncServiceProvider = Provider<MainStoreCloseSyncService>(
  (ref) => const MainStoreCloseSyncService(),
);

final mainStoreCloseSyncProvider =
    AsyncNotifierProvider<MainStoreCloseSyncNotifier, MainStoreCloseSyncState>(
      MainStoreCloseSyncNotifier.new,
    );

class MainStoreCloseSyncNotifier
    extends AsyncNotifier<MainStoreCloseSyncState> {
  static const String _logTag = 'MainStoreCloseSyncNotifier';

  Completer<bool>? _closeStoreUploadDecision;

  MainStoreCloseSyncState get _current =>
      state.value ?? const MainStoreCloseSyncState();

  MainStoreCloseSyncService get _service =>
      ref.read(mainStoreCloseSyncServiceProvider);

  @override
  Future<MainStoreCloseSyncState> build() async {
    ref.onDispose(_completePendingDecisionAsSkipped);
    return const MainStoreCloseSyncState();
  }

  AsyncResultDart<MainStoreCloseSyncOutcome, AppError>
  uploadSnapshotAfterClose({
    required StoreInfoDto storeInfo,
    required String currentStorePath,
  }) async {
    _setState(
      const MainStoreCloseSyncState(phase: MainStoreCloseSyncPhase.checking),
    );

    try {
      final context = _CloseSyncContext(
        storePath: currentStorePath,
        storeInfo: storeInfo,
      );
      final tracking = ref.read(closeSyncTrackingProvider);
      if (!_service.hasLogicalChanges(
        openedModifiedAt: tracking.openedModifiedAt,
        forceUpload: tracking.forceUpload,
        pendingPrompt: tracking.pendingPrompt,
        currentModifiedAt: context.storeInfo.modifiedAt,
      )) {
        final outcome = _service.skipped(
          MainStoreCloseSyncOutcomeType.noLogicalChanges,
        );
        _completeWithOutcome(
          outcome,
          logMessage:
              'Skipping snapshot sync after close because StoreMeta.modifiedAt did not change during the current session.',
          logData: <String, dynamic>{
            'storePath': context.storePath,
            'openedStoreModifiedAt': tracking.openedModifiedAt
                ?.toIso8601String(),
            'currentStoreModifiedAt': context.storeInfo.modifiedAt
                .toUtc()
                .toIso8601String(),
            'pendingSnapshotUploadPromptOnClose': tracking.pendingPrompt,
          },
        );
        return Success(outcome);
      }

      final cachedStatus = _service.reusableStatus(
        cachedStatus: ref.read(currentStoreSyncSnapshotProvider),
        storePath: context.storePath,
        storeInfo: context.storeInfo,
      );

      final binding =
          cachedStatus?.binding ??
          await ref
              .read(storeSyncBindingServiceProvider)
              .getByStoreUuid(context.storeInfo.id);
      if (binding == null) {
        final outcome = _service.skipped(
          MainStoreCloseSyncOutcomeType.noBinding,
        );
        _completeWithOutcome(outcome);
        return Success(outcome);
      }

      final token =
          cachedStatus?.token ??
          await ref
              .read(authTokensProvider.notifier)
              .getTokenById(binding.tokenId);
      if (token == null) {
        logWarning(
          'Skipping snapshot sync after close because token binding is stale.',
          tag: _logTag,
          data: <String, dynamic>{
            'storeUuid': context.storeInfo.id,
            'tokenId': binding.tokenId,
          },
        );
        final outcome = _service.skipped(
          MainStoreCloseSyncOutcomeType.staleTokenBinding,
        );
        _completeWithOutcome(outcome);
        return Success(outcome);
      }

      final autoUploadEnabled = await _isAutoUploadEnabled();
      if (autoUploadEnabled && !await _hasInternetAccessForCloseSync()) {
        logWarning(
          'Skipping snapshot upload after close because device has no internet access and auto-upload is enabled.',
          tag: _logTag,
          data: <String, dynamic>{
            'storeUuid': context.storeInfo.id,
            'tokenId': token.id,
          },
        );
        final outcome = _service.skipped(
          MainStoreCloseSyncOutcomeType.offlineAutoUpload,
        );
        _completeWithOutcome(outcome);
        return Success(outcome);
      }

      final status = await _loadStatus(
        cachedStatus: cachedStatus,
        context: context,
        binding: binding,
        token: token,
      );

      return switch (status.compareResult) {
        StoreVersionCompareResult.remoteMissing ||
        StoreVersionCompareResult.localNewer => await _uploadIfAllowed(
          status: status,
          context: context,
          binding: binding,
          token: token,
          autoUploadEnabled: autoUploadEnabled,
        ),
        StoreVersionCompareResult.same => _completeWithOutcome(
          _service.skipped(MainStoreCloseSyncOutcomeType.alreadySynced),
          logMessage:
              'Skipping snapshot upload after close because local and remote versions match.',
          logData: <String, dynamic>{'storeUuid': context.storeInfo.id},
        ),
        StoreVersionCompareResult.remoteNewer ||
        StoreVersionCompareResult.conflict ||
        StoreVersionCompareResult.differentStore => _completeWithOutcome(
          _service.skipped(
            MainStoreCloseSyncOutcomeType.manualResolutionRequired,
          ),
          logMessage:
              'Skipping snapshot upload after close because manual resolution is required.',
          logData: <String, dynamic>{
            'storeUuid': context.storeInfo.id,
            'compareResult': status.compareResult.name,
          },
          warning: true,
        ),
      };
    } catch (error, stackTrace) {
      final closeSyncError = _service.buildCloseSyncFailure(
        error,
        stackTrace: stackTrace,
      );
      logError(
        'Snapshot sync after close failed: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      ref.read(closeSyncTrackingProvider.notifier).markUploadRequired();
      _setState(
        _current.copyWith(
          phase: MainStoreCloseSyncPhase.failed,
          error: closeSyncError,
        ),
      );
      return Failure(closeSyncError);
    }
  }

  Future<bool> shouldAllowCloseWithoutSyncFailure(AppError error) async {
    return _service.shouldAllowCloseWithoutSyncFailure(
      autoUploadEnabled: await _isAutoUploadEnabled(),
      error: error,
    );
  }

  void resolveUploadDecision(bool shouldUpload) {
    final decision = _closeStoreUploadDecision;
    if (decision == null || decision.isCompleted) {
      return;
    }
    decision.complete(shouldUpload);
  }

  void resolveCloseStoreUploadDecision(bool shouldUpload) {
    resolveUploadDecision(shouldUpload);
  }

  void markSnapshotUploadOnCloseRequired() {
    ref.read(closeSyncTrackingProvider.notifier).markUploadRequired();
  }

  void syncPendingSnapshotUploadPrompt({
    required bool isStoreOpen,
    required String? currentStorePath,
    required String? storeUuid,
    required String? statusStorePath,
    required bool hasBinding,
    required StoreVersionCompareResult? compareResult,
  }) {
    final isCurrentStore =
        storeUuid != null &&
        currentStorePath != null &&
        statusStorePath != null &&
        isStoreOpen &&
        currentStorePath == statusStorePath;

    ref
        .read(closeSyncTrackingProvider.notifier)
        .setPendingPrompt(
          isCurrentStore &&
              hasBinding &&
              (compareResult == StoreVersionCompareResult.remoteMissing ||
                  compareResult == StoreVersionCompareResult.localNewer),
        );
  }

  void reset() {
    _completePendingDecisionAsSkipped();
    ref.read(closeStoreSyncStatusProvider.notifier).clear();
    _setState(const MainStoreCloseSyncState());
  }

  void clearPublishedStatus() {
    ref.read(closeStoreSyncStatusProvider.notifier).clear();
    _setState(_current.copyWith(clearStatus: true));
  }

  Future<StoreSyncStatus> _loadStatus({
    required StoreSyncStatus? cachedStatus,
    required _CloseSyncContext context,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
  }) {
    final syncService = ref.read(snapshotSyncServiceProvider);
    if (cachedStatus != null) {
      return syncService.rebuildStatusWithKnownRemote(
        storePath: context.storePath,
        storeInfo: context.storeInfo,
        binding: binding,
        token: token,
        remoteManifest: cachedStatus.remoteManifest,
        persistLocalSnapshot: true,
        allowLocalRevisionBump: true,
        remoteCheckSkippedOffline: false,
      );
    }

    return syncService.loadStatus(
      storePath: context.storePath,
      storeInfo: context.storeInfo,
      binding: binding,
      token: token,
      persistLocalSnapshot: true,
      allowLocalRevisionBump: true,
    );
  }

  AsyncResultDart<MainStoreCloseSyncOutcome, AppError> _uploadIfAllowed({
    required StoreSyncStatus status,
    required _CloseSyncContext context,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    required bool autoUploadEnabled,
  }) async {
    final shouldUpload = await _resolveUploadDecision(
      status: status,
      autoUploadEnabled: autoUploadEnabled,
    );

    if (!shouldUpload) {
      clearPublishedStatus();
      logInfo(
        'Skipping snapshot upload after close by user choice.',
        tag: _logTag,
        data: <String, dynamic>{'storeUuid': context.storeInfo.id},
      );
      return _completeWithOutcome(
        _service.skipped(MainStoreCloseSyncOutcomeType.skippedByUser),
      );
    }

    final baseStatus = _service.closeSyncBaseStatus(
      status: status,
      storePath: context.storePath,
      storeInfo: context.storeInfo,
      binding: binding,
      token: token,
    );
    _publishStatus(baseStatus, phase: MainStoreCloseSyncPhase.syncing);

    try {
      final result = await _consumeProgressStream(
        baseStatus: baseStatus,
        stream: ref
            .read(snapshotSyncServiceProvider)
            .syncWithProgress(
              storePath: context.storePath,
              storeInfo: context.storeInfo,
              binding: binding,
            ),
      );

      _publishStatus(
        baseStatus.copyWith(
          localManifest: result.localManifest,
          remoteManifest: result.remoteManifest,
          lastResultType: result.type,
          clearSyncProgress: true,
          isSyncInProgress: false,
        ),
        phase: MainStoreCloseSyncPhase.syncing,
      );

      logInfo(
        'Snapshot sync after close completed.',
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': context.storeInfo.id,
          'resultType': result.type.name,
        },
      );
      return _completeWithOutcome(_service.uploaded(result.type));
    } catch (error, stackTrace) {
      _reportManualReauthIfNeeded(
        error,
        binding: binding,
        token: token,
        storeUuid: binding.storeUuid,
        storePath: context.storePath,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<bool> _resolveUploadDecision({
    required StoreSyncStatus status,
    required bool autoUploadEnabled,
  }) async {
    final existing = _closeStoreUploadDecision;
    if (existing != null) {
      return existing.future;
    }

    if (autoUploadEnabled) {
      logInfo(
        'Skipping close-store snapshot upload prompt because auto-upload setting is enabled.',
        tag: _logTag,
        data: <String, dynamic>{
          'storeUuid': status.storeUuid,
          'compareResult': status.compareResult.name,
        },
      );
      return true;
    }

    ref.read(closeSyncTrackingProvider.notifier).setPendingPrompt(true);
    _publishStatus(
      _service.closePromptStatus(status),
      phase: MainStoreCloseSyncPhase.waitingForDecision,
    );

    final completer = Completer<bool>();
    _closeStoreUploadDecision = completer;
    return completer.future.whenComplete(() {
      if (identical(_closeStoreUploadDecision, completer)) {
        _closeStoreUploadDecision = null;
      }
    });
  }

  Future<SnapshotSyncResult> _consumeProgressStream({
    required StoreSyncStatus baseStatus,
    required Stream<SnapshotSyncProgressEvent> stream,
  }) async {
    SnapshotSyncResult? result;
    await for (final event in stream) {
      if (event is SnapshotSyncProgressUpdate) {
        _publishStatus(
          baseStatus.copyWith(
            syncProgress: event.progress,
            isSyncInProgress: true,
          ),
          phase: MainStoreCloseSyncPhase.syncing,
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

  ResultDart<MainStoreCloseSyncOutcome, AppError> _completeWithOutcome(
    MainStoreCloseSyncOutcome outcome, {
    String? logMessage,
    Map<String, dynamic>? logData,
    bool warning = false,
  }) {
    if (logMessage != null) {
      if (warning) {
        logWarning(logMessage, tag: _logTag, data: logData);
      } else {
        logDebug(logMessage, tag: _logTag, data: logData);
      }
    }

    if (outcome.clearsTracking) {
      ref.read(closeSyncTrackingProvider.notifier).markUploadedOrNotNeeded();
    }

    _setState(
      _current.copyWith(
        phase: outcome.completedUpload
            ? MainStoreCloseSyncPhase.completed
            : MainStoreCloseSyncPhase.skipped,
        outcome: outcome,
        clearError: true,
      ),
    );
    return Success(outcome);
  }

  void _publishStatus(
    StoreSyncStatus? status, {
    required MainStoreCloseSyncPhase phase,
  }) {
    ref.read(closeStoreSyncStatusProvider.notifier).setStatus(status);
    _setState(
      _current.copyWith(
        phase: phase,
        status: status,
        clearStatus: status == null,
        clearError: true,
      ),
    );
  }

  void _setState(MainStoreCloseSyncState nextState) {
    state = AsyncData(nextState);
  }

  void _completePendingDecisionAsSkipped() {
    final decision = _closeStoreUploadDecision;
    if (decision != null && !decision.isCompleted) {
      decision.complete(false);
    }
    _closeStoreUploadDecision = null;
  }

  Future<bool> _isAutoUploadEnabled() {
    return getIt<PreferencesService>().settingsPrefs
        .getAutoUploadSnapshotOnCloseEnabled();
  }

  Future<bool> _hasInternetAccessForCloseSync() async {
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

class _CloseSyncContext {
  const _CloseSyncContext({required this.storePath, required this.storeInfo});

  final String storePath;
  final StoreInfoDto storeInfo;
}
