# Cloud Sync Module

Сводная техническая документация по новому модулю `lib/features/cloud_sync`.

Документ нужен как единая точка входа для дальнейшей разработки. Детальные заметки по подсистемам уже лежат отдельно:

- `docs-ai/cloud-sync-auth.md`
- `docs-ai/cloud-sync-http.md`
- `docs-ai/cloud-sync-storage.md`

Этот файл описывает всю картину целиком: архитектуру, границы модулей, публичные контракты, маршруты, текущие ограничения и практические правила расширения.

## 1. Назначение

`lib/features/cloud_sync` это новая, независимая от `lib/features/old/cloud_sync` реализация cloud sync.

Текущий модуль закрывает:

- конфигурацию OAuth app credentials
- OAuth-авторизацию провайдеров
- хранение OAuth токенов
- низкоуровневый HTTP transport с авто-refresh
- единый storage-контракт поверх разных облаков
- UI-полигон для ручной проверки работы провайдеров

Старый модуль `lib/features/old/cloud_sync` не используется как runtime-логика и должен считаться read-only reference.

## 2. Верхнеуровневая архитектура

Модуль разбит на 7 зон:

- `app_credentials`
- `auth`
- `auth_tokens`
- `common`
- `http`
- `storage`
- `screens`

Поток данных выглядит так:

1. Пользователь настраивает или выбирает `AppCredentialEntry`.
2. `auth` запускает OAuth flow для выбранного провайдера и credential.
3. После успеха токен сохраняется как `AuthTokenEntry`.
4. `http` создаёт авторизованный `Dio`-клиент по `tokenId`.
5. `storage` получает token-bound provider и выполняет файловые операции.
6. `screens/cloud_sync_storage_screen.dart` использует `storage` как UI-полигон.

## 3. Структура директорий

### `common`

`lib/features/cloud_sync/common/models/cloud_sync_provider.dart`

Единый enum всех провайдеров:

- `dropbox`
- `google`
- `onedrive`
- `yandex`
- `other`

Их metadata это главный source of truth для:

- display name и icon
- OAuth endpoints
- redirect policy
- scopes
- userinfo endpoint
- auth scheme для cloud API
- provider capabilities

### `app_credentials`

Отвечает за OAuth app configuration.

Ключевые файлы:

- `models/app_credential_entry.dart`
- `models/builtin_app_credentials.dart`
- `services/app_credentials_service.dart`
- `providers/app_credentials_provider.dart`
- `screens/app_credentials_screen.dart`
- `screens/app_credential_editor_screen.dart`

Основная модель:

```dart
AppCredentialEntry {
  id,
  provider,
  name,
  clientId,
  clientSecret,
  isBuiltin,
  platformTarget, // all | desktop | mobile
  createdAt,
  updatedAt,
}
```

Особенности:

- builtin credentials читаются из `.env`
- user credentials хранятся в Hive
- `platformTarget` управляет совместимостью credential с desktop/mobile
- editor UI умеет подсказывать redirect URI и provider-specific setup info

### `auth`

Отвечает за OAuth flow и orchestration.

Ключевые файлы:

- `models/auth_flow_state.dart`
- `models/auth_flow_status.dart`
- `models/cloud_sync_auth_error.dart`
- `models/cloud_sync_auth_method.dart`
- `providers/auth_flow_provider.dart`
- `services/cloud_sync_auth_service.dart`
- `services/cloud_sync_appauth_mobile_service.dart`
- `services/cloud_sync_google_sign_in_service.dart`
- `services/cloud_sync_desktop_loopback_service.dart`
- `services/cloud_sync_oauth_http_service.dart`
- `screens/auth_progress_screen.dart`
- `widgets/show_cloud_sync_auth_sheet.dart`
- `widgets/cloud_sync_auth_flow_listener.dart`

`AuthFlowNotifier` это единая state-machine для UI и router.

Статусы:

- `idle`
- `selectingProvider`
- `selectingCredential`
- `inProgress`
- `success`
- `cancelled`
- `failure`

Методы провайдера:

- `startFlow({required String previousRoute})`
- `selectProvider(CloudSyncProvider provider)`
- `selectCredential(String credentialId)`
- `beginAuthorization(...)`
- `cancelActiveFlow()`
- `clearTerminalState()`

### `auth_tokens`

Отвечает за сохранённые OAuth токены.

Ключевые файлы:

