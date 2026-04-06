# `current_store_sync_provider.dart`

Документ описывает, за что отвечает `currentStoreSyncProvider`, какие публичные сценарии он покрывает и что именно выполняется под капотом на каждом этапе.

## Назначение

`currentStoreSyncProvider` это основной Riverpod-слой для snapshot sync текущего открытого хранилища.

Он решает четыре задачи:

1. Строит `StoreSyncStatus` для текущего store.
2. Координирует connect / disconnect / sync / resolve conflict.
3. Преобразует stream прогресса из `SnapshotSyncService` в UI-состояние.
4. Поднимает app-level сигнал, если cloud sync больше не может работать с текущим токеном.

Итоговый источник истины для UI:

- подключена ли sync;
- какой token/binding используется;
- совпадают ли локальная и облачная версии;
- есть ли conflict;
- идёт ли sync сейчас;
- нужен ли manual reauth.

---

## Основные сущности

### `currentStoreSyncProvider`

```dart
final currentStoreSyncProvider =
    AsyncNotifierProvider<CurrentStoreSyncNotifier, StoreSyncStatus>(
      CurrentStoreSyncNotifier.new,
    );
```

Возвращает `AsyncValue<StoreSyncStatus>`.

### `currentStoreSyncManualReauthIssueProvider`

Отдельный глобальный сигнал для UI верхнего уровня.

Используется, когда:

- token протух и refresh не удался;
- cloud provider вернул `unauthorized`;
- у store есть binding, но token с этим `tokenId` больше не найден локально.

UI верхнего уровня может подписаться на этот provider и показать диалог ручной переавторизации.

### `StoreSyncStatus`

Главная модель состояния sync для конкретного store.

Содержит:

- сведения о store: `isStoreOpen`, `storePath`, `storeUuid`, `storeName`;
- сведения о sync binding: `binding`, `token`;
- manifest state: `localManifest`, `remoteManifest`;
- compare result: `compareResult`;
- conflict state: `pendingConflict`;
- результат последней операции: `lastResultType`;
- спец-флаги download/apply: `requiresUnlockToApply`, `isApplyingRemoteUpdate`;
- offline flag: `remoteCheckSkippedOffline`;
- live progress: `syncProgress`, `isSyncInProgress`.

---

## Зависимости под капотом

`CurrentStoreSyncNotifier` опирается на несколько других слоёв:

- `mainStoreProvider`
  Даёт текущее состояние хранилища: открыто оно или нет, путь и имя.
- `mainStoreManagerProvider`
  Даёт доступ к `StoreInfoDto` и операциям над открытым store.
- `snapshotSyncServiceProvider`
  Выполняет основную sync-логику: build snapshot, compare, upload, download, resolve conflict.
- `storeSyncBindingServiceProvider`
  Читает и пишет binding `storeUuid -> tokenId/provider`.
- `authTokensProvider`
  Даёт доступ к сохранённым OAuth tokens.
- `internetConnectionProvider`
  Используется для soft-skip remote check, когда store открыт и нет интернета.

---

## Жизненный цикл `build()`

### Что делает `build()`

`build()` вызывается при первом чтении `currentStoreSyncProvider`.

Под капотом:

1. Ждёт `mainStoreProvider.future`.
2. Получает текущее состояние БД.
3. Вызывает `_loadCurrentStatus(storeState, useWatch: true)`.
4. Возвращает собранный `StoreSyncStatus`.

### Почему `useWatch: true`

При `build()` провайдер подписывается на зависимости реактивно.

Это важно, чтобы при изменении store state или manager провайдер мог быть перестроен автоматически.

---

## Этапы `_loadCurrentStatus(...)`

Это главный метод чтения статуса sync.

### Шаг 1. Проверка, открыто ли хранилище

Если `storeState.isOpen == false`, метод сразу возвращает:

- `isStoreOpen: false`
- `storePath`
- `storeName`

Никаких remote операций в этом случае не выполняется.

### Шаг 2. Получение `MainStoreManager`

Если store открыт, берётся `mainStoreManagerProvider`.

Если manager недоступен, возвращается безопасный fallback:

- `StoreSyncStatus(isStoreOpen: false)`

