import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preference_keys.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/core/theme/theme_switcher.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/di_init.dart';
import 'package:hoplixi/features/settings/providers/settings_provider.dart';
import 'package:hoplixi/features/settings/ui/widgets/settings_section_card.dart';
import 'package:hoplixi/features/settings/ui/widgets/settings_tile.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';
import 'package:universal_platform/universal_platform.dart';

/// Секция настроек внешнего вида
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsSectionCard(
      title: 'Внешний вид',
      children: [SettingsThemeSwitcher()],
    );
  }
}

/// Секция общих настроек
class GeneralSettingsSection extends ConsumerWidget {
  const GeneralSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final launchAtStartupService = getIt<LaunchAtStartupService>();

    final language = settings[AppKeys.language.key] as String? ?? 'ru';
    final launchAtStartupEnabled =
        settings[AppKeys.launchAtStartupEnabled.key] as bool? ?? false;

    return SettingsSectionCard(
      title: 'Общие',
      children: [
        SettingsTile(
          title: 'Язык',
          subtitle: _getLanguageName(language),
          leading: const Icon(Icons.language),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showLanguageDialog(context, ref, notifier),
        ),
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

              await notifier.setBool(AppKeys.launchAtStartupEnabled.key, value);
              Toaster.success(
                title: value ? 'Автозапуск включен' : 'Автозапуск выключен',
              );
            },
          ),
        ],
      ],
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier notifier,
  ) async {
    final languages = {'ru': 'Русский'};

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.pop(context, entry.key),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      await notifier.setString(AppKeys.language.key, result);
    }
  }
}

/// Секция настроек безопасности
class SecuritySettingsSection extends ConsumerWidget {
  const SecuritySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final biometricEnabled =
        settings[AppKeys.biometricEnabled.key] as bool? ?? false;
    final autoLockTimeout =
        settings[AppKeys.autoLockTimeout.key] as int? ?? 300;

    return SettingsSectionCard(
      title: 'Безопасность',
      children: [
        SettingsSwitchTile(
          title: 'Биометрическая аутентификация',
          subtitle: 'Использовать отпечаток пальца или Face ID',
          leading: const Icon(Icons.fingerprint),
          value: biometricEnabled,
          onChanged: (value) => notifier.setBoolWithBiometric(
            AppKeys.biometricEnabled.key,
            value,
            reason: 'Подтвердите изменение настройки биометрии',
          ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Таймаут автоблокировки',
          subtitle: _formatTimeout(autoLockTimeout),
          leading: const Icon(Icons.lock_clock),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              _showTimeoutDialog(context, ref, notifier, autoLockTimeout),
        ),
        // const Divider(height: 1),
        // SettingsTile(
        //   title: 'Изменить PIN-код',
        //   subtitle: 'Установить новый PIN-код',
        //   leading: const Icon(Icons.pin),
        //   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        //   onTap: () => _showChangePinDialog(context, ref, notifier),
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
    WidgetRef ref,
    SettingsNotifier notifier,
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
      await notifier.setInt(AppKeys.autoLockTimeout.key, result);
    }
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsNotifier notifier,
  ) async {
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
      await notifier.setStringWithBiometric(
        AppKeys.pinCode.key,
        result,
        reason: 'Подтвердите изменение PIN-кода',
      );
    }
  }
}

/// Секция настроек синхронизации
class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final autoSyncEnabled =
        settings[AppKeys.autoSyncEnabled.key] as bool? ?? false;
    final lastSyncTime = settings[AppKeys.lastSyncTime.key] as int?;

    return SettingsSectionCard(
      title: 'Синхронизация',
      children: [
        SettingsSwitchTile(
          title: 'Автоматическая синхронизация',
          subtitle: 'Синхронизировать данные автоматически',
          leading: const Icon(Icons.sync),
          value: autoSyncEnabled,
          onChanged: (value) =>
              notifier.setBool(AppKeys.autoSyncEnabled.key, value),
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
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final mainStoreNotifier = ref.read(mainStoreProvider.notifier);

    final autoBackupEnabled =
        settings[AppKeys.autoBackupEnabled.key] as bool? ?? false;
    final backupPath = settings[AppKeys.backupPath.key] as String?;
    final backupScopeRaw = settings[AppKeys.backupScope.key] as String?;
    final backupScope = _parseScope(backupScopeRaw);
    final backupIntervalMinutes =
        settings[AppKeys.backupIntervalMinutes.key] as int? ?? 360;
    final backupMaxPerStore =
        settings[AppKeys.backupMaxPerStore.key] as int? ?? 10;

    return SettingsSectionCard(
      title: 'Резервное копирование',
      children: [
        SettingsSwitchTile(
          title: 'Автоматическое резервное копирование',
          subtitle: 'Создавать резервные копии автоматически',
          leading: const Icon(Icons.backup),
          value: autoBackupEnabled,
          onChanged: (value) async {
            await notifier.setBool(AppKeys.autoBackupEnabled.key, value);

            if (value) {
              mainStoreNotifier.startPeriodicBackup(
                interval: Duration(minutes: backupIntervalMinutes),
                scope: backupScope,
                outputDirPath: backupPath,
                runImmediately: false,
                maxBackupsPerStore: backupMaxPerStore,
              );
              Toaster.success(title: 'Автобэкап включен');
            } else {
              mainStoreNotifier.stopPeriodicBackup();
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
            notifier,
            mainStoreNotifier,
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
            notifier,
            mainStoreNotifier,
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
            notifier,
            mainStoreNotifier,
            backupMaxPerStore,
            autoBackupEnabled,
            backupIntervalMinutes,
            backupScope,
            backupPath,
          ),
        ),
        const Divider(height: 1),
        SettingsTile(
          title: 'Путь резервных копий',
          subtitle: backupPath ?? 'Не установлен',
          leading: const Icon(Icons.folder),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBackupPathDialog(
            context,
            notifier,
            mainStoreNotifier,
            autoBackupEnabled,
            backupIntervalMinutes,
            backupScope,
            backupMaxPerStore,
          ),
        ),
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
    MainStoreAsyncNotifier mainStoreNotifier,
    BackupScope scope,
    String? backupPath,
    int backupMaxPerStore,
  ) async {
    final result = await mainStoreNotifier.createBackup(
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
    SettingsNotifier notifier,
    MainStoreAsyncNotifier mainStoreNotifier,
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

    await notifier.setString(AppKeys.backupScope.key, result.name);

    if (autoBackupEnabled) {
      mainStoreNotifier.startPeriodicBackup(
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
    SettingsNotifier notifier,
    MainStoreAsyncNotifier mainStoreNotifier,
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

    await notifier.setInt(AppKeys.backupIntervalMinutes.key, result);

    if (autoBackupEnabled) {
      mainStoreNotifier.startPeriodicBackup(
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
    SettingsNotifier notifier,
    MainStoreAsyncNotifier mainStoreNotifier,
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

    await notifier.setInt(AppKeys.backupMaxPerStore.key, result);

    if (autoBackupEnabled) {
      mainStoreNotifier.startPeriodicBackup(
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
    SettingsNotifier notifier,
    MainStoreAsyncNotifier mainStoreNotifier,
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
      await notifier.setString(AppKeys.backupPath.key, result);

      if (autoBackupEnabled) {
        mainStoreNotifier.startPeriodicBackup(
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
