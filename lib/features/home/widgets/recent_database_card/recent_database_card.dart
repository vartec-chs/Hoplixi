import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/security_prefs.dart';
import 'package:hoplixi/core/services/local_auth_service/local_auth_failure.dart';
import 'package:hoplixi/core/services/local_auth_service/local_auth_service.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/cloud_store_lock.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_cloud_lock_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/features/password_manager/open_store/services/store_password_attempt_limiter_service.dart';
import 'package:hoplixi/main_db/core/models/dto/main_store_dto.dart';
import 'package:hoplixi/main_db/providers/db_history_provider.dart';
import 'package:hoplixi/main_db/providers/main_store_manager_provider.dart';
import 'package:hoplixi/main_db/services/db_history_services/model/db_history_model.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/main_db/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/main_db/services/vault_key_file_service.dart';
import 'package:hoplixi/main_db/ui/store_open_migration_dialog.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:typed_prefs/typed_prefs.dart';

import 'models/cloud_version_check_data.dart';
import 'widgets/cloud_sync_progress_panel.dart';
import 'widgets/password_dialog.dart';

final _recentDatabaseManifestProvider = FutureProvider.family
    .autoDispose<StoreManifest?, String>((ref, path) {
      return StoreManifestService.readFrom(path);
    });

class RecentDatabaseCard extends ConsumerStatefulWidget {
  const RecentDatabaseCard({super.key});

  @override
  ConsumerState<RecentDatabaseCard> createState() => _RecentDatabaseCardState();
}

class _RecentDatabaseCardState extends ConsumerState<RecentDatabaseCard> {
  bool _isCheckingCloudVersion = false;
  SnapshotSyncProgress? _cloudSyncProgress;

