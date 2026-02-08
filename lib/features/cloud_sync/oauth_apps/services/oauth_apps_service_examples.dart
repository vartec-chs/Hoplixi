/// Примеры использования OAuthAppsService
///
/// Этот файл содержит примеры использования сервиса для управления OAuth приложениями
library;

import 'package:hoplixi/features/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/models/oauth_apps_errors.dart';
import 'package:hoplixi/features/cloud_sync/oauth_apps/services/oauth_apps_service.dart';
import 'package:uuid/uuid.dart';

/// Пример 1: Инициализация и базовое использование
Future<void> exampleBasicUsage(OAuthAppsService service) async {
  // 1. Инициализировать сервис
  final initResult = await service.initialize();
  if (initResult.isError()) {
    print('Ошибка инициализации: ${initResult.exceptionOrNull()}');
    return;
  }

  // 2. Создать новое OAuth приложение
  final app = OauthApps(
    id: const Uuid().v4(),
    name: 'My Google App',
    type: OauthAppsType.google,
    clientId: 'your-client-id.apps.googleusercontent.com',
    clientSecret: 'your-client-secret',
    isBuiltin: false,
  );

  // 3. Сохранить приложение
  final saveResult = await service.createApp(app);
  if (saveResult.isSuccess()) {
    print('OAuth приложение создано: ${app.id}');
  }

  // 4. Получить приложение по ID
  final getResult = await service.getApp(app.id);
  getResult.fold(
    (success) => print('Получено приложение: ${success.name}'),
    (error) => print('Ошибка: ${error.message}'),
  );
}

/// Пример 2: CRUD операции
Future<void> exampleCrudOperations(OAuthAppsService service) async {
  await service.initialize();

  final appId = const Uuid().v4();

  // CREATE
  final newApp = OauthApps(
    id: appId,
    name: 'Dropbox Integration',
    type: OauthAppsType.dropbox,
    clientId: 'dropbox-client-id',
    clientSecret: 'dropbox-secret',
  );

  await service.createApp(newApp);

  // READ
  final readResult = await service.getApp(appId);
  if (readResult.isSuccess()) {
    print('Приложение найдено: ${readResult.getOrNull()?.name}');
  }

  // UPDATE
  final updatedApp = newApp.copyWith(name: 'Updated Dropbox Integration');
  await service.updateApp(updatedApp);

  // DELETE
  await service.deleteApp(appId);
}

/// Пример 3: Работа с фильтрами
Future<void> exampleFiltering(OAuthAppsService service) async {
  await service.initialize();

  // Получить все приложения
  final allAppsResult = await service.getAllApps();
  if (allAppsResult.isSuccess()) {
    final apps = allAppsResult.getOrNull()!;
    print('Всего приложений: ${apps.length}');
  }

  // Получить приложения по типу
  final googleAppsResult = await service.getAppsByType(OauthAppsType.google);
  googleAppsResult.fold(
    (apps) => print('Приложений Google: ${apps.length}'),
    (error) => print('Ошибка получения приложений Google: ${error.message}'),
  );

  // Получить встроенные приложения
  final builtinResult = await service.getBuiltinApps();
  if (builtinResult.isSuccess()) {
    print('Встроенных приложений: ${builtinResult.getOrNull()?.length}');
  }

  // Получить пользовательские приложения
  final customResult = await service.getCustomApps();
  if (customResult.isSuccess()) {
    print('Пользовательских приложений: ${customResult.getOrNull()?.length}');
  }
}

/// Пример 4: Подписка на изменения
Future<void> exampleWatchChanges(OAuthAppsService service) async {
  await service.initialize();

  // Подписка на изменения всех приложений
  final subscription = service.watchChanges().listen((event) {
    if (event.deleted) {
      print('Приложение удалено: ${event.key}');
    } else {
      print('Приложение изменено: ${event.key}');
    }
  });

  // Подписка на изменения конкретного приложения
  final appId = 'specific-app-id';
  final appSubscription = service.watchChanges(appId: appId).listen((event) {
    print('Изменение в приложении $appId');
  });

  // Не забыть отменить подписки
  await subscription.cancel();
  await appSubscription.cancel();
}

/// Пример 5: Экспорт и импорт
Future<void> exampleExportImport(OAuthAppsService service) async {
  await service.initialize();

  // Экспорт всех приложений
  final exportResult = await service.exportAll();
  if (exportResult.isSuccess()) {
    final apps = exportResult.getOrNull()!;
    print('Экспортировано ${apps.length} приложений');

    // Сохранить в файл или отправить на сервер
    // final json = jsonEncode(apps.map((k, v) => MapEntry(k, v.toJson())));
  }

  // Импорт приложений
  final appsToImport = <String, OauthApps>{
    'app1': const OauthApps(
      id: 'app1',
      name: 'App 1',
      type: OauthAppsType.google,
      clientId: 'client-id-1',
    ),
    'app2': const OauthApps(
      id: 'app2',
      name: 'App 2',
      type: OauthAppsType.onedrive,
      clientId: 'client-id-2',
    ),
  };

  final importResult = await service.importAll(
    appsToImport,
    overwrite: false, // Не перезаписывать существующие
  );

  if (importResult.isSuccess()) {
    final imported = importResult.getOrNull()!;
    print('Импортировано $imported приложений');
  }
}

