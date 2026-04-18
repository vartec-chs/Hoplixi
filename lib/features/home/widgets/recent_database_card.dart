import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/security_prefs.dart';
import 'package:hoplixi/core/services/local_auth_failure.dart';
import 'package:hoplixi/core/services/local_auth_service.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/db_core/models/db_history_model.dart';
import 'package:hoplixi/db_core/models/dto/main_store_dto.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:hoplixi/db_core/provider/db_history_provider.dart';
import 'package:hoplixi/db_core/provider/main_store_provider.dart';
import 'package:hoplixi/db_core/services/store_manifest_service.dart';
import 'package:hoplixi/db_core/ui/store_open_migration_dialog.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/http/models/cloud_sync_http_exception.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/snapshot_sync_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/storage/models/cloud_storage_exception.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/features/password_manager/open_store/services/store_password_attempt_limiter_service.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import 'package:typed_prefs/typed_prefs.dart';

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
    final manifestAsync = ref.watch(
      _recentDatabaseManifestProvider(entry.path),
    );
    final isLoading = dbStateAsync.value?.isLoading ?? false;
    final syncProvider = manifestAsync.maybeWhen(
      data: (manifest) => manifest?.sync?.provider,
      orElse: () => null,
    );

    return Card(
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Недавняя база данных',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  tooltip: 'Удалить из истории',
                  onPressed: () => _deleteFromHistory(context, ref, entry),
                  color: colorScheme.error,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      syncProvider.metadata.icon,
                      size: 18,
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
            const SizedBox(height: 16),
            if (syncProvider != null) ...[
              SmoothButton(
                label: _cloudSyncProgress == null
                    ? 'Проверить и установить новую версию'
                    : _buildProgressButtonLabel(_cloudSyncProgress!),
                type: SmoothButtonType.outlined,
                isFullWidth: true,
                icon: Icon(syncProvider.metadata.icon),
                loading: _isCheckingCloudVersion,
                onPressed: (isLoading || _isCheckingCloudVersion)
                    ? null
                    : () => _checkCloudVersion(context, entry),
              ),
              const SizedBox(height: 12),
            ],
            if (_isCheckingCloudVersion)
              _buildCloudSyncProgressPanel(context)
            else
              SmoothButton(
                label: isLoading ? 'Открытие...' : 'Открыть',
                type: SmoothButtonType.filled,
                isFullWidth: true,
                icon: const Icon(CupertinoIcons.arrow_right_circle),
                loading: isLoading,
                onPressed: isLoading
                    ? null
                    : () => _openDatabase(context, ref, entry),
              ),
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

  Future<_CloudVersionCheckData?> _loadCloudVersionCheckData(
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

    return _CloudVersionCheckData(
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

  Widget _buildCloudSyncProgressPanel(BuildContext context) {
    final progress = _cloudSyncProgress;
    if (progress == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final transfer = progress.transferProgress;
    final fraction = transfer?.fraction;
    final fileProgressText = transfer != null && transfer.hasFileProgress
        ? '${transfer.completedFiles} из ${transfer.totalFiles} файлов'
        : null;
    final bytesProgressText = transfer != null && transfer.totalBytes != null
        ? '${_formatBytes(transfer.transferredBytes)} из ${_formatBytes(transfer.totalBytes!)}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Шаг ${progress.stepIndex} из ${progress.totalSteps}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            progress.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: fraction),
          if (fileProgressText != null) ...[
            const SizedBox(height: 10),
            Text(
              fileProgressText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (bytesProgressText != null) ...[
            const SizedBox(height: 4),
            Text(
              bytesProgressText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (transfer?.currentFileName != null &&
              transfer!.currentFileName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Текущий файл: ${transfer.currentFileName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['Б', 'КБ', 'МБ', 'ГБ'];
    var value = bytes.toDouble();
    var unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    final precision = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
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
            canceled: (_) {
              Toaster.info(
                title: 'Отменено',
                description: 'Аутентификация отменена пользователем',
              );
            },
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

      // Пароль не сохранен, показываем диалог
      final result = await showDialog<(String, bool)>(
        context: context,
        builder: (context) => _PasswordDialog(dbName: entry.name),
      );

      if (result == null) return; // User cancelled
      password = result.$1;
      shouldSavePassword = result.$2;
      usedManualPassword = true;
    }

    final resolvedPassword = password;

    final success = await notifier.openStore(
      OpenStoreDto(path: entry.path, password: resolvedPassword),
    );

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
        dto: OpenStoreDto(path: entry.path, password: resolvedPassword),
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

class _CloudVersionCheckData {
  const _CloudVersionCheckData({
    required this.manifest,
    required this.binding,
    required this.token,
  });

  final StoreManifest manifest;
  final StoreSyncBinding binding;
  final AuthTokenEntry token;
}

class _PasswordDialog extends StatefulWidget {
  final String dbName;

  const _PasswordDialog({required this.dbName});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;
  bool _savePassword = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = AppColors.getInputFieldBackgroundColor(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: Text('Введите пароль для "${widget.dbName}"'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Пароль',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              onSubmitted: (value) =>
                  Navigator.of(context).pop((value, _savePassword)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              tileColor: fillColor,
              title: const Text('Сохранить пароль'),
              value: _savePassword,
              onChanged: (value) {
                setState(() {
                  _savePassword = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        SmoothButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Отмена',

          variant: SmoothButtonVariant.error,
          type: SmoothButtonType.text,
        ),
        SmoothButton(
          label: 'Открыть',

          onPressed: () =>
              Navigator.of(context).pop((_controller.text, _savePassword)),
        ),
      ],
    );
  }
}