- `models/auth_token_entry.dart`
- `services/auth_tokens_service.dart`
- `providers/auth_tokens_provider.dart`
- `screens/auth_tokens_screen.dart`

Основная модель:

```dart
AuthTokenEntry {
  id,
  provider,
  accessToken,
  refreshToken,
  tokenType,
  expiresAt,
  scopes,
  appCredentialId,
  appCredentialName,
  accountId,
  accountEmail,
  accountName,
  extraData,
  createdAt,
  updatedAt,
}
```

Особенности:

- токены хранятся в Hive
- повторная авторизация обновляет существующую запись, если совпадают provider + credential + account
- `extraData` используется для provider-specific полей
- сервис нормализует `Map<dynamic, dynamic>` из Hive перед `fromJson`

### `http`

Низкоуровневый transport-layer на `dio`.

Ключевые файлы:

- `models/cloud_sync_http_request.dart`
- `models/cloud_sync_upload_request.dart`
- `models/cloud_sync_download_request.dart`
- `models/cloud_sync_http_exception.dart`
- `services/cloud_sync_http_client.dart`
- `services/cloud_sync_http_client_factory.dart`
- `services/cloud_sync_token_refresh_service.dart`
- `services/cloud_sync_token_resolver.dart`
- `providers/cloud_sync_http_provider.dart`

Назначение:

- клиент по `tokenId`
- auto `Authorization`
- refresh после `401`
- retry один раз после refresh
- upload / download / cancel / progress
- типизированные transport errors

### `storage`

Provider-agnostic слой поверх `http`.

Ключевые файлы:

- `models/cloud_resource_ref.dart`
- `models/cloud_resource.dart`
- `models/cloud_file.dart`
- `models/cloud_folder.dart`
- `models/cloud_list_page.dart`
- `models/cloud_move_copy_target.dart`
- `models/cloud_storage_exception.dart`
- `services/cloud_storage_provider.dart`
- `services/cloud_storage_provider_factory.dart`
- `services/cloud_storage_repository.dart`

Runtime provider implementations:

- `providers_impl/yandex_drive/yandex_drive_cloud_storage_provider.dart`
- `providers_impl/dropbox/dropbox_cloud_storage_provider.dart`
- `providers_impl/google_drive/google_drive_cloud_storage_provider.dart`
- `providers_impl/onedrive/onedrive_cloud_storage_provider.dart`

### `screens`

Входные UI-экраны фичи:

- `cloud_sync_playground_screen.dart`
- `cloud_sync_storage_screen.dart`

`cloud_sync_playground_screen.dart` это навигационный полигон фичи.

`cloud_sync_storage_screen.dart` это ручной storage sandbox:

- выбор провайдера
- проверка наличия токена
- запуск авторизации при необходимости
- просмотр папки
- создание папки
- upload / download
- copy / move / delete

## 4. Маршруты

Пути определены в `lib/routing/paths.dart`:

- `/cloud-sync`
- `/cloud-sync/storage`
- `/cloud-sync/app-credentials`
- `/cloud-sync/auth-tokens`
- `/cloud-sync/auth/progress`

Маршруты зарегистрированы в `lib/routing/routes.dart`.

Особенности routing:

- `router.dart` принудительно удерживает пользователя на `/cloud-sync/auth/progress`, пока `authFlow.status == inProgress`
- `router_refresh_provider.dart` слушает `authFlowProvider`
- глобальный `cloud_sync_auth_flow_listener.dart` показывает terminal errors/success и уводит назад на `previousRoute`

## 5. Провайдеры и capability matrix

### Dropbox

- desktop auth: да
- mobile auth: да
- manual code auth: да
- mobile auto auth: отключён
- mobile manual-only: да
- storage provider: реализован
- API auth scheme: `Bearer`

Особенность:

- mobile redirect у Dropbox зависит от `client_id`: `db-<client_id>://oauth2redirect`
- поэтому arbitrary custom Dropbox credentials на mobile не поддерживаются через auto redirect

### Google

- desktop auth: да
- mobile auth: да
- manual code auth: нет
- mobile auth strategy: `google_sign_in`
- storage provider: реализован
- API auth scheme: `Bearer`

Особенности:

- mobile flow использует `google_sign_in`, а не `flutter_appauth`
- Android/iOS конфиг особенно чувствителен к package name / SHA / server client ID
- на Android ошибки конфигурации Google могут приходить как `canceled`, хотя пользователь ничего не отменял

### OneDrive