### Шаг 3. Чтение `StoreInfoDto`

Через `manager.getStoreInfo()` читается:

- UUID store;
- имя store;
- другая метаинформация, нужная для manifest builder.

Если `getStoreInfo()` вернул ошибку, она пробрасывается наружу.

### Шаг 4. Чтение binding

Через `storeSyncBindingServiceProvider` читается binding по `storeInfo.id`.

Binding содержит:

- `storeUuid`
- `tokenId`
- `provider`

### Шаг 5. Попытка загрузить token

Если binding найден, провайдер пытается загрузить token через:

```dart
_loadToken(binding.tokenId)
```

### Шаг 6. Обработка stale binding

Если binding есть, а token уже отсутствует:

1. Вызывается `_reportMissingTokenBindingIssue(...)`.
2. Binding удаляется через `deleteBinding(storeInfo.id)`.
3. Локально `binding = null`.

Это защищает систему от состояния "sync якобы настроен, но реального токена уже нет".

### Шаг 7. Решение, делать ли remote check

Если одновременно верны условия:

- `useWatch == true`
- binding есть
- token есть
- интернет недоступен

то провайдер выставляет `skipRemoteCheck = true`.

Это означает:

- локальный snapshot всё равно будет построен;
- remote manifest не будет запрошен;
- статус будет собран без сети и с флагом `remoteCheckSkippedOffline: true`.

### Шаг 8. Делегирование в `SnapshotSyncService.loadStatus(...)`

В сервис передаются:

- `storePath`
- `storeInfo`
- `binding`
- `token`
- `skipRemoteManifestCheck`
- `remoteCheckSkippedOffline`

Дальше сервис:

1. строит локальный snapshot;
2. при необходимости читает remote manifest;
3. сравнивает local/remote;
4. возвращает готовый `StoreSyncStatus`.

### Шаг 9. Обработка unauthorized

Если во время чтения статуса произошла ошибка авторизации:

1. `_reportManualReauthIfNeeded(...)` формирует `CurrentStoreSyncManualReauthIssue`;
2. issue публикуется в `currentStoreSyncManualReauthIssueProvider`;
3. ошибка пробрасывается дальше.

---

## `loadStatus()`

Принудительно перечитывает текущий статус sync.

### Что делает

1. Сохраняет предыдущее успешное значение `state.value`.
2. Временно ставит `state = AsyncLoading()`.
3. Читает текущее состояние store.
4. Повторно вызывает `_loadCurrentStatus(..., useWatch: false)`.
5. На успехе публикует `AsyncData(next)`.

### Что делает при ошибке

Если ошибка произошла:

- при наличии старого `StoreSyncStatus` откатывается к предыдущему `AsyncData(previous)`;
- если предыдущего значения не было, публикует `AsyncError`.

Если `rethrowOnError == true`, ошибка дополнительно пробрасывается выше.

---

## `connect(tokenId)`

Подключает текущий store к cloud sync через указанный token.

### Этапы

1. Берёт текущее значение `await future`.
2. Проверяет, что у store есть `storeUuid`.
3. Загружает token по `tokenId`.
4. Сохраняет binding `storeUuid -> tokenId/provider`.
5. Читает сохранённый binding обратно из binding service.
6. Вызывает `snapshotSyncService.initializeRemoteLayout(...)`.
7. Делает `loadStatus(rethrowOnError: true)`.

### Что именно делает `initializeRemoteLayout`

Под капотом репозиторий гарантирует, что в облаке существует layout store:

- папка store;
- служебные папки;
- manifest-файлы и ожидаемая структура.

### Rollback-логика при ошибке

Если после сохранения binding произошла ошибка:

- если ошибка `network` или `timeout`, binding можно сохранить;
- в этом случае UI получает состояние "binding уже есть, но remote manifest пока не прочитан";
- если ошибка другая, провайдер восстанавливает старый binding либо удаляет новый.

### Дополнительная обработка reauth

Если ошибка выглядит как `unauthorized`, публикуется `CurrentStoreSyncManualReauthIssue`.

---

## `disconnect()`

Отключает cloud sync от текущего store.

### Этапы

