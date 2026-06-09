import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/home/recent_database/models/cloud_version_check_data.dart';
import 'package:hoplixi/features/home/recent_database/models/recent_database_cloud_sync_state.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';
import 'package:hoplixi/vault_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/vault_db/services/store_manifest_service/store_manifest_service.dart';

final recentDatabaseCloudSyncControllerProvider =
    NotifierProvider.autoDispose<
      RecentDatabaseCloudSyncController,
      RecentDatabaseCloudSyncState
    >(RecentDatabaseCloudSyncController.new);

class RecentDatabaseCloudSyncController
    extends Notifier<RecentDatabaseCloudSyncState> {
  @override
  RecentDatabaseCloudSyncState build() {
    return const RecentDatabaseCloudSyncState.idle();
  }

  Future<void> checkAndInstallLatestVersion(DatabaseEntry entry) async {
    if (state.isChecking) return;

    state = state.copyWith(
      isChecking: true,
      progress: const SnapshotSyncProgress(
        stage: SnapshotSyncStage.preparingLocalSnapshot,
        stepIndex: 1,
        totalSteps: 6,
        title: 'Подготовка локального снимка',
        description: 'Читаем локальный manifest и готовим проверку облака.',
      ),
    );

    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final checkData = await _loadCloudVersionCheckData(entry);
        if (checkData == null) {
          return;
        }

        try {
          await _runCloudVersionCheckAttempt(
            entry: entry,
            manifest: checkData.manifest,
            binding: checkData.binding,
            token: checkData.token,
          );
          return;
        } catch (error) {
          if (attempt == 0 && _shouldRetryCloudVersionCheck(error)) {
            await ref.read(authTokensProvider.notifier).reload();
            continue;
          }

          _reportManualReauthIfNeeded(
            error,
            manifest: checkData.manifest,
            binding: checkData.binding,
            token: checkData.token,
            storePath: entry.path,
          );
          rethrow;
        }
      }
    } catch (error) {
      Toaster.error(
        title: 'Cloud Sync',
        description: _buildCloudSyncErrorMessage(error),
      );
    } finally {
      state = const RecentDatabaseCloudSyncState.idle();
    }
  }

  void _setProgress(SnapshotSyncProgress progress) {
    state = state.copyWith(progress: progress);
  }

  Future<CloudVersionCheckData?> _loadCloudVersionCheckData(
    DatabaseEntry entry,
  ) async {
    final manifest = await StoreManifestService.readFrom(entry.path);
    final syncProvider = manifest?.sync?.provider;
    if (manifest == null || syncProvider == null) {
      Toaster.info(
        title: 'Cloud Sync',
        description:
            'У этого хранилища нет сохранённой cloud sync конфигурации.',
      );
      return null;
    }

    final binding = await ref
        .read(storeSyncBindingServiceProvider)
        .getByStoreUuid(manifest.storeUuid);
    if (binding == null) {
      Toaster.warning(
        title: 'Cloud Sync',
        description:
            'В store_manifest есть sync-метаданные, но локальная привязка токена не найдена.',
      );
      return null;
    }

    final token = await ref
        .read(authTokensProvider.notifier)
        .getTokenById(binding.tokenId);
    if (token == null) {
      _reportMissingTokenIssue(manifest: manifest, binding: binding);
      Toaster.warning(
        title: 'Cloud Sync',
        description:
            'Связанный OAuth-токен отсутствует. Нужна повторная авторизация.',
      );
      return null;
    }

    return CloudVersionCheckData(
      manifest: manifest,
      binding: binding,
      token: token,
    );
  }

  Future<void> _runCloudVersionCheckAttempt({
    required DatabaseEntry entry,
    required StoreManifest manifest,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
  }) async {
    final syncService = ref.read(snapshotSyncServiceProvider);
    _setProgress(
      const SnapshotSyncProgress(
        stage: SnapshotSyncStage.checkingRemoteVersion,
        stepIndex: 2,
        totalSteps: 6,
        title: 'Проверка облачной версии',
        description: 'Читаем удалённый manifest и сравниваем версии.',
      ),
    );
    final status = await syncService.loadStatus(
      storePath: entry.path,
      storeInfo: _buildStoreInfo(entry, manifest),
      binding: binding,
      token: token,
    );

    switch (status.compareResult) {
      case StoreVersionCompareResult.remoteNewer:
        _setProgress(
          const SnapshotSyncProgress(
            stage: SnapshotSyncStage.transferringPrimaryFiles,
            stepIndex: 3,
            totalSteps: 6,
            title: 'Скачивание из облака',
            description: 'Загружаем более новую remote snapshot-версию.',
          ),
        );
        await syncService.downloadRemoteSnapshot(
          storePath: entry.path,
          binding: binding,
          lockBeforeApply: false,
          emitProgress: (progress) {
            _setProgress(progress);
          },
        );
        Toaster.success(
          title: 'Cloud Sync',
          description:
              'Новая версия из ${binding.provider.metadata.displayName} установлена локально.',
        );
        break;
      case StoreVersionCompareResult.same:
        Toaster.info(
          title: 'Cloud Sync',
          description: 'Локальная версия уже совпадает с облачной.',
        );
        break;
      case StoreVersionCompareResult.remoteMissing:
        Toaster.info(
          title: 'Cloud Sync',
          description: 'В облаке ещё нет snapshot для этого хранилища.',
        );
        break;
      case StoreVersionCompareResult.localNewer:
        Toaster.info(
          title: 'Cloud Sync',
          description:
              'Локальная версия новее облачной. Для отправки изменений откройте хранилище и выполните sync.',
        );
        break;
      case StoreVersionCompareResult.conflict:
        Toaster.warning(
          title: 'Cloud Sync',
          description:
              'Обнаружен конфликт локальной и удалённой версий. Откройте хранилище для ручного разрешения.',
        );
        break;
      case StoreVersionCompareResult.differentStore:
        Toaster.error(
          title: 'Cloud Sync',
          description:
              'Удалённый manifest относится к другому хранилищу. Проверьте привязку sync.',
        );
        break;
    }
  }

  bool _shouldRetryCloudVersionCheck(Object error) {
    if (error case CloudStorageException(type: final type)) {
      return type == CloudStorageExceptionType.unauthorized ||
          type == CloudStorageExceptionType.timeout;
    }

    if (error case CloudSyncHttpException(type: final type)) {
      return type == CloudSyncHttpExceptionType.unauthorized ||
          type == CloudSyncHttpExceptionType.refreshFailed ||
          type == CloudSyncHttpExceptionType.timeout;
    }

    return false;
  }

  StoreInfoDto _buildStoreInfo(DatabaseEntry entry, StoreManifest manifest) {
    final fallbackDate = manifest.updatedAt.toUtc();
    return StoreInfoDto(
      id: manifest.storeUuid,
      name: manifest.storeName.trim().isEmpty ? entry.name : manifest.storeName,
      description: entry.description,
      createdAt: entry.createdAt ?? fallbackDate,
      modifiedAt: manifest.content.dbFile.modifiedAt?.toUtc() ?? fallbackDate,
      lastOpenedAt: entry.lastAccessed ?? fallbackDate,
    );
  }

  void _reportMissingTokenIssue({
    required StoreManifest manifest,
    required StoreSyncBinding binding,
  }) {
    ref
        .read(currentStoreSyncManualReauthIssueProvider.notifier)
        .report(
          CurrentStoreSyncManualReauthIssue(
            kind: CurrentStoreSyncIssueKind.missingToken,
            tokenId: binding.tokenId,
            provider: binding.provider,
            storeUuid: manifest.storeUuid,
            storePath: null,
            description:
                'В store_manifest указана активная cloud sync конфигурация, но связанный OAuth-токен отсутствует на устройстве.',
          ),
        );
  }

  void _reportManualReauthIfNeeded(
    Object error, {
    required StoreManifest manifest,
    required StoreSyncBinding binding,
    required AuthTokenEntry token,
    required String storePath,
  }) {
    if (error is! CloudStorageException ||
        error.type != CloudStorageExceptionType.unauthorized) {
      return;
    }

    final description = switch (error.cause) {
      CloudSyncHttpException(type: CloudSyncHttpExceptionType.refreshFailed) =>
        'Не удалось автоматически обновить OAuth-токен. Требуется повторная ручная авторизация.',
      CloudSyncHttpException(type: CloudSyncHttpExceptionType.unauthorized) =>
        'Облачный провайдер отклонил текущий токен. Требуется повторная ручная авторизация.',
      _ =>
        'Доступ к облачному провайдеру больше не подтверждается. Требуется повторная ручная авторизация.',
    };

    ref
        .read(currentStoreSyncManualReauthIssueProvider.notifier)
        .report(
          CurrentStoreSyncManualReauthIssue(
            kind: CurrentStoreSyncIssueKind.manualReauthRequired,
            tokenId: token.id,
            provider: binding.provider,
            storeUuid: manifest.storeUuid,
            storePath: storePath,
            tokenLabel: token.displayLabel,
            description: description,
          ),
        );
  }

  String _buildCloudSyncErrorMessage(Object error) {
    if (error is CloudStorageException) {
      return switch (error.type) {
        CloudStorageExceptionType.unauthorized =>
          'Авторизация cloud sync больше невалидна. Выполните вход заново.',
        CloudStorageExceptionType.network =>
          'Не удалось связаться с облаком. Проверьте интернет-соединение.',
        CloudStorageExceptionType.timeout =>
          'Облачный провайдер не ответил вовремя. Попробуйте ещё раз.',
        CloudStorageExceptionType.notFound => 'Удалённый snapshot не найден.',
        _ => error.message,
      };
    }
    return error.toString();
  }
}