- desktop auth: да
- mobile auth: да
- manual code auth: нет
- mobile auth strategy: `flutter_appauth`
- storage provider: реализован
- API auth scheme: `Bearer`

### Yandex

- desktop auth: да
- mobile auth: да
- manual code auth: в metadata поддерживается
- storage provider: реализован
- API auth scheme: `OAuth`

Особенность:

- для Yandex Disk cloud API обязательно использовать `Authorization: OAuth <token>`, а не `Bearer`

### Other

- auth: нет
- storage: нет
- зарезервирован под будущие интеграции

## 6. OAuth flow по платформам

### Desktop

Стратегия:

- browser-based Authorization Code flow
- PKCE
- loopback callback server на `127.0.0.1:8569`

Ключевые части:

- `cloud_sync_desktop_loopback_service.dart`
- `oauth_pkce.dart`
- `desktop_browser_launcher.dart`

Варианты:

- automatic redirect flow
- manual code flow, если провайдер поддерживает это capability

### Mobile Google

Стратегия:

- `cloud_sync_google_sign_in_service.dart`
- `GoogleSignIn.instance.initialize(...)`
- `authenticate()`
- `authorizationClient.authorizationForScopes(...)`
- при возможности `authorizeServer(...)`

### Mobile non-Google

Стратегия:

- `cloud_sync_appauth_mobile_service.dart`
- `flutter_appauth.authorize(...)`
- затем `flutter_appauth.token(...)`

## 7. Storage contract

Базовый контракт:

```dart
abstract interface class CloudStorageProvider {
  CloudSyncProvider get provider;

  Future<CloudResource> getResource(CloudResourceRef ref);
  Future<CloudListPage> listFolder(CloudResourceRef folderRef, {String? cursor, int? pageSize});
  Future<CloudFolder> createFolder({required CloudResourceRef parentRef, required String name});
  Future<CloudFile> uploadFile({...});
  Future<void> downloadFile({...});
  Future<CloudResource> copyResource({...});
  Future<CloudResource> moveResource({...});
  Future<void> deleteResource(CloudResourceRef ref, {bool permanent = true});
}
```

Главная идея:

- UI и бизнес-логика не знают про конкретные Dropbox/Drive endpoints
- provider сам маппит JSON, URL, polling и ошибки в общий контракт

## 8. Адресация ресурсов

Используется `CloudResourceRef`:

- `provider`
- `resourceId`
- `path`
- `isRoot`

Это гибридная адресация.

Как используется сейчас:

- Yandex: основной locator это `path`
- Dropbox: основной locator это `path`
- Google Drive: основной locator это `resourceId`, `path` хранится как pseudo-path для UI
- OneDrive: основной locator это `resourceId`, `path` тоже может использоваться как вспомогательный UI path

Root refs:

- Yandex: `disk:/`
- Dropbox: `''`
- Google: `resourceId: 'root'`
- OneDrive: `resourceId: 'root'`

## 9. HTTP и refresh

`cloud_sync/http` не знает о файловых операциях. Он решает только transport:

- создаёт клиент по `tokenId`
- ставит `Authorization`
- при `401` запускает refresh
- обновляет токен обратно в `auth_tokens`
- повторяет запрос один раз

Refresh зависит от:

- `AuthTokenEntry.refreshToken`
- `AuthTokenEntry.appCredentialId`
- `AppCredentialEntry.clientId/clientSecret`
- `CloudSyncProvider.metadata.tokenEndpoint`

Если refresh token нет, клиент после `401` не сможет обновить доступ и вернёт typed ошибку.

## 10. Текущие storage provider details

### Yandex Drive

Использует API:

- `/resources`
- `/resources/upload`
- `/resources/download`
- `/resources/copy`
- `/resources/move`
- `/resources`
- `/operations/{id}`

Особенности:

- скрывает polling `operation_id`
- `path` хранится как `disk:/...`

### Dropbox

Использует API v2:

- `/files/get_metadata`
- `/files/list_folder`
- `/files/list_folder/continue`
- `/files/create_folder_v2`
- `/files/upload`
- `/files/download`
- `/files/copy_v2`
- `/files/move_v2`
- `/files/delete_v2`

Особенности:

- работает через `path`
- provider делает tolerant JSON parsing, потому что `Dio` иногда возвращает тело как `String`

### Google Drive

Использует Drive API v3:

- `files.get`
- `files.list`
- `files.create`
- `files.copy`
- `files.update`
- `files.delete`
- `files.get?alt=media`

