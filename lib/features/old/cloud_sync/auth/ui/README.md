# OAuth Login UI

UI компонент для OAuth авторизации с выбором провайдера, построенный на AsyncNotifierProvider.

## Архитектура

```
┌──────────────────────┐
│  OAuthLoginScreen    │  ← UI (ConsumerWidget)
└──────────┬───────────┘
           │ watches
           ▼
┌──────────────────────┐
│ authLoginProvider   │  ← AsyncNotifierProvider
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ OAuthLoginNotifier   │  ← AsyncNotifier (бизнес-логика)
└──────────┬───────────┘
           │
           ├─→ OauthProvidersService (OAuth операции)
           └─→ OAuthLoginState (состояние)
```

## Компоненты

### 1. OAuthLoginState (Модель состояния)

Freezed-модель, описывающая все возможные состояния процесса авторизации:

```dart
@freezed
class OAuthLoginState with _$OAuthLoginState {
  const factory OAuthLoginState({
    /// Список доступных OAuth приложений
    @Default([]) List<OauthApps> availableApps,
    
    /// Текущий выбранный провайдер (app.id)
    String? selectedProviderId,
    
    /// Информация о выбранном приложении
    OauthApps? selectedApp,
    
    /// Состояние процесса авторизации
    @Default(LoginStatus.idle) LoginStatus loginStatus,
    
    /// Полученный токен после успешной авторизации
    OAuth2Token? token,
    
    /// Сообщение об ошибке
    String? errorMessage,
    
    /// Список сохраненных аккаунтов для выбранного провайдера
    @Default([]) List<SavedAccount> savedAccounts,
  }) = _OAuthLoginState;
}
```

**LoginStatus:**
- `idle` - начальное состояние
- `loadingProviders` - загрузка списка провайдеров
- `autoLogin` - попытка автоматического входа
- `loggingIn` - выполнение нового входа
- `success` - успешная авторизация
- `error` - ошибка авторизации

### 2. OAuthLoginNotifier (Бизнес-логика)

AsyncNotifier, управляющий процессом авторизации:

```dart
class OAuthLoginNotifier extends AsyncNotifier<OAuthLoginState> {
  /// Выбрать провайдера
  Future<void> selectProvider(String providerId)
  
  /// Попробовать автоматический вход с сохраненным аккаунтом
  Future<void> tryAutoLogin(String userName)
  
  /// Выполнить новый вход
  Future<void> login()
  
  /// Сбросить состояние к выбору провайдера
  void reset()
  
  /// Перезагрузить список провайдеров
  Future<void> reload()
}
```

### 3. OAuthLoginScreen (UI)

ConsumerWidget, отображающий интерфейс авторизации:

- **Экран выбора провайдера** - список доступных OAuth приложений
- **Экран авторизации** - форма входа с сохраненными аккаунтами
- **Экран успеха** - подтверждение успешной авторизации

## Использование

### Базовое использование

```dart
import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/oauth/ui/oauth_login_screen.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Открыть экран авторизации
        final token = await Navigator.of(context).push<OAuth2Token>(
          MaterialPageRoute(
            builder: (context) => const OAuthLoginScreen(),
          ),
        );
        
        if (token != null) {
          // Токен получен, можно использовать
          print('Авторизован: ${token.userName}');
        }
      },
      child: const Text('Подключить облачное хранилище'),
    );
  }
}
```

### Использование с провайдером в родительском виджете

```dart
class MyFeature extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(authLoginProvider);
    
    return loginState.when(
      data: (state) {
        if (state.token != null) {
          // Токен получен - показать основной интерфейс
          return MainView(token: state.token!);
        }
        
        // Показать кнопку входа
        return ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OAuthLoginScreen(),
              ),
            );
          },
          child: const Text('Войти'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
    );
  }
}
```

### Программное управление состоянием

```dart
class CustomLoginFlow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(authLoginProvider.notifier);
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            // Выбрать первый доступный провайдер
            final state = ref.read(authLoginProvider).valueOrNull;
            if (state != null && state.availableApps.isNotEmpty) {
              await notifier.selectProvider(state.availableApps.first.id);
              await notifier.login();
            }
          },
          child: const Text('Быстрый вход'),
        ),
        ElevatedButton(
          onPressed: () => notifier.reset(),
          child: const Text('Сбросить'),
        ),
      ],
    );
  }
}
```

## Workflow

### 1. Инициализация

```
OAuthLoginScreen открыт
        ↓
OAuthLoginNotifier.build() вызван
        ↓
Загрузка OauthProvidersService (ожидание инициализации)
        ↓
Получение списка зарегистрированных провайдеров
        ↓
Для каждого providerId получение OauthApps
        ↓
State: OAuthLoginState(availableApps: [...], loginStatus: idle)
```

### 2. Выбор провайдера

