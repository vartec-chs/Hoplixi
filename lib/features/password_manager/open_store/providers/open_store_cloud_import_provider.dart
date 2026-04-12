import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_cloud_import_state.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/features/password_manager/open_store/providers/open_store_form_provider.dart';

final openStoreCloudImportProvider =
    AsyncNotifierProvider.autoDispose<
      OpenStoreCloudImportNotifier,
      OpenStoreCloudImportState
    >(OpenStoreCloudImportNotifier.new);

class OpenStoreCloudImportNotifier
    extends AsyncNotifier<OpenStoreCloudImportState> {
  bool get _isMounted => ref.mounted;

  @override
  Future<OpenStoreCloudImportState> build() async {
    Future.microtask(reloadCloudOptions);
    return const OpenStoreCloudImportState();
  }

  OpenStoreCloudImportState get _currentState =>
      state.value ?? const OpenStoreCloudImportState();

  void _setState(OpenStoreCloudImportState newState) {
    state = AsyncData(newState);
  }

  Future<void> reloadCloudOptions() async {
    try {
      final tokens = await ref.read(authTokensProvider.future);
      if (!_isMounted) {
        return;
      }

      final grouped = _groupTokensByProvider(tokens);
      final currentState = _currentState;
      final selectedProvider =
          currentState.selectedCloudProvider ??
          _firstProviderWithTokens(grouped);
      final providerTokens = selectedProvider == null
          ? const <AuthTokenEntry>[]
          : (grouped[selectedProvider] ?? const <AuthTokenEntry>[]);
      final selectedTokenId =
          providerTokens.any(
            (token) => token.id == currentState.selectedCloudTokenId,
          )
          ? currentState.selectedCloudTokenId
          : (providerTokens.isNotEmpty ? providerTokens.first.id : null);

      _setState(
        currentState.copyWith(
          cloudTokensByProvider: grouped,
          selectedCloudProvider: selectedProvider,
          selectedCloudTokenId: selectedTokenId,
          remoteSnapshots: selectedTokenId == null
              ? const <CloudManifestStoreEntry>[]
              : currentState.remoteSnapshots,
          remoteSnapshotsError: selectedTokenId == null
              ? null
              : currentState.remoteSnapshotsError,
        ),
      );

      if (selectedTokenId == null) {
        return;
      }

      await _loadRemoteSnapshots(selectedTokenId);
    } catch (error, stackTrace) {
      logError(
        'Error loading cloud tokens: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreCloudImport',
      );
      if (!_isMounted) {
        return;
      }

      _setState(
        _currentState.copyWith(
          remoteSnapshots: const <CloudManifestStoreEntry>[],
          remoteSnapshotsError: 'Ошибка загрузки OAuth токенов: $error',
          isLoadingRemoteSnapshots: false,
        ),
      );
    }
  }

  Future<void> selectCloudProvider(CloudSyncProvider? provider) async {
    if (!_isMounted) {
      return;
    }

    final providerTokens = provider == null
        ? const <AuthTokenEntry>[]
        : (_currentState.cloudTokensByProvider[provider] ??
              const <AuthTokenEntry>[]);
    final tokenId = providerTokens.isNotEmpty ? providerTokens.first.id : null;

    _setState(
      _currentState.copyWith(
        selectedCloudProvider: provider,
        selectedCloudTokenId: tokenId,
        remoteSnapshots: tokenId == null
            ? const <CloudManifestStoreEntry>[]
            : _currentState.remoteSnapshots,
        remoteSnapshotsError: null,
      ),
    );

    if (tokenId == null) {
      return;
    }

    await _loadRemoteSnapshots(tokenId);
  }

  Future<void> selectCloudToken(String? tokenId) async {
    if (!_isMounted) {
      return;
    }

    _setState(
      _currentState.copyWith(
        selectedCloudTokenId: tokenId,
        remoteSnapshots: tokenId == null
            ? const <CloudManifestStoreEntry>[]
            : _currentState.remoteSnapshots,
        remoteSnapshotsError: null,
      ),
    );

    if (tokenId == null) {
      return;
    }

    await _loadRemoteSnapshots(tokenId);
  }

  Future<ImportedRemoteStoreResult?> importRemoteSnapshot(
    CloudManifestStoreEntry entry,
  ) async {
    final currentState = _currentState;
    final tokenId = currentState.selectedCloudTokenId;
    final provider = currentState.selectedCloudProvider;
    final token = _selectedToken;
    if (tokenId == null || provider == null || token == null) {
      _setState(
        currentState.copyWith(
          remoteSnapshotsError:
              'Выберите провайдера и OAuth токен перед импортом.',
        ),
      );
      return null;
    }

    _setState(
      currentState.copyWith(
        downloadingRemoteStoreUuid: entry.storeUuid,
        remoteSnapshotsError: null,
      ),
    );

    try {
      final baseStoragePath = await AppPaths.appStoragesPath;
      if (!_isMounted) {
        return null;
      }

      final result = await ref
          .read(snapshotSyncServiceProvider)
          .importRemoteStoreToLocal(
            tokenId: tokenId,
            storeUuid: entry.storeUuid,
            baseStoragePath: baseStoragePath,
          );

      if (!_isMounted) {
        return null;
      }

      await ref.read(openStoreFormProvider.notifier).loadStorages();
      if (!_isMounted) {
        return null;
      }

      _setState(
        _currentState.copyWith(
          downloadingRemoteStoreUuid: null,
          pendingImportedStoreBinding: PendingImportedStoreBinding(
            localStoreUuid: result.remoteManifest.storeUuid,
            localStoreName: result.remoteManifest.storeName,
            localStoragePath: result.storagePath,
            remoteStoreUuid: entry.storeUuid,
            tokenId: tokenId,
            provider: provider,
            accountLabel: token.displayLabel,
          ),
        ),
      );

      return result;
    } catch (error, stackTrace) {
      logError(
        'Error importing remote snapshot: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreCloudImport',
      );
      if (!_isMounted) {
        return null;
      }

      _setState(
        _currentState.copyWith(
          downloadingRemoteStoreUuid: null,
          remoteSnapshotsError: 'Ошибка скачивания снапшота: $error',
        ),
      );
      return null;
    }
  }

  Future<bool> deleteRemoteSnapshot(CloudManifestStoreEntry entry) async {
    final currentState = _currentState;
    final tokenId = currentState.selectedCloudTokenId;
    final provider = currentState.selectedCloudProvider;
    if (tokenId == null || provider == null) {
      _setState(
        currentState.copyWith(
          remoteSnapshotsError:
              'Выберите провайдера и OAuth токен перед удалением снапшота.',
        ),
      );
      return false;
    }

    _setState(currentState.copyWith(remoteSnapshotsError: null));

    try {
      await ref
          .read(snapshotSyncServiceProvider)
          .deleteRemoteSnapshot(tokenId: tokenId, entry: entry);
      if (!_isMounted) {
        return false;
      }

      await _loadRemoteSnapshots(tokenId);
      return true;
    } catch (error, stackTrace) {
      logError(
        'Error deleting remote snapshot: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreCloudImport',
      );
      if (!_isMounted) {
        return false;
      }

      _setState(
        _currentState.copyWith(
          remoteSnapshotsError: 'Ошибка удаления снапшота: $error',
        ),
      );
      return false;
    }
  }

  Future<bool> resolvePendingImportedStoreBinding({required bool bind}) async {
    final pending = _currentState.pendingImportedStoreBinding;
    if (pending == null) {
      return false;
    }

    if (!bind) {
      _setState(_currentState.copyWith(pendingImportedStoreBinding: null));
      return false;
    }

    try {
      await ref
          .read(storeSyncBindingServiceProvider)
          .saveBinding(
            storeUuid: pending.localStoreUuid,
            tokenId: pending.tokenId,
            provider: pending.provider,
          );
      if (!_isMounted) {
        return false;
      }

      _setState(_currentState.copyWith(pendingImportedStoreBinding: null));
      return true;
    } catch (error, stackTrace) {
      logError(
        'Error saving imported store binding: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreCloudImport',
      );
      if (!_isMounted) {
        return false;
      }

      _setState(
        _currentState.copyWith(
          pendingImportedStoreBinding: null,
          remoteSnapshotsError: 'Не удалось сохранить привязку: $error',
        ),
      );
      return false;
    }
  }

  void clearRemoteSnapshotsError() {
    if (!_isMounted) {
      return;
    }

    _setState(_currentState.copyWith(remoteSnapshotsError: null));
  }

  Future<void> _loadRemoteSnapshots(String tokenId) async {
    if (!_isMounted) {
      return;
    }

    _setState(
      _currentState.copyWith(
        isLoadingRemoteSnapshots: true,
        remoteSnapshotsError: null,
      ),
    );

    try {
      final cloudManifest = await ref
          .read(snapshotSyncRepositoryProvider)
          .readCloudManifest(tokenId);
      if (!_isMounted) {
        return;
      }

      final snapshots =
          (cloudManifest?.stores ?? const <CloudManifestStoreEntry>[])
              .where((entry) => !entry.deleted)
              .toList(growable: false)
            ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

      if (_currentState.selectedCloudTokenId != tokenId) {
        return;
      }

      _setState(
        _currentState.copyWith(
          remoteSnapshots: snapshots,
          isLoadingRemoteSnapshots: false,
          remoteSnapshotsError: null,
        ),
      );
    } catch (error, stackTrace) {
      logError(
        'Error loading remote snapshots: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreCloudImport',
      );
      _reportManualReauthIfNeeded(error, tokenId: tokenId);
      if (!_isMounted || _currentState.selectedCloudTokenId != tokenId) {
        return;
      }

      _setState(
        _currentState.copyWith(
          remoteSnapshots: const <CloudManifestStoreEntry>[],
          isLoadingRemoteSnapshots: false,
          remoteSnapshotsError: 'Ошибка загрузки cloud manifest: $error',
        ),
      );
    }
  }

  void _reportManualReauthIfNeeded(Object error, {required String tokenId}) {
    final cloudError = error is CloudStorageException ? error : null;
    if (cloudError == null ||
        cloudError.type != CloudStorageExceptionType.unauthorized) {
      return;
    }

    final token = _selectedToken;
    final provider =
        token?.provider ??
        _currentState.selectedCloudProvider ??
        cloudError.provider;
    if (provider == null) {
      return;
    }

    final description = switch (cloudError.cause) {
      CloudSyncHttpException(type: CloudSyncHttpExceptionType.refreshFailed) =>
        'Не удалось автоматически обновить OAuth-токен. Требуется повторная ручная авторизация.',
      CloudSyncHttpException(type: CloudSyncHttpExceptionType.unauthorized) =>
        'Облачный провайдер отклонил текущий токен. Требуется повторная ручная авторизация.',
      _ => 'Текущий OAuth-токен больше не подходит для доступа к облаку.',
    };

    ref
        .read(currentStoreSyncManualReauthIssueProvider.notifier)
        .report(
          CurrentStoreSyncManualReauthIssue(
            kind: CurrentStoreSyncIssueKind.manualReauthRequired,
            tokenId: tokenId,
            provider: provider,
            tokenLabel: token?.displayLabel,
            description: description,
          ),
        );
  }

  Map<CloudSyncProvider, List<AuthTokenEntry>> _groupTokensByProvider(
    List<AuthTokenEntry> tokens,
  ) {
    final grouped = <CloudSyncProvider, List<AuthTokenEntry>>{};
    for (final provider in CloudSyncProvider.values) {
      grouped[provider] = tokens
          .where((token) => token.provider == provider)
          .toList(growable: false);
    }
    return grouped;
  }

  CloudSyncProvider? _firstProviderWithTokens(
    Map<CloudSyncProvider, List<AuthTokenEntry>> grouped,
  ) {
    for (final provider in CloudSyncProvider.values) {
      final tokens = grouped[provider] ?? const <AuthTokenEntry>[];
      if (tokens.isNotEmpty) {
        return provider;
      }
    }
    return null;
  }

  AuthTokenEntry? get _selectedToken {
    final tokenId = _currentState.selectedCloudTokenId;
    if (tokenId == null) {
      return null;
    }

    for (final tokens in _currentState.cloudTokensByProvider.values) {
      for (final token in tokens) {
        if (token.id == tokenId) {
          return token;
        }
      }
    }
    return null;
  }
}