Особенности:

- `resourceId` это основной идентификатор
- upload реализован low-level, без старого кода

### OneDrive

Использует Microsoft Graph:

- `/me/drive/root`
- `/items/{id}`
- `/children`
- `/content`
- `/copy`
- `PATCH /items/{id}`
- `DELETE /items/{id}`

Особенности:

- copy может требовать polling по `Location`
- root адресуется через `resourceId: 'root'`

## 11. Локализация

Локализация вынесена в `lib/l10n/cloud_sync/*`.

Текущие namespaces:

- `cloud_sync_app_credentials`
- `cloud_sync_auth`
- `cloud_sync_auth_tokens`
- `cloud_sync_storage`

Сгенерированные файлы:

- `lib/generated/l10n/translations.g.dart`
- `lib/generated/l10n/translations_ru.g.dart`
- `lib/generated/l10n/translations_en.g.dart`

Важно:

- используемый генератор это `slang`
- после изменения `.arb` нужно перегенерировать переводы
- в проекте принят `snake_case` стиль ключей

## 12. Хранилище и persistence

### App credentials

- builtin: из `.env`
- custom: Hive

### Auth tokens

- Hive
- JSON-модель через `freezed` + `json_serializable`

### Generated code

В модуле активно используются:

- `freezed`
- `json_serializable`
- `slang`

После изменения моделей и `.arb` нужно поддерживать generated файлы в актуальном состоянии.

## 13. Как добавить нового провайдера

Минимальный порядок:

1. Добавить enum case в `CloudSyncProvider`.
2. Заполнить metadata:
   - auth endpoints
   - scopes
   - redirect policy
   - userinfo config
   - auth scheme override при необходимости
3. Добавить capability rules:
   - desktop/mobile auth
   - manual code auth
   - mobile manual-only
4. Добавить builtin credential при необходимости.
5. Расширить auth service, если нужна специальная мобильная стратегия.
6. Добавить storage provider implementation.
7. Подключить provider в `CloudStorageProviderFactory`.
8. Обновить UI-полигон, если есть provider-specific особенности.
9. Добавить/обновить локализацию.
10. Прогнать генерацию `freezed/json/slang`.

## 14. Как добавить новый storage operation

Если операция должна быть общей для всех облаков:

1. Расширить `CloudStorageProvider`.
2. Добавить типы в `storage/models`, если нужен новый результат.
3. Реализовать метод во всех runtime providers.
4. При необходимости расширить `CloudStorageRepository`.
5. Только после этого подключать операцию в UI.

Если операция provider-specific:

- не ломать общий контракт
- либо сделать optional service поверх конкретного provider
- либо ввести capability layer отдельно

## 15. Что важно не сломать

- не переносить новую логику обратно в `lib/features/old/cloud_sync`
- не хардкодить access tokens в UI
- не обходить `auth_tokens` и `http` прямыми `Dio` вызовами из storage/UI
- не смешивать provider-specific адресацию с общим контрактом без `CloudResourceRef`
- не прятать platform restrictions в UI только визуально, capability должна жить и в сервисном слое

## 16. Известные ограничения

- mobile Google по-прежнему очень чувствителен к Android/iOS OAuth config
- некоторые provider errors на mobile могут маскироваться под cancellation в SDK плагинов
- storage screen это полигон, а не финальный production UX
- нет фоновой синхронизации, кеша дерева и offline mode
- нет унифицированного capability layer для provider-specific дополнительных операций

## 17. Рекомендуемая точка входа для разработчика

Если нужно понять модуль быстро:

1. Начать с `common/models/cloud_sync_provider.dart`
2. Потом посмотреть:
   - `app_credentials/models/app_credential_entry.dart`
   - `auth_tokens/models/auth_token_entry.dart`
3. Затем пройти flow:
   - `auth/providers/auth_flow_provider.dart`
   - `auth/services/cloud_sync_auth_service.dart`
4. После этого:
   - `http/services/cloud_sync_http_client.dart`
   - `storage/services/cloud_storage_provider.dart`
   - нужный provider implementation
5. Для ручной проверки использовать:
   - `screens/cloud_sync_playground_screen.dart`
   - `screens/cloud_sync_storage_screen.dart`

## 18. Связанные документы

- [cloud-sync-auth.md](./cloud-sync-auth.md)
- [cloud-sync-http.md](./cloud-sync-http.md)
- [cloud-sync-storage.md](./cloud-sync-storage.md)