  @override
  Widget build(BuildContext context) {
    final recentDbAsync = ref.watch(recentDatabaseProvider);

    return recentDbAsync.when(
      data: (entry) {
        if (entry == null) return const SizedBox.shrink();
        return _buildCard(context, ref, entry);
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, DatabaseEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final dbStateAsync = ref.watch(mainStoreProvider);
    final dbState = dbStateAsync.value;
    final lockState = ref.watch(currentStoreCloudLockProvider);
    final manifestAsync = ref.watch(
      _recentDatabaseManifestProvider(entry.path),
    );
    final isOpening = dbState?.isOpening ?? false;
    final isCurrentStoreCard = dbState?.path == entry.path;
    final lockPhase = lockState.value?.phase;
    final isCloudLockChecking =
        isCurrentStoreCard &&
        ((lockState.isLoading && lockState.value == null) ||
            lockPhase == CloudStoreLockPhase.checking);
    final isCloudLockReleasing =
        isCurrentStoreCard &&
        (lockPhase == CloudStoreLockPhase.releasing ||
            (dbState?.isClosing ?? false));
    final syncProvider = manifestAsync.maybeWhen(
      data: (manifest) => manifest?.sync?.provider,
      orElse: () => null,
    );

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Недавнее хранилище',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash),
                  tooltip: 'Удалить из истории',
                  onPressed: () => _deleteFromHistory(context, ref, entry),
                  color: colorScheme.error,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (entry.description != null && entry.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              entry.path,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (syncProvider != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CloudSyncProviderLogo(
                      metadata: syncProvider.metadata,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Подключен Cloud Sync: ${syncProvider.metadata.displayName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isCloudLockChecking)
              const _CloudLockStatusBanner(
                icon: LucideIcons.cloudCog,
                title: 'Проверяем cloud lock',
                message:
                    'Кнопки появятся после проверки, что хранилище не открыто на другом устройстве.',
                showProgress: true,
              )
            else if (isCloudLockReleasing)
              const _CloudLockStatusBanner(
                icon: LucideIcons.cloudOff,
                title: 'Закрываем cloud-сессию',
                message:
                    'Удаляем lock-файл в облаке. Действия с хранилищем временно недоступны.',
                showProgress: true,
              )
            else ...[
              if (syncProvider != null) ...[
                SmoothButton(
                  label: _cloudSyncProgress == null
                      ? 'Проверить и установить новую версию'
                      : _buildProgressButtonLabel(_cloudSyncProgress!),
                  type: SmoothButtonType.outlined,
                  isFullWidth: true,
                  icon: CloudSyncProviderLogo(
                    metadata: syncProvider.metadata,
                    size: 20,
                  ),
                  loading: _isCheckingCloudVersion,
                  onPressed: (isOpening || _isCheckingCloudVersion)
                      ? null
                      : () => _checkCloudVersion(context, entry),
                ),
                const SizedBox(height: 12),
              ],
              if (_isCheckingCloudVersion)
                CloudSyncProgressPanel(progress: _cloudSyncProgress)
              else
                SmoothButton(
                  label: isOpening ? 'Открытие...' : 'Открыть',
                  type: SmoothButtonType.tonal,
                  isFullWidth: true,
                  icon: const Icon(LucideIcons.folderOpen),
                  loading: isOpening,
                  onPressed: isOpening
                      ? null
                      : () => _openDatabase(context, ref, entry),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkCloudVersion(
    BuildContext context,
    DatabaseEntry entry,
  ) async {
    if (_isCheckingCloudVersion) {
      return;
    }

    setState(() {
      _isCheckingCloudVersion = true;
      _cloudSyncProgress = const SnapshotSyncProgress(
        stage: SnapshotSyncStage.preparingLocalSnapshot,
        stepIndex: 1,
        totalSteps: 6,
        title: 'Подготовка локального снимка',
        description: 'Читаем локальный manifest и готовим проверку облака.',
      );
    });

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
      if (mounted) {
        setState(() {
          _isCheckingCloudVersion = false;
          _cloudSyncProgress = null;
        });
      }
    }
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
    _updateCloudSyncProgress(
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
        _updateCloudSyncProgress(
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
            _updateCloudSyncProgress(progress);
          },
        );
        ref.invalidate(_recentDatabaseManifestProvider(entry.path));
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

  void _updateCloudSyncProgress(SnapshotSyncProgress progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      _cloudSyncProgress = progress;
    });
  }

  String _buildProgressButtonLabel(SnapshotSyncProgress progress) {
    return '${progress.title} · шаг ${progress.stepIndex}/${progress.totalSteps}';
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
      version: manifest.version.toString(),
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

  Future<void> _openDatabase(
    BuildContext context,
    WidgetRef ref,
    DatabaseEntry entry,
  ) async {
    final notifier = ref.read(mainStoreProvider.notifier);
    final historyService = await ref.read(dbHistoryProvider.future);
    final attemptLimiter = getIt<StorePasswordAttemptLimiterService>();
    String? password;
    bool shouldSavePassword = false;
    bool usedManualPassword = false;

    // Если пользователь выбрал сохранение пароля, сначала подтверждаем доступ
    if (entry.savePassword) {
      final storageService = getIt<PreferencesService>();
      final isBiometricEnabled =
          await storageService.securityPrefs.biometricEnabled.get() ?? false;

      if (isBiometricEnabled) {
        final localAuthService = getIt<LocalAuthService>();
        final authResult = await localAuthService.authenticate(
          localizedReason: 'Подтвердите открытие базы данных "${entry.name}"',
        );

        final authSuccess = authResult.fold((success) => success, (failure) {
          failure.map(
            notAvailable: (_) {
              Toaster.warning(
                title: 'Биометрия недоступна',
                description:
                    'На устройстве не настроена биометрическая аутентификация',
              );
            },
            notEnrolled: (_) {
              Toaster.warning(
                title: 'Биометрия не настроена',
                description: 'Настройте биометрию в системных настройках',
              );
            },
            canceled: (_) {},
            lockedOut: (_) {
              Toaster.error(
                title: 'Временная блокировка',
                description: 'Слишком много неудачных попыток',
              );
            },
            permanentlyLockedOut: (_) {
              Toaster.error(
                title: 'Блокировка',
                description: 'Биометрия заблокирована',
              );
            },
            other: (error) {
              Toaster.error(
                title: 'Ошибка аутентификации',
                description: error.message,
              );
            },
          );
          return false;
        });

        if (!authSuccess) {
          return; // Не открываем базу, если биометрия не пройдена
        }
      }

      password = entry.savePassword
          ? await historyService.getSavedPasswordByPath(entry.path)
          : null;
    }

    if (password == null) {
      final attemptStatus = await attemptLimiter.getStatus(entry.path);
      if (attemptStatus.isBlocked) {
        Toaster.error(
          title: 'Хранилище временно заблокировано',
          description: attemptLimiter.buildBlockedDescription(attemptStatus),
        );
        return;
      }

      if (!context.mounted) return;

      // Пароль не сохранен, показываем диалог
      final result = await showDialog<(String, bool)>(
        context: context,
        builder: (context) => PasswordDialog(dbName: entry.name),
      );

      if (result == null) return; // User cancelled
      password = result.$1;
      shouldSavePassword = result.$2;
      usedManualPassword = true;
    }

    final resolvedPassword = password;
    final requiresKeyFile = await _entryRequiresKeyFile(entry);
    final keyFile = await _resolveKeyFileForEntry(context, entry);
    if (!context.mounted || (requiresKeyFile && keyFile == null)) {
      return;
    }

    final success = await notifier.openStore(
      OpenStoreDto(
        path: entry.path,
        password: resolvedPassword,
        keyFileId: keyFile?.id,
        keyFileSecret: keyFile?.secret,
      ),
    );

    if (!context.mounted) return;

    if (success) {
      await attemptLimiter.reset(entry.path);
      // Toaster.success(title: 'Успех', description: 'База данных открыта');

      if (shouldSavePassword && password.isNotEmpty) {
        final freshEntry = await historyService.getByPath(entry.path);
        if (freshEntry != null) {
          final updatedEntry = freshEntry.copyWith(savePassword: true);
          await historyService.update(updatedEntry);
          await historyService.setSavedPasswordByPath(entry.path, password);
          ref.invalidate(recentDatabaseProvider);
        }
      }
    } else {
      final handled = await promptStoreMigrationAndOpen(
        context: context,
        ref: ref,
        dto: OpenStoreDto(
          path: entry.path,
          password: resolvedPassword,
          keyFileId: keyFile?.id,
          keyFileSecret: keyFile?.secret,
        ),
        onOpened: () async {
          await attemptLimiter.reset(entry.path);

          if (shouldSavePassword && resolvedPassword.isNotEmpty) {
            final freshEntry = await historyService.getByPath(entry.path);
            if (freshEntry != null) {
              final updatedEntry = freshEntry.copyWith(savePassword: true);
              await historyService.update(updatedEntry);
              await historyService.setSavedPasswordByPath(
                entry.path,
                resolvedPassword,
              );
              ref.invalidate(recentDatabaseProvider);
            }
          }
        },
      );
      if (handled) {
        return;
      }

      final state = ref.read(mainStoreProvider);
      var errorMessage =
          state.value?.error?.message ?? 'Не удалось открыть базу данных';

      if (usedManualPassword &&
          state.value?.error?.code == 'DB_INVALID_PASSWORD') {
        final failureStatus = await attemptLimiter.registerFailure(entry.path);
        errorMessage =
            '$errorMessage ${attemptLimiter.buildFailureDescription(failureStatus)}';
      }

      Toaster.error(title: 'Ошибка', description: errorMessage);
    }
  }

  Future<bool> _entryRequiresKeyFile(DatabaseEntry entry) async {
    final manifest = await StoreManifestService.readFrom(entry.path);
    return manifest?.useKeyFile == true;
  }

  Future<VaultKeyFile?> _resolveKeyFileForEntry(
    BuildContext context,
    DatabaseEntry entry,
  ) async {
    final manifest = await StoreManifestService.readFrom(entry.path);
    if (manifest?.useKeyFile != true) {
      return null;
    }

    final result = await const VaultKeyFileService().pickAndRead();
    if (!context.mounted) {
      return null;
    }

    return result.fold(
      (keyFile) {
        if (keyFile.id != manifest!.keyFileId) {
          Toaster.error(
            title: 'Неверный key file',
            description: 'Выбранный JSON key file не подходит для хранилища',
          );
          return null;
        }
        return keyFile;
      },
      (error) {
        Toaster.error(title: 'Ошибка key file', description: error.message);
        return null;
      },
    );
  }

  Future<void> _deleteFromHistory(
    BuildContext context,
    WidgetRef ref,
    DatabaseEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из истории'),
        content: Text(
          'Удалить "${entry.name}" из истории?\n\nФайлы базы данных на диске останутся без изменений.',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            variant: SmoothButtonVariant.normal,
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            variant: SmoothButtonVariant.error,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final historyService = await ref.read(dbHistoryProvider.future);
      await historyService.deleteByPath(entry.path);
      ref.invalidate(recentDatabaseProvider);

      if (context.mounted) {
        Toaster.success(
          title: 'Успех',
          description: 'База данных удалена из истории',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Toaster.error(
          title: 'Ошибка',
          description: 'Не удалось удалить из истории: $e',
        );
      }
    }
  }
}

class _CloudLockStatusBanner extends StatelessWidget {
  const _CloudLockStatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress)
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colorScheme.primary,
              ),
            )
          else
            Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
