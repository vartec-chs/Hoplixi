# Встроенные OAuth приложения

## Обзор

Система поддерживает встроенные OAuth приложения, которые автоматически загружаются из переменных окружения `.env` файла при инициализации сервиса. Эти приложения предназначены для быстрого старта и не могут быть изменены или удалены пользователем через UI.

## Конфигурация .env

### Глобальные настройки

```env
# Включить/выключить все встроенные приложения
USED_BUILTIN_AUTH_APPS=true
```

### Конфигурация провайдеров

Каждый провайдер OAuth настраивается через набор переменных:

#### Google OAuth

```env
GOOGLE_BUILTIN_ENABLED=true
GOOGLE_APP_NAME=Hoplixi
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

#### Dropbox OAuth

```env
DROPBOX_BUILTIN_ENABLED=true
DROPBOX_APP_NAME=Hoplixi
DROPBOX_CLIENT_ID=your-dropbox-client-id
DROPBOX_CLIENT_SECRET=your-dropbox-client-secret
```

#### Yandex OAuth

```env
YANDEX_BUILTIN_ENABLED=true
YANDEX_APP_NAME=Hoplixi
YANDEX_CLIENT_ID=your-yandex-client-id
YANDEX_CLIENT_SECRET=your-yandex-client-secret
```

#### OneDrive OAuth

```env
ONEDRIVE_BUILTIN_ENABLED=true
ONEDRIVE_APP_NAME=Hoplixi
ONEDRIVE_CLIENT_ID=your-onedrive-client-id
ONEDRIVE_CLIENT_SECRET=
```

**Примечание:** `CLIENT_SECRET` может быть пустым для публичных OAuth клиентов.

## Логика работы

### Инициализация

При вызове `OAuthAppsService.initialize()`:

1. Открывается Hive бокс для хранения приложений
2. Проверяется флаг `USED_BUILTIN_AUTH_APPS`
3. Если флаг `true`, загружаются настройки каждого провайдера
4. Для каждого провайдера с `*_BUILTIN_ENABLED=true`:
   - Создается объект `OauthApps` с `isBuiltin: true`
   - ID формируется как `builtin-{type}` (например, `builtin-google`)
   - Приложение сохраняется в Hive (если не существует)
   - Если существует, обновляются учетные данные

### ID встроенных приложений

Формат ID: `builtin-{type}`

Примеры:
- `builtin-google`
- `builtin-dropbox`
- `builtin-yandex`
- `builtin-onedrive`

### Защита от изменений

#### В сервисе

- `updateApp()` - проверяет флаг `isBuiltin` и возвращает ошибку
- `deleteApp()` - проверяет флаг `isBuiltin` и возвращает ошибку

#### В UI

- Встроенные приложения отображаются отдельной секцией
- Карточки встроенных приложений не кликабельны (`onTap: null`)
- Кнопка удаления не отображается (`onDelete: null`)
- Модальное окно не открывается для встроенных приложений

## Использование в коде

### Получение встроенных приложений

```dart
final service = ref.read(oauthAppsServiceProvider);
await service.initialize();

final result = await service.getBuiltinApps();
result.fold(
  (apps) {
    // Обработка списка встроенных приложений
    for (final app in apps) {
      print('${app.name}: ${app.clientId}');
    }
  },
  (error) {
    print('Ошибка: ${error.message}');
  },
);
```

### Перезагрузка встроенных приложений

```dart
// Полезно после изменения .env файла
final result = await service.reloadBuiltinApps();
if (result.isSuccess()) {
  print('Встроенные приложения обновлены');
}
```

### Проверка существования

```dart
if (service.appExists('builtin-google')) {
  final result = await service.getApp('builtin-google');
  // Работа с приложением
}
```

## Разделение в UI

Экран `OAuthAppsScreen` автоматически разделяет приложения на две группы:

1. **Встроенные приложения** (`app.isBuiltin == true`)
   - Отображаются в верхней секции
   - Нельзя редактировать
   - Нельзя удалить
   - Помечены бейджем "Встроенное"

2. **Пользовательские приложения** (`app.isBuiltin == false`)
   - Отображаются в нижней секции
   - Можно редактировать
   - Можно удалить

## Обработка ошибок

### При попытке изменить встроенное приложение

```dart
final result = await service.updateApp(builtinApp);
result.fold(
  (_) => print('Успешно обновлено'),
  (error) => print(error.message), // "Встроенные OAuth приложения нельзя редактировать"
);
```

### При попытке удалить встроенное приложение

```dart
final result = await service.deleteApp('builtin-google');
result.fold(
  (_) => print('Успешно удалено'),
  (error) => print(error.message), // "Встроенные OAuth приложения нельзя удалять"
);
```

## Логирование

Сервис логирует следующие события:

- Загрузку встроенных приложений
- Создание/обновление каждого встроенного приложения
- Попытки изменить/удалить встроенные приложения
- Ошибки при парсинге .env переменных

Все логи помечены тегом `OAuthAppsService`.

## Лучшие практики

1. **Безопасность**: Не храните реальные `CLIENT_SECRET` в репозитории
2. **Конфигурация**: Используйте разные `.env` файлы для dev/prod
3. **Обновления**: После изменения `.env`, перезапустите приложение или вызовите `reloadBuiltinApps()`
4. **Тестирование**: Используйте тестовые OAuth приложения в dev окружении

## Примеры

Полные примеры использования см. в файле:
`lib/features/cloud_sync/oauth_apps/services/oauth_apps_builtin_examples.dart`
