# OAuth Provider Service Migration Guide

## Изменения в версии (текущей)

### Проблема
Ранее все OAuth-приложения одного типа (например, несколько Google-аккаунтов) создавали провайдеры с одинаковым именем, что приводило к их перезаписи в `Map<String, OAuth2Provider>` внутри `OAuth2Account`.

### Решение
Теперь каждое OAuth-приложение получает уникальное имя провайдера на основе `app.id`.

### Что изменилось

#### 1. Параметр `provider` теперь ожидает `app.id`

**Раньше:**
```dart
// Использовался тип провайдера
await providerService.login('google');
await providerService.tryAutoLogin('google', 'user@gmail.com');
```

**Теперь:**
```dart
// Используется app.id
await providerService.login('550e8400-e29b-41d4-a716-446655440000');
await providerService.tryAutoLogin('550e8400-e29b-41d4-a716-446655440000', 'user@gmail.com');
```

#### 2. Новые вспомогательные методы

```dart
// Получить список всех зарегистрированных провайдеров (app.id)
final result = await providerService.getRegisteredProviders();
final appIds = result.getOrThrow(); // ['app_id_1', 'app_id_2', ...]

// Получить информацию о приложении по ID
final appResult = await providerService.getAppById('app_id_1');
final app = appResult.getOrThrow();
print('Provider: ${app.name} (${app.type.name})');
```

### Миграция кода

#### Если вы использовали хардкоженные типы провайдеров

**Раньше:**
```dart
// ❌ Больше не работает
await providerService.login('google');
```

**Теперь:**
```dart
// ✅ Сначала получите app.id из OAuthAppsService или списка провайдеров
final providersResult = await providerService.getRegisteredProviders();
final appIds = providersResult.getOrThrow();

// Фильтруйте по типу, если нужно
for (final appId in appIds) {
  final appResult = await providerService.getAppById(appId);
  final app = appResult.getOrThrow();
  
  if (app.type == OauthAppsType.google) {
    await providerService.login(appId);
    break;
  }
}
```

#### Если вы получали токены через getAllAccounts

**Раньше:**
```dart
// service мог быть типом провайдера
final accounts = await providerService.getAllAccounts(service: 'google');
```

**Теперь:**
```dart
// service теперь app.id (или пусто для всех)
final accounts = await providerService.getAllAccounts(service: appId);

// Или получить все аккаунты и отфильтровать
final allAccounts = await providerService.getAllAccounts();
```

### Рекомендации

1. **Используйте `getRegisteredProviders()`** для получения списка доступных провайдеров
2. **Используйте `getAppById()`** для получения информации о провайдере
3. **Сохраняйте app.id** в вашем состоянии/конфигурации, если нужно работать с конкретным провайдером
4. **Не хардкодьте app.id** - получайте их динамически через сервис

### Преимущества новой системы

- ✅ Поддержка нескольких аккаунтов одного типа (несколько Google, Dropbox и т.д.)
- ✅ Уникальная идентификация каждого OAuth-приложения
- ✅ Нет конфликтов имен провайдеров
- ✅ Более гибкая система управления приложениями

### Пример полного workflow

```dart
// 1. Инициализация
await providerService.initialize();

// 2. Получить список провайдеров
final providersResult = await providerService.getRegisteredProviders();
final appIds = providersResult.getOrThrow();

// 3. Показать пользователю список провайдеров
for (final appId in appIds) {
  final appResult = await providerService.getAppById(appId);
  if (appResult.isSuccess()) {
    final app = appResult.getOrThrow();
    print('${app.name} (${app.type.name})');
  }
}

// 4. Пользователь выбирает провайдер (appId)
final selectedAppId = appIds.first;

// 5. Попробовать авто-вход или новый вход
final accounts = await providerService.getAllAccounts(service: selectedAppId);
if (accounts.isSuccess() && accounts.getOrThrow().isNotEmpty) {
  final (_, userName) = accounts.getOrThrow().first;
  final tokenResult = await providerService.tryAutoLogin(selectedAppId, userName);
  
  if (tokenResult.isError()) {
    // Авто-вход не удался, выполнить новый вход
    await providerService.login(selectedAppId);
  }
} else {
  // Нет сохраненных аккаунтов, выполнить новый вход
  await providerService.login(selectedAppId);
}
```