```
Пользователь выбирает провайдера
        ↓
notifier.selectProvider(appId)
        ↓
Получение информации о приложении
        ↓
Загрузка сохраненных аккаунтов для провайдера
        ↓
State: OAuthLoginState(
  selectedProviderId: appId,
  selectedApp: app,
  savedAccounts: [...],
  loginStatus: idle
)
```

### 3A. Автоматический вход (если есть сохраненные аккаунты)

```
Пользователь выбирает сохраненный аккаунт
        ↓
notifier.tryAutoLogin(userName)
        ↓
State: loginStatus = autoLogin
        ↓
service.tryAutoLogin(providerId, userName)
        ↓
Success: State: loginStatus = success, token = ...
        ↓
Error: State: loginStatus = idle, errorMessage = ...
```

### 3B. Новый вход

```
Пользователь нажимает "Войти"
        ↓
notifier.login()
        ↓
State: loginStatus = loggingIn
        ↓
service.login(providerId) - открывается браузер
        ↓
Пользователь авторизуется в браузере
        ↓
Success: State: loginStatus = success, token = ...
        ↓
Error: State: loginStatus = error, errorMessage = ...
```

### 4. Завершение

```
State: loginStatus = success, token != null
        ↓
UI показывает экран успеха
        ↓
Пользователь нажимает "Готово"
        ↓
Navigator.pop(token) - возврат токена вызывающему коду
```

## Обработка состояний

### AsyncValue состояния

```dart
final loginState = ref.watch(authLoginProvider);

loginState.when(
  data: (state) {
    // Состояние загружено
    switch (state.loginStatus) {
      case LoginStatus.idle:
        // Показать форму входа
      case LoginStatus.loggingIn:
      case LoginStatus.autoLogin:
        // Показать индикатор загрузки
      case LoginStatus.success:
        // Показать успех
      case LoginStatus.error:
        // Показать ошибку
      case LoginStatus.loadingProviders:
        // Загрузка провайдеров
    }
  },
  loading: () {
    // Начальная загрузка провайдеров
    return const CircularProgressIndicator();
  },
  error: (error, stack) {
    // Критическая ошибка (например, сервис не инициализирован)
    return ErrorWidget(error);
  },
);
```

### Отслеживание изменений

```dart
ref.listen(authLoginProvider, (previous, next) {
  next.whenData((state) {
    if (state.loginStatus == LoginStatus.success) {
      // Успешная авторизация
      Toaster.success(
        title: 'Успешная авторизация',
        description: 'Подключен: ${state.token!.userName}',
      );
    } else if (state.loginStatus == LoginStatus.error) {
      // Ошибка авторизации
      Toaster.error(
        title: 'Ошибка авторизации',
        description: state.errorMessage ?? 'Неизвестная ошибка',
      );
    }
  });
});
```

## Кастомизация

### Изменение внешнего вида провайдеров

```dart
// В _ProviderIcon можно добавить кастомные иконки
class _ProviderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Используйте AssetImage для кастомных иконок
    return Image.asset(
      'assets/icons/${type.identifier}.png',
      width: 32,
      height: 32,
    );
  }
}
```

### Добавление дополнительной валидации

```dart
class CustomOAuthLoginNotifier extends OAuthLoginNotifier {
  @override
  Future<void> login() async {
    // Дополнительная логика перед входом
    if (!await _checkInternetConnection()) {
      state = AsyncData(
        state.valueOrNull!.copyWith(
          loginStatus: LoginStatus.error,
          errorMessage: 'Нет интернет соединения',
        ),
      );
      return;
    }
    
    await super.login();
  }
}
```

## Тестирование

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('OAuthLoginNotifier', () {
    test('должен загрузить список провайдеров при инициализации', () async {
      final container = ProviderContainer(
        overrides: [
          oauthProvidersServiceAsyncProvider.overrideWith(
            (ref) => Future.value(mockService),
          ),
        ],
      );
      
      final state = await container.read(authLoginProvider.future);
      
      expect(state.availableApps, isNotEmpty);
      expect(state.loginStatus, LoginStatus.idle);
    });
    
    test('должен выбрать провайдера и загрузить сохраненные аккаунты', () async {
      final container = ProviderContainer();
      final notifier = container.read(authLoginProvider.notifier);
      
      await notifier.selectProvider('test_app_id');
      
      final state = container.read(authLoginProvider).valueOrNull;
      expect(state?.selectedProviderId, 'test_app_id');
      expect(state?.selectedApp, isNotNull);
    });
  });
}
```

## Зависимости

- `flutter_riverpod` - state management
- `freezed` - immutable models
- `cloud_storage_all` - OAuth2Token
- `hoplixi/core/logger` - логирование
- `hoplixi/core/utils/toastification` - уведомления
- `hoplixi/shared/ui/button` - кнопки

## См. также

- [oauth_providers_service.dart](../services/oauth_providers_service.dart) - сервис OAuth
- [oauth_apps.dart](../../oauth_apps/models/oauth_apps.dart) - модель приложений
- [Riverpod.md](../../../../docs/Riverpod.md) - документация по Riverpod
