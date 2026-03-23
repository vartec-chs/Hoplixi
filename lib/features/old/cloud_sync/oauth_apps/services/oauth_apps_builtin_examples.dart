/// Примеры использования встроенных OAuth приложений
///
/// Этот файл содержит примеры работы с встроенными OAuth приложениями,
/// которые загружаются из .env файла
library;

import 'package:hoplixi/features/old/cloud_sync/oauth_apps/services/oauth_apps_service.dart';

/// Пример 1: Получение встроенных приложений
Future<void> exampleGetBuiltinApps(OAuthAppsService service) async {
  await service.initialize();

  // Получить все встроенные приложения
  final builtinResult = await service.getBuiltinApps();
  builtinResult.fold((apps) {
    print('Встроенные приложения (${apps.length}):');
    for (final app in apps) {
      print('- ${app.name} (${app.type.name}): ${app.clientId}');
    }
  }, (error) => print('Ошибка: ${error.message}'));
}

/// Пример 2: Перезагрузка встроенных приложений
/// Полезно после изменения .env файла
Future<void> exampleReloadBuiltinApps(OAuthAppsService service) async {
  await service.initialize();

  // Перезагрузить встроенные приложения из .env
  final reloadResult = await service.reloadBuiltinApps();
  if (reloadResult.isSuccess()) {
    print('Встроенные приложения перезагружены');

    // Проверяем обновления
    final appsResult = await service.getBuiltinApps();
    appsResult.fold((apps) {
      print('Обновленные встроенные приложения: ${apps.length}');
    }, (error) => print('Ошибка: ${error.message}'));
  }
}

/// Пример 3: Попытка удалить встроенное приложение (будет ошибка)
Future<void> exampleAttemptDeleteBuiltin(OAuthAppsService service) async {
  await service.initialize();

  // Получаем первое встроенное приложение
  final builtinResult = await service.getBuiltinApps();
  builtinResult.fold((apps) async {
    if (apps.isNotEmpty) {
      final app = apps.first;
      print('Попытка удалить встроенное приложение: ${app.name}');

      // Попытка удалить встроенное приложение
      final deleteResult = await service.deleteApp(app.id);
      deleteResult.fold(
        (_) => print('Удалено (не должно произойти!)'),
        (error) => print('Ожидаемая ошибка: ${error.message}'),
      );
    }
  }, (error) => print('Ошибка при получении приложений: ${error.message}'));
}

/// Пример 4: Попытка изменить встроенное приложение (будет ошибка)
Future<void> exampleAttemptUpdateBuiltin(OAuthAppsService service) async {
  await service.initialize();

  // Получаем первое встроенное приложение
  final builtinResult = await service.getBuiltinApps();
  builtinResult.fold((apps) async {
    if (apps.isNotEmpty) {
      final app = apps.first;
      print('Попытка изменить встроенное приложение: ${app.name}');

      // Попытка изменить встроенное приложение
      final updatedApp = app.copyWith(name: 'Измененное название');
      final updateResult = await service.updateApp(updatedApp);
      updateResult.fold(
        (_) => print('Обновлено (не должно произойти!)'),
        (error) => print('Ожидаемая ошибка: ${error.message}'),
      );
    }
  }, (error) => print('Ошибка при получении приложений: ${error.message}'));
}

/// Пример 5: Получение конкретного типа встроенных приложений
Future<void> exampleGetBuiltinByType(OAuthAppsService service) async {
  await service.initialize();

  // Получить все встроенные приложения
  final builtinResult = await service.getBuiltinApps();
  builtinResult.fold((apps) {
    // Фильтруем по типам
    final googleApps = apps.where((app) => app.type.name == 'Google').toList();
    final dropboxApps = apps
        .where((app) => app.type.name == 'Dropbox')
        .toList();

    print('Google приложений: ${googleApps.length}');
    print('Dropbox приложений: ${dropboxApps.length}');
  }, (error) => print('Ошибка: ${error.message}'));
}