/// Пример 6: Обработка ошибок
Future<void> exampleErrorHandling(OAuthAppsService service) async {
  await service.initialize();

  // Попытка получить несуществующее приложение
  final result = await service.getApp('non-existent-id');
  result.fold(
    (app) {
      print('Приложение найдено: ${app.name}');
    },
    (error) {
      error.when(
        notFound: (code, message, data, stackTrace, timestamp) {
          print('Приложение не найдено: $message');
        },
        alreadyExists: (code, message, data, stackTrace, timestamp) {
          print('Приложение уже существует: $message');
        },
        storageError: (code, message, data, stackTrace, timestamp) {
          print('Ошибка хранилища: $message');
        },
        serializationError: (code, message, data, stackTrace, timestamp) {
          print('Ошибка сериализации: $message');
        },
        invalidData: (code, message, data, stackTrace, timestamp) {
          print('Некорректные данные: $message');
        },
      );
    },
  );

  // Попытка создать приложение с пустым ID
  final invalidApp = const OauthApps(
    id: '',
    name: 'Invalid App',
    type: OauthAppsType.google,
    clientId: 'client-id',
  );

  final saveResult = await service.saveApp(invalidApp);
  if (saveResult.isError()) {
    print('Ошибка валидации: ${saveResult.exceptionOrNull()?.message}');
  }
}

/// Пример 7: Массовые операции
Future<void> exampleBatchOperations(OAuthAppsService service) async {
  await service.initialize();

  // Создать несколько приложений
  final apps = [
    OauthApps(
      id: const Uuid().v4(),
      name: 'Google Drive',
      type: OauthAppsType.google,
      clientId: 'google-client-id',
    ),
    OauthApps(
      id: const Uuid().v4(),
      name: 'OneDrive',
      type: OauthAppsType.onedrive,
      clientId: 'onedrive-client-id',
    ),
    OauthApps(
      id: const Uuid().v4(),
      name: 'Dropbox',
      type: OauthAppsType.dropbox,
      clientId: 'dropbox-client-id',
    ),
  ];

  for (final app in apps) {
    await service.createApp(app);
  }

  // Удалить несколько приложений
  final idsToDelete = apps.take(2).map((app) => app.id).toList();
  await service.deleteApps(idsToDelete);

  // Очистить все приложения
  await service.clearAll();
}

/// Пример 8: Оптимизация хранилища
Future<void> exampleOptimization(OAuthAppsService service) async {
  await service.initialize();

  // Проверить количество приложений
  final count = service.getCount();
  print('Приложений в хранилище: $count');

  // Компактировать хранилище для освобождения места
  final compactResult = await service.compact();
  if (compactResult.isSuccess()) {
    print('Хранилище успешно оптимизировано');
  }
}

/// Пример 9: Использование с Riverpod
/// ```dart
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// import 'package:hoplixi/features/cloud_sync/oauth_apps/providers/oauth_apps_service_provider.dart';
///
/// class OAuthAppsScreen extends ConsumerWidget {
///   const OAuthAppsScreen({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final service = ref.watch(oAuthAppsServiceProvider);
///
///     return FutureBuilder(
///       future: service.getAllApps(),
///       builder: (context, snapshot) {
///         if (snapshot.connectionState == ConnectionState.waiting) {
///           return const CircularProgressIndicator();
///         }
///
///         if (snapshot.hasError) {
///           return Text('Ошибка: ${snapshot.error}');
///         }
///
///         final result = snapshot.data;
///         return result!.when(
///           success: (apps) => ListView.builder(
///             itemCount: apps.length,
///             itemBuilder: (context, index) {
///               final app = apps[index];
///               return ListTile(
///                 title: Text(app.name),
///                 subtitle: Text(app.type.name),
///               );
///             },
///           ),
///           failure: (error) => Text('Ошибка: ${error.message}'),
///         );
///       },
///     );
///   }
/// }
/// ```

/// Пример 10: Полный жизненный цикл
Future<void> exampleFullLifecycle(OAuthAppsService service) async {
  // 1. Инициализация
  await service.initialize();

  // 2. Создание встроенных приложений
  final builtinApps = [
    const OauthApps(
      id: 'google-builtin',
      name: 'Google (встроенное)',
      type: OauthAppsType.google,
      clientId: 'builtin-google-client-id',
      isBuiltin: true,
    ),
    const OauthApps(
      id: 'dropbox-builtin',
      name: 'Dropbox (встроенное)',
      type: OauthAppsType.dropbox,
      clientId: 'builtin-dropbox-client-id',
      isBuiltin: true,
    ),
  ];

  for (final app in builtinApps) {
    await service.createApp(app);
  }

  // 3. Проверка существования
  if (service.appExists('google-builtin')) {
    print('Встроенное приложение Google существует');
  }

  // 4. Работа с данными
  final customApp = OauthApps(
    id: const Uuid().v4(),
    name: 'My Custom App',
    type: OauthAppsType.other,
    clientId: 'custom-client-id',
    clientSecret: 'custom-secret',
  );

  await service.createApp(customApp);

  // 5. Получение статистики
  print('Всего приложений: ${service.getCount()}');

  final builtinResult = await service.getBuiltinApps();
  if (builtinResult.isSuccess()) {
    print('Встроенных: ${builtinResult.getOrNull()?.length}');
  }

  final customResult = await service.getCustomApps();
  if (customResult.isSuccess()) {
    print('Пользовательских: ${customResult.getOrNull()?.length}');
  }

  // 6. Оптимизация
  await service.compact();

  // 7. Завершение работы
  await service.dispose();
}
