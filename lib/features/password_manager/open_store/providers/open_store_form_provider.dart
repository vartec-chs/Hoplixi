import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_manifest.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/services/snapshot_sync_service.dart';
import 'package:hoplixi/features/password_manager/open_store/models/open_store_state.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/provider/db_history_provider.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:path/path.dart' as p;

final openStoreFormProvider =
    AsyncNotifierProvider.autoDispose<OpenStoreFormNotifier, OpenStoreState>(
      OpenStoreFormNotifier.new,
    );

class OpenStoreFormNotifier extends AsyncNotifier<OpenStoreState> {
  bool get _isMounted => ref.mounted;

  @override
  Future<OpenStoreState> build() async {
    final initialState = const OpenStoreState();
    Future.microtask(_loadInitialData);
    return initialState;
  }

  OpenStoreState get _currentState => state.value ?? const OpenStoreState();

  void _setState(OpenStoreState newState) {
    state = AsyncData(newState);
  }

  Future<void> _loadInitialData() async {
    await loadStorages();
    if (!_isMounted) {
      return;
    }
    await reloadCloudOptions();
  }

  Future<void> loadStorages() async {
    if (!_isMounted) {
      return;
    }

    final currentState = _currentState;
    _setState(currentState.copyWith(isLoading: true, error: null));

    try {
      final storages = <StorageInfo>[];

      final historyStorages = await _loadFromHistory();
      if (!_isMounted) {
        return;
      }
      storages.addAll(historyStorages);

      final folderStorages = await _loadFromFolder();
      if (!_isMounted) {
        return;
      }
      for (final storage in folderStorages) {
        if (!storages.any((item) => item.path == storage.path)) {
          storages.add(storage);
        }
      }

      final backupStorages = await _loadFromBackups();
      if (!_isMounted) {
        return;
      }
      for (final storage in backupStorages) {
        if (!storages.any((item) => item.path == storage.path)) {
          storages.add(storage);
        }
      }

      storages.sort((left, right) {
        if (left.fromHistory && !right.fromHistory) return -1;
        if (!left.fromHistory && right.fromHistory) return 1;

        if (left.fromHistory && right.fromHistory) {
          return (right.lastOpenedAt ?? DateTime(0)).compareTo(
            left.lastOpenedAt ?? DateTime(0),
          );
        }

        return right.modifiedAt.compareTo(left.modifiedAt);
      });

      if (!_isMounted) {
        return;
      }

      _setState(
        _currentState.copyWith(
          storages: storages,
          isLoading: false,
          error: null,
        ),
      );
      logInfo('Loaded ${storages.length} storages', tag: 'OpenStoreForm');
    } catch (error, stackTrace) {
      logError(
        'Error loading storages: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      if (!_isMounted) {
        return;
      }

      _setState(
        _currentState.copyWith(
          isLoading: false,
          error: 'Ошибка загрузки списка хранилищ: $error',
        ),
      );
    }
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
        tag: 'OpenStoreForm',
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

      await loadStorages();
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
        tag: 'OpenStoreForm',
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
        tag: 'OpenStoreForm',
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
        tag: 'OpenStoreForm',
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

  void selectStorage(StorageInfo storage) {
    if (!_isMounted) {
      return;
    }

    _setState(
      _currentState.copyWith(
        selectedStorage: storage,
        password: '',
        passwordError: null,
        error: null,
      ),
    );
  }

  void updatePassword(String password) {
    if (!_isMounted) {
      return;
    }

    _setState(_currentState.copyWith(password: password, passwordError: null));
  }

  Future<bool> openStorage() async {
    final currentState = _currentState;

    if (currentState.selectedStorage == null) {
      _setState(currentState.copyWith(error: 'Хранилище не выбрано'));
      return false;
    }

    if (currentState.password.isEmpty) {
      _setState(currentState.copyWith(passwordError: 'Введите пароль'));
      return false;
    }

    _setState(
      currentState.copyWith(isOpening: true, passwordError: null, error: null),
    );

    try {
      final dto = OpenStoreDto(
        path: currentState.selectedStorage!.path,
        password: currentState.password,
      );

      final storeNotifier = ref.read(mainStoreProvider.notifier);
      final success = await storeNotifier.openStore(dto);
      if (!_isMounted) {
        return false;
      }

      if (success) {
        logInfo(
          'Store opened successfully: ${currentState.selectedStorage!.name}',
          tag: 'OpenStoreForm',
        );
        return true;
      }

      final storeState = await ref.read(mainStoreProvider.future);
      if (!_isMounted) {
        return false;
      }

      final errorMessage =
          storeState.error?.message ?? 'Не удалось открыть хранилище';
      _setState(
        _currentState.copyWith(isOpening: false, passwordError: errorMessage),
      );
      return false;
    } catch (error, stackTrace) {
      logError(
        'Error opening store: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      if (!_isMounted) {
        return false;
      }

      _setState(
        _currentState.copyWith(
          isOpening: false,
          error: 'Ошибка при открытии: $error',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteStorage(String path) async {
    try {
      if (!_isMounted) {
        return false;
      }

      final storeNotifier = ref.read(mainStoreProvider.notifier);
      final dir = Directory(path).parent;
      final success = await storeNotifier.deleteStoreFromDisk(dir.path);
      if (!_isMounted) {
        return false;
      }

      if (!success) {
        return false;
      }

      await loadStorages();
      return true;
    } catch (error, stackTrace) {
      logError(
        'Error deleting storage: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return false;
    }
  }

  void reset() {
    if (!_isMounted) {
      return;
    }
    _setState(const OpenStoreState());
  }

  void cancelSelection() {
    if (!_isMounted) {
      return;
    }

    _setState(
      _currentState.copyWith(
        selectedStorage: null,
        password: '',
        passwordError: null,
      ),
    );
  }

  Future<List<StorageInfo>> _loadFromHistory() async {
    try {
      final historyService = await ref.read(dbHistoryProvider.future);
      if (!_isMounted) {
        return [];
      }

      final history = await historyService.getRecent(limit: 10);
      if (!_isMounted) {
        return [];
      }

      final storages = <StorageInfo>[];
      for (final entry in history) {
        final dir = Directory(entry.path);
        if (!await dir.exists()) {
          continue;
        }

        final files = await dir
            .list()
            .where(
              (entity) =>
                  entity is File &&
                  entity.path.endsWith(MainConstants.dbExtension),
            )
            .toList();
        if (files.isEmpty) {
          continue;
        }

        final dbFile = File(files.first.path);
        final stat = await dbFile.stat();
        storages.add(
          StorageInfo(
            name: entry.name,
            path: dbFile.path,
            modifiedAt: stat.modified,
            description: entry.description,
            size: stat.size,
            fromHistory: true,
            lastOpenedAt: entry.lastAccessed,
          ),
        );
      }

      return storages;
    } catch (error, stackTrace) {
      logError(
        'Error loading from history: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }

  Future<List<StorageInfo>> _loadFromFolder() async {
    try {
      final storagePath = await AppPaths.appStoragesPath;
      if (!_isMounted) {
        return [];
      }

      final storageDir = Directory(storagePath);
      if (!await storageDir.exists()) {
        return [];
      }

      final storages = <StorageInfo>[];
      await for (final entity in storageDir.list()) {
        if (entity is! Directory) {
          continue;
        }

        if (!await entity.exists()) {
          continue;
        }

        final files = await entity
            .list()
            .where(
              (item) =>
                  item is File && item.path.endsWith(MainConstants.dbExtension),
            )
            .toList();
        if (files.isEmpty) {
          continue;
        }

        final dbFile = File(files.first.path);
        final stat = await dbFile.stat();
        storages.add(
          StorageInfo(
            name: p.basename(entity.path),
            path: dbFile.path,
            modifiedAt: stat.modified,
            size: stat.size,
            fromHistory: false,
          ),
        );
      }

      return storages;
    } catch (error, stackTrace) {
      logError(
        'Error scanning storage folder: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
  }

  Future<List<StorageInfo>> _loadFromBackups() async {
    try {
      final backupsPath = await AppPaths.backupsPath;
      if (!_isMounted) {
        return [];
      }

      final backupsDir = Directory(backupsPath);
      if (!await backupsDir.exists()) {
        return [];
      }

      final storages = <StorageInfo>[];
      await for (final entity in backupsDir.list(recursive: false)) {
        if (entity is! Directory) {
          continue;
        }

        final files = await entity
            .list(recursive: false)
            .where(
              (item) =>
                  item is File && item.path.endsWith(MainConstants.dbExtension),
            )
            .toList();
        if (files.isEmpty) {
          continue;
        }

        final dbFile = File(files.first.path);
        final stat = await dbFile.stat();
        storages.add(
          StorageInfo(
            name: p.basename(entity.path),
            path: dbFile.path,
            modifiedAt: stat.modified,
            size: stat.size,
            fromHistory: false,
            description: 'Бэкап',
          ),
        );
      }

      return storages;
    } catch (error, stackTrace) {
      logError(
        'Error scanning backups folder: $error',
        stackTrace: stackTrace,
        tag: 'OpenStoreForm',
      );
      return [];
    }
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
        tag: 'OpenStoreForm',
      );
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
