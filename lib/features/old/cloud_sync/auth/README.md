# OAuth Provider Service

Сервис для управления OAuth2 провайдерами и авторизацией в приложении.

## Архитектура

```
┌─────────────────────────┐
│  OAuthAppsService       │  ← Управляет OAuth приложениями (хранение в Hive)
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ OauthProvidersService   │  ← Основной сервис (этот файл)
└───────────┬─────────────┘
            │
            ├─→ TokenService (хранение токенов)
            │
            ├─→ OAuth2Account (из cloud_storage_all)
            │   └─→ OAuthProviderWrapper (обертка для уникальных имен)
            │       └─→ Google/Dropbox/Yandex/Microsoft
            │
            └─→ OAuth2RestClient (кэш HTTP клиентов)
```

## Ключевые особенности

### 1. Уникальные имена провайдеров

Каждое OAuth-приложение получает уникальное имя на основе `app.id`, что позволяет:
- Использовать несколько приложений одного типа (например, два Google-аккаунта)
- Избежать конфликтов имен в Map внутри OAuth2Account
- Гибко управлять несколькими OAuth-приложениями

**Реализация:**
- `OAuthProviderWrapper` оборачивает базовый провайдер (Google, Dropbox и т.д.)
- При регистрации провайдера используется `app.id` как уникальное имя
- Все методы ожидают `app.id` вместо типа провайдера

### 2. Централизованное управление токенами

- Токены хранятся через `TokenService` (secure storage)
- Автоматическое обновление токенов через `OAuth2Account`
- Защита от одновременных запросов обновления токена

### 3. Кэширование HTTP клиентов

- Клиенты кэшируются по ключу `provider:userName`
- Автоматическое обновление токенов в клиентах
- Управление жизненным циклом клиентов

## UI компоненты

### OAuthLoginScreen

Готовый UI компонент для OAuth авторизации с выбором провайдера.

**Возможности:**
- Выбор OAuth провайдера из списка доступных
- Автоматический вход с сохраненными аккаунтами
- Новый вход через браузер
- Обработка ошибок и loading состояний
- Material Design 3 интерфейс

**Быстрый старт:**

```dart
import 'package:hoplixi/features/old/cloud_sync/auth/ui/oauth_login_screen.dart';

// Открыть экран авторизации
final token = await Navigator.of(context).push<OAuth2Token>(
  MaterialPageRoute(
    builder: (context) => const OAuthLoginScreen(),
  ),
);

if (token != null) {
  // Токен получен - можно использовать для API запросов
  print('Авторизован: ${token.userName}');
}
```

**Архитектура:**
- `OAuthLoginState` - Freezed модель состояния
- `OAuthLoginNotifier` - AsyncNotifier с бизнес-логикой
- `authLoginProvider` - AsyncNotifierProvider
- `OAuthLoginScreen` - ConsumerWidget UI

См. [ui/README.md](./ui/README.md) для подробной документации.

## API

### Инициализация

```dart
final service = OauthProvidersService(
  appsService: oAuthAppsService,
  tokenService: tokenService,
);

await service.initialize();
```

### Получение списка провайдеров

```dart
final result = await service.getRegisteredProviders();
final appIds = result.getOrThrow(); // ['app_id_1', 'app_id_2', ...]
```

### Вход в систему

```dart
// Новый вход
final loginResult = await service.login(appId);
final token = loginResult.getOrThrow();

// Автоматический вход (если токен есть)
final autoLoginResult = await service.tryAutoLogin(appId, userName);

// Принудительный повторный вход
final reloginResult = await service.forceRelogin(expiredToken);
```

### Управление токенами

```dart
// Обновить токен
final refreshResult = await service.refreshToken(expiredToken);

// Загрузить сохраненный токен
final tokenResult = await service.loadAccount(appId, userName);

// Получить любой доступный токен
final anyTokenResult = await service.getAnyToken(service: appId);
```

### Управление аккаунтами

```dart
// Получить все аккаунты
final accounts = await service.getAllAccounts();

// Получить аккаунты для конкретного провайдера
final googleAccounts = await service.getAllAccounts(service: appId);

// Удалить аккаунт
await service.deleteAccount(appId, userName);
```

### HTTP клиенты

```dart
// Создать или получить клиент
final clientResult = await service.getOrCreateClient(token);
final client = clientResult.getOrThrow();

// Удалить клиент из кэша
await service.removeClient(appId, userName);

// Очистить все клиенты
await service.clearAllClients();
```

## Обработка ошибок

Все методы возвращают `AsyncResultDart<T, ProviderServiceError>`:

```dart
final result = await service.login(appId);

result.fold(
  (success) => print('Token: ${success.accessToken}'),
  (error) => print('Error: ${error.message}'),
);
```

### Типы ошибок

- `ProviderServiceError.initializationFailed` - ошибка инициализации
- `ProviderServiceError.unsupportedProvider` - неподдерживаемый провайдер
- `ProviderServiceError.registrationFailed` - ошибка регистрации провайдера
- `ProviderServiceError.loginFailed` - ошибка входа
- `ProviderServiceError.autoLoginFailed` - ошибка автоматического входа
- `ProviderServiceError.noTokenFound` - токен не найден
- `ProviderServiceError.reloginFailed` - ошибка повторного входа
- `ProviderServiceError.refreshFailed` - ошибка обновления токена
- `ProviderServiceError.operationFailed` - общая ошибка операции

## Примеры использования

### Полный workflow авторизации

```dart
// 1. Получить список доступных провайдеров
final providersResult = await service.getRegisteredProviders();
final appIds = providersResult.getOrThrow();

// 2. Получить информацию о провайдере
final appResult = await service.getAppById(appIds.first);
final app = appResult.getOrThrow();
print('Provider: ${app.name} (${app.type.name})');

// 3. Попробовать автоматический вход
final accounts = await service.getAllAccounts(service: app.id);
if (accounts.isSuccess() && accounts.getOrThrow().isNotEmpty) {
  final (_, userName) = accounts.getOrThrow().first;
  final tokenResult = await service.tryAutoLogin(app.id, userName);
  
  if (tokenResult.isSuccess()) {
    // Успешный авто-вход
    final token = tokenResult.getOrThrow();
    final client = await service.getOrCreateClient(token);
  } else {
    // Требуется новый вход
    final loginResult = await service.login(app.id);
  }
} else {
  // Нет сохраненных аккаунтов
  final loginResult = await service.login(app.id);
}
```

### Работа с несколькими аккаунтами одного типа

```dart
// Получить все Google-приложения
final allApps = await appsService.getAllApps();
final googleApps = allApps.getOrThrow()
    .where((app) => app.type == OauthAppsType.google)
    .toList();

// Показать пользователю список
for (final app in googleApps) {
  print('${app.name} - ${app.id}');
}

// Пользователь выбирает нужный аккаунт
final selectedApp = googleApps.first;
await service.login(selectedApp.id);
```

## Миграция

См. [MIGRATION.md](./MIGRATION.md) для информации о миграции с предыдущих версий.

## Тестирование

Тесты находятся в `test/unit/features/cloud_sync/oauth/`:
- `oauth_provider_wrapper_test.dart` - тесты wrapper-класса
- *(добавьте другие тесты по мере необходимости)*

```bash
flutter test test/unit/features/cloud_sync/oauth/
```