1. Берёт текущее состояние.
2. Если `storeUuid == null`, просто выходит.
3. Удаляет binding из `storeSyncBindingService`.
4. Мгновенно очищает локальный state:
   - binding
   - token
   - remote manifest
   - pending conflict
5. Запускает `loadStatus()`, чтобы привести итоговое состояние к реальному источнику истины.

---

## `syncNow()`

Запускает обычную sync-операцию для текущего store.

### Предусловия

Должны существовать:

- `binding`
- `token`
- `storePath`
- `MainStoreManager`

Иначе выбрасывается `StateError`.

### Ветка 1. Уже известен conflict

Если `compareResult == conflict`, провайдер не пытается сразу upload/download.

Вместо этого:

1. формирует `pendingConflict`, если он ещё не собран;
2. пишет `lastResultType = conflict`;
3. завершает метод.

Это даёт UI возможность показать диалог выбора:

- upload local
- download remote

### Ветка 2. `remoteNewer`

Если облачная версия новее:

1. строится промежуточный state `downloadInProgressState`;
2. store помечается как закрытый для применения download:
   - `isStoreOpen: false`
   - `isApplyingRemoteUpdate: true`
   - `isSyncInProgress: true`
   - `syncProgress = _initialDownloadProgress()`
3. вызывается `lockStore(skipSnapshotSync: true)`;
4. затем запускается `resolveConflictWithProgress(... downloadRemote ...)`;
5. stream прогресса прокачивается в state;
6. после успеха строится `StoreSyncStatus` через `_buildLockedDownloadedStatus(...)`.

Итог этого сценария:

- snapshot уже скачан и применён локально;
- store остаётся закрыт;
- `requiresUnlockToApply: true`

UI может показать экран "remote snapshot применён, разблокируйте store заново".

### Ветка 3. Обычный sync

Если special-case download не нужен:

1. создаётся `baseState` без progress и без pending conflict;
2. запускается `snapshotSyncService.syncWithProgress(...)`;
3. `CurrentStoreSyncNotifier` слушает stream и обновляет `syncProgress`;
4. когда приходит terminal result:
   - если это `conflict`, состояние фиксируется как conflict;
   - иначе вызывается `_reloadStatusWithoutLoading(...)`.

### Что делает `_reloadStatusWithoutLoading`

1. перечитывает store state из `mainStoreProvider`;
2. заново вызывает `_loadCurrentStatus(...)`;
3. принудительно очищает transient поля:
   - `syncProgress`
   - `isSyncInProgress`
   - `isApplyingRemoteUpdate`
4. записывает `lastResultType`.

---

## `syncBeforeClose(...)`

Специальный sync-путь, используемый перед закрытием store.

### Зачем нужен отдельный метод

Чтобы экран "закрываем и синхронизируем" мог получать подробный progress, не дожидаясь полного `loadStatus()`.

### Этапы

1. Формирует `baseState` на основе уже известного `StoreSyncStatus`.
2. Публикует его в `state`.
3. Запускает `snapshotSyncService.syncWithProgress(...)`.
4. Через `_runProgressStream(...)` прокидывает progress в UI.
5. После завершения пишет:
   - `localManifest`
   - `remoteManifest`
   - `lastResultType`
   - очищает progress-флаги

Метод возвращает `SnapshotSyncResult`, чтобы вызывающий код мог решить, как завершать close flow.

---

## Resolve conflict

Есть две публичные точки:

- `resolveConflictWithUpload()`
- `resolveConflictWithDownload()`

Обе вызывают внутренний `_resolveConflict(resolution)`.

### Общий сценарий `_resolveConflict(...)`

1. Проверяет `binding`, `token`, `storePath`.
2. Получает `StoreInfoDto` через manager.
3. Вычисляет `requiresUnlock`.

`requiresUnlock == true` только для `downloadRemote`.

### Если выбран `downloadRemote`

1. Публикуется промежуточный progress state.
2. Вызывается `lockStore(skipSnapshotSync: true)`.
3. Запускается `snapshotSyncService.resolveConflictWithProgress(...)`.
4. После успеха строится locked status через `_buildLockedDownloadedStatus(...)`.

### Если выбран `uploadLocal`

