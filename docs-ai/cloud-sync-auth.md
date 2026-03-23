# Cloud Sync Auth

Документация по новому модулю `lib/features/cloud_sync/auth` и его связям с `app_credentials`, `auth_tokens` и роутингом.

## Назначение

Модуль реализует кроссплатформенную OAuth-авторизацию для cloud sync без зависимости от `lib/features/old/cloud_sync`.

Поддерживаемый сценарий:

1. Пользователь запускает flow из Home.
2. Открывается `WoltModalSheet` с выбором провайдера.
3. На втором шаге пользователь выбирает `app_credentials` для этого провайдера.
4. Запускается OAuth flow.
5. Пользователь переводится на progress route.
6. После успеха токен сохраняется в `auth_tokens`.
7. После `success`, `cancelled` или `failure` происходит возврат на сохранённый прошлый маршрут.

## Структура

### Shared config

`lib/features/cloud_sync/common/models/cloud_sync_provider.dart`

Содержит единый enum провайдеров и их metadata:

- display name и icon
- authorization/token/userinfo endpoint
- desktop redirect URI
- mobile redirect policy
- default scopes
- provider-specific auth parameters

Это главный source of truth для UI и OAuth orchestration.

### Auth models

`lib/features/cloud_sync/auth/models/`

Основные модели:

- `AuthFlowStatus`
- `AuthFlowState`
- `AuthFlowSuccessResult`
- `CloudSyncAuthError`
- `CloudSyncOAuthResult`
- `AuthCredentialOption`

`AuthFlowState` является единым source of truth для router и UI.

### Auth services

`lib/features/cloud_sync/auth/services/`

Слой разделён по ответственности:

- `cloud_sync_auth_service.dart`
  - orchestration
  - выбор стратегии по platform/provider
  - сохранение токена в `auth_tokens`
  - кооперативная отмена flow
- `cloud_sync_appauth_mobile_service.dart`
  - mobile OAuth через `flutter_appauth`
  - используется для всех mobile провайдеров, кроме Google
- `cloud_sync_google_sign_in_service.dart`
  - mobile Google flow через `google_sign_in`
- `cloud_sync_desktop_loopback_service.dart`
  - desktop Authorization Code + PKCE + loopback server на `127.0.0.1:8569`
- `cloud_sync_oauth_http_service.dart`
  - token exchange
  - user info fetch

### Auth providers

`lib/features/cloud_sync/auth/providers/auth_flow_provider.dart`

Публичный API notifier:

- `startFlow({required String previousRoute})`
- `selectProvider(CloudSyncProvider provider)`
- `selectCredential(String credentialId)`
- `beginAuthorization()`
- `cancelActiveFlow()`
- `clearTerminalState()`

Derived providers:

- `cloudSyncSupportedAuthProvidersProvider`
- `authCredentialOptionsProvider`

### Auth UI

`lib/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart`

- показывает 2-step modal flow
- шаг 1: выбор провайдера
- шаг 2: выбор credentials
- если credentials нет, даёт CTA на экран `app_credentials`
- неподдерживаемые credentials не скрываются, а показываются disabled с причиной

`lib/features/cloud_sync/auth/screens/auth_progress_screen.dart`

- progress route с spinner и кнопкой `Cancel`
- слушает terminal state
- показывает toast
- возвращает пользователя на `previousRoute`

## Роутинг

Новые точки интеграции:

- `AppRoutesPaths.cloudSyncAuthProgress`
- `AuthProgressScreen` в `routes.dart`
- `router_refresh_provider.dart` слушает `authFlowProvider`
- `router.dart` удерживает пользователя на progress route, пока `status == inProgress`

Home entrypoint:

- в `home_screen.dart` добавлено production action для запуска cloud auth flow

## Поведение по платформам

### Desktop

Для Windows, macOS и Linux используется loopback flow:

- browser-based OAuth authorization
- PKCE
- локальный сервер на `127.0.0.1:8569`
- явная отмена через кнопку на progress screen
- явные ошибки при timeout, provider error, network error

### Mobile

#### Google

Используется `google_sign_in`.

Особенности:

- flow рассчитан на access token
- refresh token на mobile не гарантирован
- в текущей архитектуре `google_sign_in` инициализируется один раз на app session
- если в одной сессии попытаться использовать другой Google `client_id`, flow будет отклонён как unsupported

#### Остальные провайдеры

Используется `flutter_appauth`.

Redirect URI определяется из metadata провайдера и выбранных credentials.

## Ограничения v1

### Dropbox custom credentials на mobile

Не поддерживаются.

Причина:

- Dropbox mobile redirect URI имеет вид `db-<client_id>://oauth2redirect`
- такую схему нельзя безопасно зарегистрировать динамически под произвольный пользовательский `client_id`

Текущее поведение:

- на desktop Dropbox работает
- на mobile custom Dropbox credentials отображаются disabled
- mobile Dropbox допустим только для заранее встроенных credentials с уже зарегистрированной схемой

### OneDrive

В UI для создания credentials используется generic app redirect (`hoplixiauth://oauth2redirect`), чтобы не привязывать v1 к жёсткой app-bound конфигурации.

### Provider `other`

Не участвует в auth UI и orchestration, пока для него не добавлена полноценная OAuth metadata-конфигурация.

## Сохранение токенов

Слой `auth_tokens` был расширен так, чтобы повторная авторизация обновляла существующую запись, если совпадает:

- `provider`
- `appCredentialId`
- `accountId` или `accountEmail`

Если совпадение не найдено, создаётся новая token entry.

## Добавление нового провайдера

Минимальные шаги:

1. Расширить `CloudSyncProvider`.
2. Добавить metadata в `cloud_sync_provider.dart`.
3. Указать endpoints, scopes, redirect policy и auth flags.
4. При необходимости добавить provider-specific auth parameters.
5. При необходимости расширить extraction логики user info.
6. Если provider поддерживается на mobile, зарегистрировать нужный redirect scheme в platform config.
7. Если provider должен появиться в auth UI, metadata должна вернуть `supportsAuth == true`.

## Platform config

Текущая реализация добавляет:

- Android `RedirectUriReceiverActivity` для `hoplixiauth://oauth2redirect`
- iOS `CFBundleURLTypes` для `hoplixiauth`
- macOS `CFBundleURLTypes` для `hoplixiauth`

Важно:

- для конкретных provider apps пользователь всё равно должен правильно настроить redirect URI в консоли провайдера
- для mobile Google и AppAuth provider apps platform-side registration должна совпадать с выбранными credentials

## Что не используется

- `lib/features/old/cloud_sync/*`
- старые `oauthApps/oauthTokens/oauthLogin` маршруты как источник логики

Они сохранены нетронутыми и не участвуют в новом auth flow.