/// Пример 6: Проверка существования встроенного приложения
Future<void> exampleCheckBuiltinExists(OAuthAppsService service) async {
  await service.initialize();

  // ID встроенных приложений имеют формат: builtin-{type}
  final googleBuiltinId = 'builtin-google';
  final dropboxBuiltinId = 'builtin-dropbox';

  if (service.appExists(googleBuiltinId)) {
    print('Встроенное Google приложение существует');
    final appResult = await service.getApp(googleBuiltinId);
    appResult.fold(
      (app) => print('  Название: ${app.name}'),
      (error) => print('  Ошибка: ${error.message}'),
    );
  }

  if (service.appExists(dropboxBuiltinId)) {
    print('Встроенное Dropbox приложение существует');
  }
}

/// Пример 7: Полный сценарий с встроенными и пользовательскими приложениями
Future<void> exampleMixedApps(OAuthAppsService service) async {
  await service.initialize();

  print('=== Статистика OAuth приложений ===');

  // Общее количество
  print('Всего приложений: ${service.getCount()}');

  // Встроенные приложения
  final builtinResult = await service.getBuiltinApps();
  builtinResult.fold(
    (apps) => print('Встроенных: ${apps.length}'),
    (error) => print('Ошибка при получении встроенных: ${error.message}'),
  );

  // Пользовательские приложения
  final customResult = await service.getCustomApps();
  customResult.fold(
    (apps) => print('Пользовательских: ${apps.length}'),
    (error) => print('Ошибка при получении пользовательских: ${error.message}'),
  );

  print('\n=== Список всех приложений ===');
  final allResult = await service.getAllApps();
  allResult.fold((apps) {
    for (final app in apps) {
      final type = app.isBuiltin ? '[Встроенное]' : '[Пользовательское]';
      print('$type ${app.name} (${app.type.name})');
    }
  }, (error) => print('Ошибка: ${error.message}'));
}

/// Пример 8: Конфигурация .env для встроенных приложений
///
/// Для включения встроенных приложений в .env файле должны быть указаны:
///
/// ```env
/// # Глобальный флаг использования встроенных приложений
/// USED_BUILTIN_AUTH_APPS=true
///
/// # Конфигурация Google OAuth
/// GOOGLE_BUILTIN_ENABLED=true
/// GOOGLE_APP_NAME=My App
/// GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
/// GOOGLE_CLIENT_SECRET=your-client-secret
///
/// # Конфигурация Dropbox OAuth
/// DROPBOX_BUILTIN_ENABLED=true
/// DROPBOX_APP_NAME=My App
/// DROPBOX_CLIENT_ID=your-dropbox-client-id
/// DROPBOX_CLIENT_SECRET=your-dropbox-client-secret
///
/// # Конфигурация Yandex OAuth
/// YANDEX_BUILTIN_ENABLED=true
/// YANDEX_APP_NAME=My App
/// YANDEX_CLIENT_ID=your-yandex-client-id
/// YANDEX_CLIENT_SECRET=your-yandex-client-secret
///
/// # Конфигурация OneDrive OAuth
/// ONEDRIVE_BUILTIN_ENABLED=true
/// ONEDRIVE_APP_NAME=My App
/// ONEDRIVE_CLIENT_ID=your-onedrive-client-id
/// ONEDRIVE_CLIENT_SECRET=your-onedrive-client-secret
/// ```
///
/// Примечания:
/// - CLIENT_SECRET может быть пустым (для публичных клиентов)
/// - Каждый провайдер может быть включен/выключен индивидуально
/// - Встроенные приложения нельзя редактировать или удалять через UI
/// - ID встроенных приложений имеют формат: builtin-{type}
void envConfigurationExample() {
  // Этот пример показывает структуру .env файла
  print('См. комментарий к функции для примера конфигурации .env');
}
