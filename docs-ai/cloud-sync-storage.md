# Cloud Sync Storage

Документация по новому слою `lib/features/cloud_sync/storage`.

## Назначение

`cloud_sync/storage` даёт единый provider-agnostic контракт для облаков поверх `cloud_sync/http`.

Он закрывает минимальный набор операций:

- получить метаданные ресурса
- получить содержимое папки
- создать папку
- загрузить файл
- скачать файл
- скопировать ресурс
- переместить ресурс
- удалить ресурс

## Архитектура

Слой разделён на три части:

1. Общие модели и интерфейс `CloudStorageProvider`
2. Factory/repository layer
3. Реализации провайдеров

Первый runtime provider сейчас только `Yandex Drive`.

## Основные типы

- `CloudResourceRef`
- `CloudResource`
- `CloudFile`
- `CloudFolder`
- `CloudListPage`
- `CloudMoveCopyTarget`
- `CloudStorageException`

## Использование

Через factory:

```dart
final factory = ref.read(cloudStorageProviderFactoryProvider);
final provider = await factory.providerForToken(tokenId);
final page = await provider.listFolder(
  const CloudResourceRef.root(
    provider: CloudSyncProvider.yandex,
    path: 'disk:/',
  ),
);
```

Через repository:

```dart
final repository = ref.read(cloudStorageRepositoryProvider);
final resource = await repository.getResource(
  tokenId,
  const CloudResourceRef(
    provider: CloudSyncProvider.yandex,
    path: 'disk:/backup/archive.zip',
  ),
);
```

## Yandex Drive

`YandexDriveCloudStorageProvider` построен только на новом `CloudSyncHttpClient`.

Используемые endpoints:

- `GET /resources`
- `PUT /resources`
- `GET /resources/upload`
- `GET /resources/download`
- `POST /resources/copy`
- `POST /resources/move`
- `DELETE /resources`
- `GET /operations/{id}`

Особенности:

- `CloudResourceRef.path` хранится как yandex path, например `disk:/folder/file.txt`
- root представляется как `disk:/`
- асинхронные операции Yandex скрыты внутри провайдера
- если API возвращает `operation_id`, провайдер сам polling-ом дожидается финального статуса

## Ограничения v1

- runtime-реализация есть только для `Yandex Drive`
- `Dropbox`, `Google Drive`, `OneDrive` пока не реализованы и через factory вернут `unsupportedOperation`
- cursor pagination для Yandex сейчас нормализована как строковый `offset`
- repository остаётся thin facade без кеша и фоновой синхронизации
