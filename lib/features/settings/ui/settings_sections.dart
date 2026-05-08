import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_prefs/security_prefs.dart';
import 'package:hoplixi/core/app_prefs/settings_prefs.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/core/theme/theme_switcher.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/settings/providers/settings_prefs_providers.dart';
import 'package:hoplixi/features/settings/ui/widgets/settings_section_card.dart';
import 'package:hoplixi/features/settings/ui/widgets/settings_tile.dart';
import 'package:hoplixi/main_db/providers/main_store_backup_orchestrator_provider.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/shared/widgets/language_switcher.dart';
import 'package:typed_prefs/typed_prefs.dart';
import 'package:universal_platform/universal_platform.dart';

/// Секция настроек внешнего вида
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animatedBackgroundEnabled =
        ref.watch(animatedBackgroundEnabledProvider).value ?? true;

    return SettingsSectionCard(
      title: 'Внешний вид',
      children: [
        const SettingsThemeSwitcher(),
        const Divider(height: 1),
        SettingsSwitchTile(
          title: 'Анимированный фон',
          subtitle: 'Использовать живой многослойный фон вместо статичного',
          leading: const Icon(Icons.auto_awesome_motion_outlined),
          value: animatedBackgroundEnabled,
          onChanged: (value) => getIt<PreferencesService>().settingsPrefs
              .setAnimatedBackgroundEnabled(value),
        ),
      ],
    );
  }
}

/// Секция общих настроек
class GeneralSettingsSection extends ConsumerWidget {
  const GeneralSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchAtStartupService = getIt<LaunchAtStartupService>();
    final launchAtStartupEnabled =
        ref.watch(launchAtStartupEnabledProvider).value ?? false;

