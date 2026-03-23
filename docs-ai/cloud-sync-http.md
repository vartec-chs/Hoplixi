# Cloud Sync HTTP

Документация по новому низкоуровневому модулю `lib/features/cloud_sync/http`.

## Назначение

Модуль даёт общий transport-layer для HTTP-запросов к API облаков без привязки к Dropbox, Google Drive или другому конкретному бизнес-API.

Он решает только инфраструктурные задачи:

- создание клиента по `tokenId`
- автоматическая подстановка `Authorization`
- refresh access token после `401`
- сохранение обновлённого токена обратно в `auth_tokens`
- обычные запросы, upload, download, progress и cancel
- унификация ошибок в typed exception

Модуль не знает про файловые endpoints, папки, metadata API и другие provider-specific операции.

## Структура

### Models

`lib/features/cloud_sync/http/models/`

- `CloudSyncHttpRequest`
- `CloudSyncUploadRequest`
- `CloudSyncDownloadRequest`
- `CloudSyncHttpException`

`CloudSyncHttpException` содержит:

- `type`
- `message`
- `provider`
- `tokenId`
- `statusCode`
- `requestUri`
- `responseBodySnippet`
- `cause`

Поддерживаемые типы ошибок:

- `unauthorized`
- `refreshFailed`
- `network`
- `timeout`
- `cancelled`
- `badResponse`
- `misconfiguredProvider`
- `tokenNotFound`
- `unknown`

### Services

`lib/features/cloud_sync/http/services/`

- `CloudSyncTokenResolver`
  - загружает `AuthTokenEntry` по `tokenId`
  - сохраняет обновлённый токен обратно в `AuthTokensService`
- `CloudSyncTokenRefreshService`
  - делает refresh через provider token endpoint
  - подтягивает `client_id/client_secret` из `AppCredentialsService`
  - обновляет `accessToken`, `refreshToken`, `tokenType`, `expiresAt`, `scopes`, `extraData`
- `CloudSyncHttpClient`
  - thin wrapper над `Dio`
  - поддерживает `request`, `upload`, `download`
  - использует `QueuedInterceptor` для auth/retry
- `CloudSyncHttpClientFactory`
  - создаёт готовый клиент через `clientForToken(tokenId)`

### Providers

`lib/features/cloud_sync/http/providers/cloud_sync_http_provider.dart`

Публичные Riverpod providers:

- `cloudSyncTokenResolverProvider`
- `cloudSyncTokenRefreshServiceProvider`
- `cloudSyncHttpClientFactoryProvider`

## Поведение refresh

Refresh запускается только после `401`.

Алгоритм:

1. Клиент получает `401`.
2. Interceptor проверяет, был ли уже retry после refresh.
3. Если retry уже был, запрос завершается `unauthorized`.
4. Если retry ещё не был, клиент загружает актуальный токен.
5. Если другой запрос уже успел обновить токен, текущий запрос просто ретраится с новым `Authorization`.
6. Если токен всё ещё старый, запускается refresh.
7. После успешного refresh исходный запрос повторяется ровно один раз.

Для сериализации используется `QueuedInterceptor`.

## Источники данных

### Токен

Берётся из `AuthTokensService` по `tokenId`.

### OAuth app credentials

Для refresh берутся из `AppCredentialsService` по `AuthTokenEntry.appCredentialId`.

Это нужно потому, что refresh endpoint обычно требует:

- `client_id`
- `client_secret` при наличии
- `refresh_token`

### Provider metadata

Берётся из `CloudSyncProvider.metadata`.

Сейчас используется только `tokenEndpoint`.

## Пример использования

```dart
final factory = ref.read(cloudSyncHttpClientFactoryProvider);
final client = await factory.clientForToken(tokenId);

final response = await client.request<Map<String, dynamic>>(
  const CloudSyncHttpRequest(
    method: 'GET',
    url: 'https://api.example.com/v1/profile',
  ),
);
```

Upload:

```dart
final response = await client.upload<Map<String, dynamic>>(
  CloudSyncUploadRequest(
    url: 'https://api.example.com/v1/upload',
    data: formData,
    onSendProgress: (sent, total) {},
  ),
);
```

Download в файл:

```dart
await client.download(
  CloudSyncDownloadRequest(
    url: 'https://api.example.com/v1/download/file',
    savePath: targetPath,
    onReceiveProgress: (received, total) {},
  ),
);
```

Отмена:

```dart
final cancelToken = CancelToken();

client.request<void>(
  CloudSyncHttpRequest(
    method: 'GET',
    url: 'https://api.example.com/v1/slow',
    cancelToken: cancelToken,
  ),
);

cancelToken.cancel('user cancelled');
```

## Ограничения v1

- Refresh делается только реактивно, после `401`.
- Упреждающее обновление по `expiresAt` пока не реализовано.
- В v1 вызывающий код всегда передаёт абсолютный URL.
- Модуль не содержит registry базовых API URL для провайдеров.
- Модуль не содержит provider-specific методов вроде `listFiles`, `createFolder`, `uploadFile`.
- Если у токена нет `refreshToken`, после `401` клиент вернёт `refreshFailed` или `unauthorized`.
- Для mobile Google, где refresh token может отсутствовать, специальных обходов нет.

## Что добавить дальше

Следующий слой может строиться поверх `CloudSyncHttpClient` и уже описывать provider-specific API:

- Dropbox API client
- Google Drive API client
- OneDrive API client
- Yandex Disk API client

Именно там должны появиться:

- typed DTO конкретного облака
- mapping бизнес-ошибок
- file/folder operations
- base URL registry
- pagination helpers
- provider-specific upload/download semantics