1. Store не блокируется.
2. Запускается stream-based upload pipeline.
3. После успеха статус перечитывается через `_reloadStatusWithoutLoading(...)`.

---

## Как работает progress pipeline

### `SnapshotSyncService` возвращает stream

Сервис отдаёт:

- `SnapshotSyncProgressUpdate`
- `SnapshotSyncProgressResult`

### Что делает `_consumeProgressStream(...)`

На каждом `SnapshotSyncProgressUpdate` провайдер пишет:

- `syncProgress = event.progress`
- `isSyncInProgress = true`

Когда приходит `SnapshotSyncProgressResult`, он запоминается как terminal result.

Если stream завершился без terminal result, выбрасывается `StateError`.

### Что делает `_runProgressStream(...)`

Это обёртка над `_consumeProgressStream(...)`, которая ещё и обрабатывает `unauthorized`.

Если во время sync/download/upload произошла auth-ошибка:

1. вызывается `_reportManualReauthIfNeeded(...)`;
2. issue публикуется глобально;
3. ошибка пробрасывается дальше.

---

## Сигналы о проблемах с токеном

### Сценарий 1. Token отсутствует локально

Условия:

- binding найден;
- `authTokensProvider` не смог найти token по `tokenId`.

Что происходит:

1. Публикуется issue `CurrentStoreSyncIssueKind.missingToken`.
2. Stale binding удаляется.
3. Дальше статус строится уже как у store без привязки.

Это важно, потому что иначе UI мог бы считать, что sync всё ещё подключён.

### Сценарий 2. Token больше невалиден в облаке

Условия:

- `CloudStorageException.type == unauthorized`

Провайдер анализирует `error.cause`:

- `refreshFailed`
- `unauthorized`
- прочие unauthorized-причины

После этого публикуется issue `manualReauthRequired`.

### Где может всплыть manual reauth

Практически в любом публичном потоке:

- `loadStatus()`
- `connect()`
- `syncNow()`
- `syncBeforeClose()`
- `resolveConflict...()`

---

## Почему провайдер иногда выставляет `AsyncLoading()`, а иногда нет

### `loadStatus()`

Использует `AsyncLoading()`, потому что это полноценное перечитывание статуса.

### Sync-операции

Не переводят всё состояние в `AsyncLoading()`.

Вместо этого провайдер старается сохранить `AsyncData(StoreSyncStatus)` и обновлять внутри него:

- `syncProgress`
- `isSyncInProgress`

Это нужно, чтобы UI мог показывать живой прогресс, а не только глобальный спиннер.

---

## Ключевые инварианты

### 1. Binding без token не должен жить долго

Если token отсутствует локально, binding удаляется.

### 2. Любой sync progress должен быть transient

После завершения операции очищаются:

- `syncProgress`
- `isSyncInProgress`

### 3. Download remote snapshot не применяется поверх открытого store

Перед download/apply flow store блокируется через:

```dart
lockStore(skipSnapshotSync: true)
```

### 4. После успешного sync статус перечитывается заново

Провайдер не пытается вручную восстановить весь финальный state во всех сценариях.

Обычно он перечитывает реальный статус через `_loadCurrentStatus(...)`, а локально дописывает только transient-результаты вроде `lastResultType`.

---

## Краткая карта публичных методов

### `build()`

Первичная сборка статуса текущего store.

### `loadStatus()`

Принудительное перечитывание статуса sync.

### `connect(tokenId)`

Подключение store к cloud sync.

### `disconnect()`

Удаление binding и сброс статуса sync.

### `syncNow()`

Обычная sync-операция с conflict handling и progress.

### `syncBeforeClose(...)`

Sync перед закрытием store, с подробным progress.

### `resolveConflictWithUpload()`

Разрешение конфликта в пользу локальной версии.

### `resolveConflictWithDownload()`

Разрешение конфликта в пользу удалённой версии.

---

## Если нужно быстро понять файл

Минимальный порядок чтения такой:

1. `build()`
2. `_loadCurrentStatus(...)`
3. `syncNow()`
4. `_resolveConflict(...)`
5. `_runProgressStream(...)`
6. `_reportManualReauthIfNeeded(...)`

Этого достаточно, чтобы понять почти весь жизненный цикл provider-а.