    return SettingsSectionCard(
      title: 'Общие',
      children: [
        const LanguageSwitcher(style: LanguageSwitcherStyle.settings),
        if (UniversalPlatform.isDesktop) ...[
          const Divider(height: 1),
          SettingsSwitchTile(
            title: 'Запускать при старте системы',
            subtitle: 'Автоматически запускать приложение при входе в систему',
            leading: const Icon(Icons.rocket_launch_outlined),
            value: launchAtStartupEnabled,
            onChanged: (value) async {
              final appliedValue = await launchAtStartupService.setEnabled(
                value,
              );

              if (appliedValue != value) {
                Toaster.error(
                  title: 'Не удалось обновить автозапуск',
                  description: 'Проверьте права и настройки системы',
                );
                return;
              }

              await getIt<PreferencesService>().settingsPrefs
                  .setLaunchAtStartupEnabled(value);
              Toaster.success(
                title: value ? 'Автозапуск включен' : 'Автозапуск выключен',
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Секция настроек безопасности
class SecuritySettingsSection extends ConsumerWidget {
  const SecuritySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricEnabled = ref.watch(biometricEnabledProvider).value ?? false;
    final preventScreenCaptureOnDashboard =
        ref.watch(preventScreenCaptureOnDashboardProvider).value ?? true;
    final dashboardBlurOverlayEnabled =
        ref.watch(dashboardScreenBlurOverlayEnabledProvider).value ?? false;
    final autoLockTimeout = ref.watch(autoLockTimeoutProvider).value ?? 300;

    return SettingsSectionCard(
      title: 'Безопасность',
      children: [
        SettingsSwitchTile(
          title: 'Биометрическая аутентификация',
          subtitle: 'Использовать отпечаток пальца или Face ID',
          leading: const Icon(Icons.fingerprint),
          value: biometricEnabled,
          onChanged: (value) =>
              getIt<PreferencesService>().securityPrefs.setBiometricEnabled(
                value,
                onWriteError: (failure) {
                  Toaster.error(
                    title: 'Не удалось обновить настройку',
                    description: failure.error.toString(),
                  );
                },
              ),
        ),
        const Divider(height: 1),
        SettingsSwitchTile(
          title: 'Защита скриншотов на дашборде',
          subtitle: 'Запрещать скриншоты и запись экрана на дашборде',
          leading: const Icon(Icons.visibility_off_outlined),
          value: preventScreenCaptureOnDashboard,
          onChanged: (value) => getIt<PreferencesService>().securityPrefs
              .setPreventScreenCaptureOnDashboard(
                value,
                onWriteError: (failure) {
                  Toaster.error(
                    title: 'Не удалось обновить настройку',
                    description: failure.error.toString(),
                  );
                },
              ),
        ),
        SettingsSwitchTile(
          title: 'Blur overlay в переключателе приложений',
          subtitle:
              'Размывать содержимое при сворачивании приложения и в recents',
          leading: const Icon(Icons.blur_on_outlined),
          value: dashboardBlurOverlayEnabled,
          onChanged: (value) => getIt<PreferencesService>().securityPrefs
              .setDashboardScreenBlurOverlayEnabled(
                value,
                onWriteError: (failure) {
                  Toaster.error(
                    title: 'Не удалось обновить настройку',
                    description: failure.error.toString(),
                  );
                },
              ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Таймаут автоблокировки',
          subtitle: _formatTimeout(autoLockTimeout),
          leading: const Icon(Icons.lock_clock),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showTimeoutDialog(context, autoLockTimeout),
        ),
        // const Divider(height: 1),
        // SettingsTile(
        //   title: 'Изменить PIN-код',
        //   subtitle: 'Установить новый PIN-код',
        //   leading: const Icon(Icons.pin),
        //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        // onTap: () => _showChangePinDialog(context),
        // ),
      ],
    );
  }

  String _formatTimeout(int seconds) {
    if (seconds == 0) return 'Отключено';
    if (seconds < 60) return '$seconds сек';
    final minutes = seconds ~/ 60;
    return '$minutes мин';
  }

  Future<void> _showTimeoutDialog(
    BuildContext context,
    int currentTimeout,
  ) async {
    final timeouts = {
      0: 'Отключено',
      30: '30 секунд',
      60: '1 минута',
      300: '5 минут',
      600: '10 минут',
      1800: '30 минут',
    };

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Таймаут автоблокировки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: timeouts.entries.map((entry) {
            return RadioListTile<int>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: currentTimeout,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      await getIt<PreferencesService>().settingsPrefs.setAutoLockTimeout(
        result,
      );
    }
  }

  Future<void> _showChangePinDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить PIN-код'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите новый PIN-код (4-8 цифр)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'PIN-код',
                hintText: '****',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await getIt<PreferencesService>().securityPrefs.setPinCode(result);
    }
  }
}

/// Секция настроек синхронизации
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSyncEnabled = ref.watch(autoSyncEnabledProvider).value ?? false;
    final autoUploadSnapshotOnCloseEnabled =
        ref.watch(autoUploadSnapshotOnCloseEnabledProvider).value ?? false;
    final lastSyncTime = ref.watch(lastSyncTimeProvider).value;

    return SettingsSectionCard(
      title: 'Синхронизация',
      children: [
        // SettingsSwitchTile(
        //   title: 'Автоматическая синхронизация',
        //   subtitle: 'Синхронизировать данные автоматически',
        //   leading: const Icon(Icons.sync),
        //   value: autoSyncEnabled,
        //   onChanged: (value) => getIt<PreferencesService>().settingsPrefs
        //       .setAutoSyncEnabled(value),
        // ),
        // const Divider(height: 1),
        SettingsSwitchTile(
          title: 'Авто-отправка при закрытии',
          subtitle:
              'Если локальная версия новее, отправлять snapshot в облако без подтверждения',
          leading: const Icon(Icons.cloud_upload_outlined),
          value: autoUploadSnapshotOnCloseEnabled,
          onChanged: (value) => getIt<PreferencesService>().settingsPrefs
              .setAutoUploadSnapshotOnCloseEnabled(value),
        ),
        if (lastSyncTime != null) ...[
          const Divider(height: 1),
          SettingsTile(
            title: 'Последняя синхронизация',
            subtitle: _formatLastSync(lastSyncTime),
            leading: const Icon(Icons.update),
          ),
        ],
      ],
    );
  }

  String _formatLastSync(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин назад';
    if (diff.inDays < 1) return '${diff.inHours} ч назад';
    return '${diff.inDays} дн назад';
  }
}

/// Секция настроек резервного копирования
class BackupSettingsSection extends ConsumerWidget {
  const BackupSettingsSection({super.key});

  BackupScope _parseScope(String? raw) {
    switch (raw) {
      case 'databaseOnly':
        return BackupScope.databaseOnly;
      case 'encryptedFilesOnly':
        return BackupScope.encryptedFilesOnly;
      case 'full':
      default:
        return BackupScope.full;
    }
  }

  String _scopeTitle(BackupScope scope) {
    switch (scope) {
      case BackupScope.databaseOnly:
        return 'Только файл базы данных';
      case BackupScope.encryptedFilesOnly:
        return 'Только зашифрованные файлы';
      case BackupScope.full:
        return 'Полный (БД + зашифрованные файлы)';
    }
  }

  String _intervalTitle(int minutes) {
    if (minutes < 60) return '$minutes мин';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours ч';
    final days = hours ~/ 24;
    return '$days дн';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupOrchestrator = ref.read(mainStoreBackupOrchestratorProvider);

    final autoBackupEnabled =
        ref.watch(autoBackupEnabledProvider).value ?? false;
    final backupPath = ref.watch(backupPathProvider).value;
    final backupScopeRaw = ref.watch(backupScopeProvider).value;
    final backupScope = _parseScope(backupScopeRaw);
    final backupIntervalMinutes =
        ref.watch(backupIntervalMinutesProvider).value ?? 360;
    final backupMaxPerStore = ref.watch(backupMaxPerStoreProvider).value ?? 10;

    return SettingsSectionCard(
      title: 'Резервное копирование',
      children: [
        SettingsSwitchTile(
          title: 'Автоматическое резервное копирование',
          subtitle: 'Создавать резервные копии автоматически',
          leading: const Icon(Icons.backup),
          value: autoBackupEnabled,
          onChanged: (value) async {
            await getIt<PreferencesService>().settingsPrefs
                .setAutoBackupEnabled(value);

            if (value) {
              await backupOrchestrator.startPeriodicBackup(
                interval: Duration(minutes: backupIntervalMinutes),
                scope: backupScope,
                outputDirPath: backupPath,
                runImmediately: false,
                maxBackupsPerStore: backupMaxPerStore,
              );
              Toaster.success(title: 'Автобэкап включен');
            } else {
              backupOrchestrator.stopPeriodicBackup();
              Toaster.info(title: 'Автобэкап остановлен');
            }
          },
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Режим бэкапа',
          subtitle: _scopeTitle(backupScope),
          leading: const Icon(Icons.tune),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBackupScopeDialog(
            context,
            backupOrchestrator,
            backupScope,
            autoBackupEnabled,
            backupIntervalMinutes,
            backupPath,
            backupMaxPerStore,
          ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Интервал автобэкапа',
          subtitle: _intervalTitle(backupIntervalMinutes),
          leading: const Icon(Icons.schedule),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBackupIntervalDialog(
            context,
            backupOrchestrator,
            backupIntervalMinutes,
            autoBackupEnabled,
            backupScope,
            backupPath,
            backupMaxPerStore,
          ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Макс. бэкапов на стор',
          subtitle: '$backupMaxPerStore',
          leading: const Icon(Icons.layers_clear),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBackupMaxCountDialog(
            context,
            backupOrchestrator,
            backupMaxPerStore,
            autoBackupEnabled,
            backupIntervalMinutes,
            backupScope,
            backupPath,
          ),
        ),
        // const Divider(height: 1),
        // SettingsTile(
        //   title: 'Путь резервных копий',
        //   subtitle: backupPath ?? 'Не установлен',
        //   leading: const Icon(Icons.folder),
        //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        //   onTap: () => _showBackupPathDialog(
        //     context,
        //     mainStoreNotifier,
        //     autoBackupEnabled,
        //     backupIntervalMinutes,
        //     backupScope,
        //     backupMaxPerStore,
        //   ),
        // ),
        // const Divider(height: 1),
        // SettingsTile(
        //   title: 'Создать резервную копию сейчас',
        //   subtitle: _scopeTitle(backupScope),
        //   leading: const Icon(Icons.save_alt),
        //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        //   onTap: () => _runManualBackup(
        //     context,
        //     mainStoreNotifier,
        //     backupScope,
        //     backupPath,
        //     backupMaxPerStore,
        //   ),
        // ),
      ],
    );
  }

  Future<void> _runManualBackup(
    BuildContext context,
    MainStoreBackupOrchestrator backupOrchestrator,
    BackupScope scope,
    String? backupPath,
    int backupMaxPerStore,
  ) async {
    final result = await backupOrchestrator.createBackup(
      scope: scope,
      outputDirPath: backupPath,
      periodic: false,
      maxBackupsPerStore: backupMaxPerStore,
    );

    if (result == null) {
      Toaster.error(
        title: 'Бэкап не создан',
        description: 'Проверьте, что хранилище открыто',
      );
      return;
    }

    Toaster.success(title: 'Бэкап создан', description: result.backupPath);
  }

  Future<void> _showBackupScopeDialog(
    BuildContext context,
    MainStoreBackupOrchestrator backupOrchestrator,
    BackupScope currentScope,
    bool autoBackupEnabled,
    int backupIntervalMinutes,
    String? backupPath,
    int backupMaxPerStore,
  ) async {
    final scopes = BackupScope.values;

    final result = await showDialog<BackupScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Режим резервного копирования'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: scopes.map((scope) {
            return RadioListTile<BackupScope>(
              title: Text(_scopeTitle(scope)),
              value: scope,
              groupValue: currentScope,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (result == null) return;

    await getIt<PreferencesService>().settingsPrefs.setBackupScope(result.name);

    if (autoBackupEnabled) {
      await backupOrchestrator.startPeriodicBackup(
        interval: Duration(minutes: backupIntervalMinutes),
        scope: result,
        outputDirPath: backupPath,
        runImmediately: false,
        maxBackupsPerStore: backupMaxPerStore,
      );
    }
  }

  Future<void> _showBackupIntervalDialog(
    BuildContext context,
    MainStoreBackupOrchestrator backupOrchestrator,
    int currentIntervalMinutes,
    bool autoBackupEnabled,
    BackupScope backupScope,
    String? backupPath,
    int backupMaxPerStore,
  ) async {
    final intervals = <int>[15, 30, 60, 180, 360, 720, 1440];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интервал автобэкапа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((minutes) {
            return RadioListTile<int>(
              title: Text(_intervalTitle(minutes)),
              value: minutes,
              groupValue: currentIntervalMinutes,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (result == null) return;

    await getIt<PreferencesService>().settingsPrefs.setBackupIntervalMinutes(
      result,
    );

    if (autoBackupEnabled) {
      await backupOrchestrator.startPeriodicBackup(
        interval: Duration(minutes: result),
        scope: backupScope,
        outputDirPath: backupPath,
        runImmediately: false,
        maxBackupsPerStore: backupMaxPerStore,
      );
    }
  }

  Future<void> _showBackupMaxCountDialog(
    BuildContext context,
    MainStoreBackupOrchestrator backupOrchestrator,
    int currentMaxCount,
    bool autoBackupEnabled,
    int backupIntervalMinutes,
    BackupScope backupScope,
    String? backupPath,
  ) async {
    final options = <int>[3, 5, 10, 20, 30, 50, 100];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Максимум бэкапов на один стор'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((count) {
            return RadioListTile<int>(
              title: Text('$count'),
              value: count,
              groupValue: currentMaxCount,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
      ),
    );

    if (result == null) return;

    await getIt<PreferencesService>().settingsPrefs.setBackupMaxPerStore(
      result,
    );

    if (autoBackupEnabled) {
      await backupOrchestrator.startPeriodicBackup(
        interval: Duration(minutes: backupIntervalMinutes),
        scope: backupScope,
        outputDirPath: backupPath,
        runImmediately: false,
        maxBackupsPerStore: result,
      );
    }
  }

  Future<void> _showBackupPathDialog(
    BuildContext context,
    MainStoreBackupOrchestrator backupOrchestrator,
    bool autoBackupEnabled,
    int backupIntervalMinutes,
    BackupScope backupScope,
    int backupMaxPerStore,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Путь резервных копий'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите путь для сохранения резервных копий'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Путь',
                hintText: '/path/to/backup',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await getIt<PreferencesService>().settingsPrefs.setBackupPath(result);

      if (autoBackupEnabled) {
        await backupOrchestrator.startPeriodicBackup(
          interval: Duration(minutes: backupIntervalMinutes),
          scope: backupScope,
          outputDirPath: result,
          runImmediately: false,
          maxBackupsPerStore: backupMaxPerStore,
        );
      }
    }
  }
}

/// Секция настроек Dashboard
class DashboardSettingsSection extends ConsumerWidget {
  const DashboardSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAnimationsEnabled =
        ref.watch(dashboardAnimationsEnabledProvider).value ?? true;
    final floatingNavEffectsEnabled =
        ref.watch(dashboardFloatingNavEffectsEnabledProvider).value ?? true;
    final floatingNavHighlightColor =
        ref.watch(dashboardFloatingNavHighlightColorProvider).value ??
        DashboardFloatingNavHighlightColor.primary;
    final animatedItemsThreshold =
        ref.watch(dashboardAnimatedItemsThresholdProvider).value ?? 15;

    return SettingsSectionCard(
      title: 'Dashboard',
      children: [
        SettingsSwitchTile(
          title: 'Анимации dashboard',
          subtitle: 'Полностью отключить анимации списка, сетки и переходов',
          leading: const Icon(Icons.motion_photos_off_outlined),
          value: dashboardAnimationsEnabled,
          onChanged: (value) => getIt<PreferencesService>().settingsPrefs
              .setDashboardAnimationsEnabled(value),
        ),
        const Divider(height: 1),
        SettingsSwitchTile(
          title: 'Glass-эффект нижней навигации',
          subtitle:
              'Показывать затемнение и стеклянный фон у мобильной навигации',
          leading: const Icon(Icons.blur_on_outlined),
          value: floatingNavEffectsEnabled,
          onChanged: (value) => getIt<PreferencesService>().settingsPrefs
              .setDashboardFloatingNavEffectsEnabled(value),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Цвет подсветки нижней навигации',
          subtitle: _floatingNavHighlightColorTitle(
            floatingNavHighlightColor,
          ),
          leading: const Icon(Icons.palette_outlined),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showFloatingNavHighlightColorDialog(
            context,
            currentValue: floatingNavHighlightColor,
          ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Порог анимированных элементов',
          subtitle:
              'Если элементов не больше $animatedItemsThreshold, список и сетка анимируются',
          leading: const Icon(Icons.auto_awesome_outlined),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showAnimatedItemsThresholdDialog(
            context,
            currentValue: animatedItemsThreshold,
          ),
        ),
      ],
    );
  }

  String _floatingNavHighlightColorTitle(String value) {
    return switch (value) {
      DashboardFloatingNavHighlightColor.darkGrey => 'Тёмно-серый',
      _ => 'Primary',
    };
  }

  Future<void> _showFloatingNavHighlightColorDialog(
    BuildContext context, {
    required String currentValue,
  }) async {
    const options = <String>[
      DashboardFloatingNavHighlightColor.primary,
      DashboardFloatingNavHighlightColor.darkGrey,
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Цвет подсветки'),
        children: [
          for (final option in options)
            RadioListTile<String>(
              title: Text(_floatingNavHighlightColorTitle(option)),
              value: option,
              groupValue: currentValue,
              onChanged: (value) => Navigator.pop(dialogContext, value),
            ),
        ],
      ),
    );

    if (selected == null || selected == currentValue) {
      return;
    }

    await getIt<PreferencesService>().settingsPrefs
        .setDashboardFloatingNavHighlightColor(selected);
  }

  Future<void> _showAnimatedItemsThresholdDialog(
    BuildContext context, {
    required int currentValue,
  }) async {
    const options = <int>[5, 10, 15, 20, 25, 30, 40, 50];

    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Порог анимированных элементов'),
        children: [
          for (final option in options)
            RadioListTile<int>(
              title: Text('$option элементов'),
              value: option,
              groupValue: currentValue,
              onChanged: (value) => Navigator.pop(dialogContext, value),
            ),
        ],
      ),
    );

    if (selected == null || selected == currentValue) {
      return;
    }

    await getIt<PreferencesService>().settingsPrefs
        .setDashboardAnimatedItemsThreshold(selected);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Новый порог: $selected элементов')),
      );
    }
  }
}
