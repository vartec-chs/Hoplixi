import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/security_prefs.dart';
import 'package:hoplixi/core/services/local_auth_service/local_auth_failure.dart';
import 'package:hoplixi/core/services/local_auth_service/local_auth_service.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/home/providers/recent_database_provider.dart';
import 'package:hoplixi/features/home/recent_database/models/recent_database_open_models.dart';
import 'package:hoplixi/features/home/recent_database/widgets/password_dialog.dart';
import 'package:hoplixi/features/password_manager/open_store/services/store_password_attempt_limiter_service.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:typed_prefs/typed_prefs.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';
import 'package:hoplixi/vault_db/providers/providers.dart';
import 'package:hoplixi/vault_db/services/db_history_services/model/db_history_model.dart';
import 'package:hoplixi/vault_db/services/store_manifest_service/model/store_manifest.dart';
import 'package:hoplixi/vault_db/services/store_manifest_service/store_manifest_service.dart';
import 'package:hoplixi/vault_db/services/vault_key_file_service.dart';
import 'package:hoplixi/vault_db/ui/store_open_migration_dialog.dart';

final recentDatabaseOpenControllerProvider =
    Provider<RecentDatabaseOpenController>((ref) {
      return RecentDatabaseOpenController(ref);
    });

class RecentDatabaseOpenController {
  const RecentDatabaseOpenController(this.ref);

  final Ref ref;

  Future<void> open(
    BuildContext context,
    DatabaseEntry entry, {
    required WidgetRef widgetRef,
  }) async {
    final request = await _buildOpenRequest(context, entry);
    if (request == null || !context.mounted) return;

    final notifier = ref.read(vaultDBManagerStateProvider.notifier);
    final success = await notifier.openStore(request.dto);

    if (!context.mounted) return;

    if (success) {
      await _handleOpenSuccess(entry, request);
      return;
    }

    await _handleOpenFailure(context, entry, request, widgetRef);
  }

  Future<RecentDatabaseOpenRequest?> _buildOpenRequest(
    BuildContext context,
    DatabaseEntry entry,
  ) async {
    final savedPassword = await _getSavedPasswordIfAllowed(entry);

    if (!context.mounted) return null;

    final passwordResult = await _requestPasswordIfNeeded(
      context,
      entry,
      savedPassword,
    );

    if (passwordResult == null) return null;

    final manifest = await StoreManifestService.readFrom(entry.path);

    if (!context.mounted) return null;

    final keyFile = await _resolveKeyFileForManifest(context, manifest);

    if (!context.mounted) return null;

    if (manifest?.useKeyFile == true && keyFile == null) {
      return null;
    }

    return RecentDatabaseOpenRequest(
      dto: OpenStoreDto(
        path: entry.path,
        password: passwordResult.password,
        keyFileId: keyFile?.id,
        keyFileSecret: keyFile?.secret,
      ),
      password: passwordResult.password,
      shouldSavePassword: passwordResult.shouldSavePassword,
      usedManualPassword: passwordResult.usedManualPassword,
    );
  }

  Future<String?> _getSavedPasswordIfAllowed(DatabaseEntry entry) async {
    if (!entry.savePassword) return null;

    final authenticated = await _authenticateForSavedPasswordIfNeeded(entry);
    if (!authenticated) return null;

    final historyService = await ref.read(dbHistoryProvider.future);
    return historyService.getSavedPasswordByPath(entry.path);
  }

  Future<bool> _authenticateForSavedPasswordIfNeeded(
    DatabaseEntry entry,
  ) async {
    final storageService = getIt<PreferencesService>();
    final isBiometricEnabled =
        await storageService.securityPrefs.biometricEnabled.get() ?? false;

    if (!isBiometricEnabled) return true;

    final localAuthService = getIt<LocalAuthService>();
    final authResult = await localAuthService.authenticate(
      localizedReason: 'Подтвердите открытие базы данных "${entry.name}"',
    );

    return authResult.fold((success) => success, (failure) {
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
  }

  Future<RecentDatabasePasswordPromptResult?> _requestPasswordIfNeeded(
    BuildContext context,
    DatabaseEntry entry,
    String? savedPassword,
  ) async {
    if (savedPassword != null) {
      return RecentDatabasePasswordPromptResult(
        password: savedPassword,
        shouldSavePassword: false,
        usedManualPassword: false,
      );
    }

    final attemptLimiter = getIt<StorePasswordAttemptLimiterService>();
    final attemptStatus = await attemptLimiter.getStatus(entry.path);

    if (attemptStatus.isBlocked) {
      Toaster.error(
        title: 'Хранилище временно заблокировано',
        description: attemptLimiter.buildBlockedDescription(attemptStatus),
      );
      return null;
    }

    if (!context.mounted) return null;

    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (context) => PasswordDialog(dbName: entry.name),
    );

    if (result == null) return null;

    return RecentDatabasePasswordPromptResult(
      password: result.$1,
      shouldSavePassword: result.$2,
      usedManualPassword: true,
    );
  }

  Future<VaultKeyFile?> _resolveKeyFileForManifest(
    BuildContext context,
    StoreManifest? manifest,
  ) async {
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

  Future<void> _handleOpenSuccess(
    DatabaseEntry entry,
    RecentDatabaseOpenRequest request,
  ) async {
    final attemptLimiter = getIt<StorePasswordAttemptLimiterService>();

    await attemptLimiter.reset(entry.path);

    await _savePasswordIfRequested(
      entry: entry,
      password: request.password,
      shouldSavePassword: request.shouldSavePassword,
    );
  }

  Future<void> _handleOpenFailure(
    BuildContext context,
    DatabaseEntry entry,
    RecentDatabaseOpenRequest request,
    WidgetRef widgetRef,
  ) async {
    final attemptLimiter = getIt<StorePasswordAttemptLimiterService>();

    final handled = await promptStoreMigrationAndOpen(
      context: context,
      ref: widgetRef,
      dto: request.dto,
      onOpened: () async {
        await attemptLimiter.reset(entry.path);

        await _savePasswordIfRequested(
          entry: entry,
          password: request.password,
          shouldSavePassword: request.shouldSavePassword,
        );
      },
    );

    if (handled) return;

    final state = ref.read(vaultDBManagerStateProvider);

    var errorMessage =
        state.value?.error?.message ?? 'Не удалось открыть базу данных';

    if (request.usedManualPassword &&
        state.value?.error?.code == 'DB_INVALID_PASSWORD') {
      final failureStatus = await attemptLimiter.registerFailure(entry.path);
      errorMessage =
          '$errorMessage ${attemptLimiter.buildFailureDescription(failureStatus)}';
    }

    Toaster.error(title: 'Ошибка', description: errorMessage);
  }

  Future<void> _savePasswordIfRequested({
    required DatabaseEntry entry,
    required String password,
    required bool shouldSavePassword,
  }) async {
    if (!shouldSavePassword || password.isEmpty) return;

    final historyService = await ref.read(dbHistoryProvider.future);
    final freshEntry = await historyService.getByPath(entry.path);

    if (freshEntry == null) return;

    await historyService.update(freshEntry.copyWith(savePassword: true));
    await historyService.setSavedPasswordByPath(entry.path, password);

    ref.invalidate(recentDatabaseProvider);
  }
}
