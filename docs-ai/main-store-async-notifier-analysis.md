# MainStoreAsyncNotifier: связи, сервисы и матрица зависимостей

Документ описывает `MainStoreAsyncNotifier` из
`lib/db_core/provider/main_store_provider.dart`:

- какие зависимости он инжектит;
- какие внешние сервисы использует напрямую и через контроллеры;
- какие связи задействованы в каждом методе;
- где у него внутренние (внутриклассовые) связи между методами.

## 1. Роль MainStoreAsyncNotifier

`MainStoreAsyncNotifier` — orchestration-слой сессии хранилища:

- держит `DatabaseState` и управляет переходами статусов
  (`idle/open/loading/closingSync/error/...`);
- сериализует критичные операции через lock (`_operationLock`);
- делегирует специализированную логику контроллерам (`backup`, `storage`,
  `close-sync`);
- делегирует lifecycle БД в `MainStoreManager` через `MainStoreRuntime`.

Он не реализует низкоуровневую работу с файлами/БД/сетью сам, а координирует её.

## 2. Прямые зависимости (поля класса)

## 2.1 Инициализируются в build()

- `MainStoreRuntime _runtime`
  - из `mainStoreRuntimeProvider.future`.
  - содержит:
    - `MainStoreManager manager`
    - `MainStoreBackupService backupService`
    - `MainStoreMaintenanceService maintenanceService`
- `MainStoreBackupController _backupController`
  - из `mainStoreBackupControllerProvider`.
- `MainStoreStorageController _storageController`
  - из `mainStoreStorageControllerProvider`.
- `MainStoreCloseSyncController _closeSyncController`
  - из `mainStoreCloseSyncControllerProvider`.

## 2.2 Локальные механизмы сессии

- `Timer? _errorResetTimer`
  - авто-сброс `DatabaseStatus.error -> idle`.
- `Completer<void>? _operationLock`
  - сериализация конкурентных операций (`create/open/close/...`).
- `Ref get _ref => ref`
  - алиас для чтения провайдеров в методах.

## 2.3 Сессионный bridge

- `MainStoreSessionBridge get _sessionBridge`
  - адаптер с callbacks:
    - `readState`
    - `setState`
    - `setErrorState`
  - используется контроллерами (`storage`, `close-sync`) для безопасной работы с
    состоянием нотифаера без прямого доступа к его полям.

## 3. Внешние provider-связи вокруг нотифаера

В этом же файле определены смежные провайдеры:

- `mainStoreProvider`:
  `AsyncNotifierProvider<MainStoreAsyncNotifier, DatabaseState>`
  - главный entrypoint.
- `mainStoreOpeningOverlayProvider`
  - UI-overlay во время открытия/миграции стора.
- `mainStoreStateProvider`
  - `FutureProvider`, читает итоговое состояние из `mainStoreProvider.future`.
- `mainStoreManagerProvider`
  - отдаёт `MainStoreManager?`, если store реально открыт.
  - зависит от `mainStoreProvider.future` + `mainStoreRuntimeProvider.future`.
- `dataUpdateStreamProvider`
  - при открытом store отдаёт `currentStore.watchDataChanged().skip(1)`.

Связанный sync-модуль (`current_store_sync_provider.dart`) дергает методы
нотифаера:

- `markSnapshotUploadOnCloseRequired()`
- `syncPendingSnapshotUploadPrompt(...)`
- `lockStore(skipSnapshotSync: true)`

UI close-store flow дергает:

- `resolveCloseStoreUploadDecision(bool)`.

## 4. Карта сервисов, которые реально используются MainStoreAsyncNotifier

## 4.1 Через \_runtime.manager (MainStoreManager)

- `createStore(dto)`
- `openStore(dto, allowMigration?)`
- `closeStore()`
- `updateStore(dto)`
- `getStoreInfo()` (косвенно, через close-sync controller)
- `resolveStoragePath(path)`
- свойства:
  - `currentStorePath`
  - `currentStore`
  - `isStoreOpen`

## 4.2 Через \_runtime.backupService

- `createBackup(...)` (прямо в `backupAndMigrateStore`, и косвенно в
  `MainStoreBackupController`).

## 4.3 Через \_runtime.maintenanceService

- cleanup decrypted attachments
- пути вложений/подпапки
- startup cleanup

(на уровне нотифаера чаще вызывается через `MainStoreStorageController`, а не
напрямую).

## 4.4 Через MainStoreBackupController

- one-shot backup
- periodic backup timer orchestration

## 4.5 Через MainStoreStorageController

- delete store / delete from disk
- attachments/decrypted paths
- create subfolder
- startup cleanup
- cleanup decrypted attachments on close/lock

## 4.6 Через MainStoreCloseSyncController

- pre-close snapshot sync
- build/format close-sync errors
- разрешение «можно ли закрыть без sync при recoverable network error»
- prompt-решение по upload при close
- tracking changed-state между open/close

## 4.7 Через StoreManifestService (напрямую)

- `StoreManifestService.readFrom(actualStoragePath)` в `backupAndMigrateStore()`
  - нужно, чтобы выбрать корректное имя стора для pre-migration backup.

## 4.8 Через close-store sync status provider (напрямую)

- `closeStoreSyncStatusProvider.notifier`
  - `clear()` в `closeStore()/lockStore()` и в error-ветках.

## 5. Внутренние связи методов (call graph)

## 5.1 Базовые служебные связи

- `_setErrorState(...) -> _cancelErrorResetTimer() -> _setState(...) -> _scheduleErrorReset()`
- `_scheduleErrorReset()` через `Timer` при активной ошибке переводит в `idle`.
- `_acquireLock()`/`_releaseLock()` оборачивают долгие lifecycle-операции.

## 5.2 Open/Create flow

- `createStore()`
  - использует `_acquireLock`, `_setState`, `_setErrorState`,
    `_runStartupCleanup`.
- `openStore()`
  - использует `_acquireLock`, `_handleOpenStoreSuccess`,
    `_handleOpenStoreFailure`, `_buildOpenFailureState`.
- `backupAndMigrateStore()`
  - использует `_acquireLock`, `_handleOpenStoreSuccess`,
    `_handleOpenStoreFailure`, `_buildOpenFailureState`.

## 5.3 Close/Lock flow

- `closeStore()`
  - использует `_tryUploadSnapshotBeforeClose`,
    `_shouldAllowCloseWithoutSyncFailure`, `_buildCloseSyncFailure`,
    `_setState`.
- `lockStore()`
  - использует `_tryUploadSnapshotBeforeClose` (если
    `skipSnapshotSync == false`).

## 5.4 Доп. wrappers над close-sync controller

- `_buildCloseSyncFailure`, `_formatCloseSyncFailureMessage`,
  `_shouldAllowCloseWithoutSyncFailure`, `_promptCloseStoreUploadDecision`
  - это adapter-обёртки над `_closeSyncController`.
  - В текущем файле `_formatCloseSyncFailureMessage` и
    `_promptCloseStoreUploadDecision` не вызываются самим нотифаером (но
    доступны как внутренняя прослойка).

## 6. Матрица зависимостей по каждому публичному методу

Ниже: что именно методу нужно, какие связи он использует, и зачем.

### build()

- Зависимости:
  - `mainStoreRuntimeProvider.future`
  - `mainStoreBackupControllerProvider`
  - `mainStoreStorageControllerProvider`
  - `mainStoreCloseSyncControllerProvider`
  - `ref.onDispose`
- Назначение:
  - wiring всех контроллеров и runtime;
  - установка dispose-hook для `_errorResetTimer`.

### createBackup(...)

- Зависимости:
  - `_backupController.createBackup(...)`
  - `_currentState`, `_runtime`
- Назначение:
  - делегирует backup-операцию в backup-controller.

### startPeriodicBackup(...)

- Зависимости:
  - `_backupController.startPeriodicBackup(...)`
  - callbacks `readState`, `readRuntime`
- Назначение:
  - запускает периодический backup-timer.

### stopPeriodicBackup()

- Зависимости:
  - `_backupController.stopPeriodicBackup(...)`
- Назначение:
  - останавливает периодический backup.

### isPeriodicBackupActive

- Зависимости:
  - `_backupController.isPeriodicBackupActive`
- Назначение:
  - expose текущего состояния periodic backup.

### createStore(CreateStoreDto dto)

- Зависимости:
  - `_acquireLock/_releaseLock`
  - `_runtime.manager.createStore(dto)`
  - `_setState`, `_setErrorState`
  - `_closeSyncController.startTracking(forceUpload: true)`
  - `_runStartupCleanup()`
- Назначение:
  - создать store, перевести state в `open`, запустить tracking и cleanup.

### openStore(OpenStoreDto dto)

- Зависимости:
  - `mainStoreOpeningOverlayProvider.notifier.show/hide`
  - `_acquireLock/_releaseLock`
  - `_runtime.manager.openStore(dto)`
  - `_handleOpenStoreSuccess/_handleOpenStoreFailure`
  - `_buildOpenFailureState`
- Назначение:
  - открыть существующий store + обновить состояние/ошибки.

### backupAndMigrateStore(OpenStoreDto dto, ...)

- Зависимости:
  - `mainStoreOpeningOverlayProvider.notifier.show/hide`
  - `_acquireLock/_releaseLock`
  - `_runtime.manager.resolveStoragePath(dto.path)`
  - `StoreManifestService.readFrom(...)`
  - `_runtime.backupService.createBackup(...)`
  - `_runtime.maintenanceService.getAttachmentsPath(...)`
  - `_runtime.manager.openStore(dto, allowMigration: true)`
  - `_handleOpenStoreSuccess/_handleOpenStoreFailure`
  - `_buildOpenFailureState`
- Назначение:
  - сделать backup до миграции и только потом открыть store с migration-флагом.

### closeStore()

- Зависимости:
  - `_acquireLock/_releaseLock`
  - `closeStoreSyncStatusProvider.notifier.clear()`
  - `_storageController.getDecryptedAttachmentsPath(...)`
  - `_tryUploadSnapshotBeforeClose(...)`
  - `_shouldAllowCloseWithoutSyncFailure(...)`
  - `_buildCloseSyncFailure(...)`
  - `_runtime.manager.closeStore()`
  - `_storageController.cleanupDecryptedAttachments(...)`
  - `_closeSyncController.resetTracking()`
  - `_setState(...)`
- Назначение:
  - безопасно закрыть store с pre-close cloud sync и cleanup decrypted data.

### lockStore({bool skipSnapshotSync = false})

- Зависимости:
  - `closeStoreSyncStatusProvider.notifier.clear()`
  - `_storageController.getDecryptedAttachmentsPath(...)`
  - `_tryUploadSnapshotBeforeClose()` (опционально)
  - `_runtime.manager.closeStore()`
  - `_storageController.cleanupDecryptedAttachments(...)`
  - `_closeSyncController.resetTracking()`
  - `_setState(...)`
- Назначение:
  - закрыть текущий store и перейти в `locked`, сохранив path/name.

### resetState()

- Зависимости:
  - `_setState(...)`
- Назначение:
  - явный перевод в `idle`.

### unlockStore(String password)

- Зависимости:
  - `_runtime.manager.closeStore()`
  - `_runtime.manager.openStore(OpenStoreDto(...))`
  - `_setState(...)`
  - `_closeSyncController.startTracking(...)`
  - `_runStartupCleanup()`
- Назначение:
  - re-open locked store с новым password input.

### updateStore(UpdateStoreDto dto)

- Зависимости:
  - `_runtime.manager.updateStore(dto)`
  - `_setState/_setErrorState`
- Назначение:
  - обновление metadata стора (имя/описание/пароль и пр.) и state refresh.

### deleteStore(String path, {bool deleteFromDisk = true})

- Зависимости:
  - `_runtime.manager.currentStorePath`
  - `_runtime.manager.isStoreOpen`
  - `_storageController.deleteStore(...)`
  - `_sessionBridge`
  - `_closeSyncController.resetTracking()`
- Назначение:
  - удалить store логически (+ опционально с диска), делегируя
    storage-controller.

### deleteStoreFromDisk(String path)

- Зависимости:
  - `_runtime.manager.currentStorePath`
  - `_runtime.manager.isStoreOpen`
  - `_storageController.deleteStoreFromDisk(...)`
  - `_sessionBridge`
  - `_closeSyncController.resetTracking()`
- Назначение:
  - удалить store физически с диска + историю.

### getAttachmentsPath()

- Зависимости:
  - `_storageController.getAttachmentsPath(...)`
- Назначение:
  - получить путь к encrypted attachments текущего store.

### getDecryptedAttachmentsPath()

- Зависимости:
  - `_storageController.getDecryptedAttachmentsPath(...)`
- Назначение:
  - получить путь к decrypted attachments.

### createSubfolder(String folderName)

- Зависимости:
  - `_storageController.createSubfolder(...)`
- Назначение:
  - создать подпапку внутри storage.

### clearError()

- Зависимости:
  - `_cancelErrorResetTimer()`
  - `_setState(_currentState.copyWith(error: null))`
- Назначение:
  - ручная очистка ошибки без полного reset state.

### resolveCloseStoreUploadDecision(bool shouldUpload)

- Зависимости:
  - `_closeSyncController.resolveCloseStoreUploadDecision(...)`
- Назначение:
  - передать решение пользователя в pending close-sync prompt.

### markSnapshotUploadOnCloseRequired()

- Зависимости:
  - `_closeSyncController.markSnapshotUploadOnCloseRequired()`
- Назначение:
  - принудительно пометить необходимость upload при close.

### syncPendingSnapshotUploadPrompt(...)

- Зависимости:
  - `_runtime.manager.currentStorePath`
  - `_closeSyncController.syncPendingSnapshotUploadPrompt(...)`
- Назначение:
  - синхронизировать флаг необходимости close-upload prompt из external
    sync-status.

### currentMainStoreManager (getter)

- Зависимости:
  - `_runtime.manager`
- Назначение:
  - отдать ссылку на manager (nullable API на уровне getter).

### currentDatabase (getter)

- Зависимости:
  - `_runtime.manager.currentStore`
  - `logError(...)`
  - `DatabaseError.unknown(...)`
- Назначение:
  - гарантированный доступ к открытому `MainStore` или исключение.

## 7. Матрица приватных методов и их зависимостей

### \_currentState (getter)

- Зависимости: `state.value`, fallback `DatabaseState(idle)`.
- Нужен для: безопасного чтения текущего state в контроллерах и публичных
  методах.

### \_sessionBridge (getter)

- Зависимости: `_currentState`, `_setState`, `_setErrorState`.
- Нужен для: унифицированной передачи контракта сессии в контроллеры.

### \_setState(DatabaseState)

- Зависимости: `state = AsyncValue.data(...)`.
- Нужен для: централизованной записи состояния.

### \_setErrorState(DatabaseState)

- Зависимости: `_cancelErrorResetTimer`, `_setState`, `_scheduleErrorReset`.
- Нужен для: постановки error-state с автоматическим reset через таймер.

### \_scheduleErrorReset()

- Зависимости: `Timer`, `_currentState`, `logInfo`, `_setState`.
- Нужен для: авто-восстановления в `idle`, если ошибка не была очищена вручную.

### \_cancelErrorResetTimer()

- Зависимости: `_errorResetTimer?.cancel()`.
- Нужен для: отмены предыдущих reset-сценариев ошибки.

### \_acquireLock()

- Зависимости: `_operationLock`, `Completer<void>`, `logInfo`.
- Нужен для: последовательного исполнения долгих операций.

### \_releaseLock()

- Зависимости: `_operationLock?.complete()`, null-reset.
- Нужен для: снятия сериализации операций.

### \_handleOpenStoreSuccess(StoreInfoDto)

- Зависимости:
  - `_setState(...)`
  - `_runtime.manager.currentStorePath`
  - `_closeSyncController.startTracking(...)`
  - `_runStartupCleanup()`
- Нужен для: единая success-ветка для `openStore` и `backupAndMigrateStore`.

### \_handleOpenStoreFailure(DatabaseError)

- Зависимости:
  - `_buildOpenFailureState(...)`
  - `_setErrorState(...)`
  - `logError(...)`
- Нужен для: единая failure-ветка открытия.

### \_buildOpenFailureState(DatabaseError)

- Зависимости:
  - `_runtime.manager.isStoreOpen`
  - `_currentState`
- Нужен для: корректный выбор target-status (`open` vs `error`).

### \_runStartupCleanup()

- Зависимости:
  - `_storageController.runStartupCleanup(...)`
- Нужен для: post-open housekeeping.

### \_tryUploadSnapshotBeforeClose(...)

- Зависимости:
  - `_closeSyncController.tryUploadSnapshotBeforeClose(...)`
  - `_runtime`, `_sessionBridge`
- Нужен для: pre-close cloud sync orchestration.

### \_buildCloseSyncFailure(Object, stackTrace)

- Зависимости:
  - `_closeSyncController.buildCloseSyncFailure(...)`
- Нужен для: единый DatabaseError при fail pre-close sync.

### \_formatCloseSyncFailureMessage(Object)

- Зависимости:
  - `_closeSyncController.formatCloseSyncFailureMessage(...)`
- Нужен для: map error -> user-friendly message (сейчас в нотифаере напрямую не
  используется).

### \_shouldAllowCloseWithoutSyncFailure(Object)

- Зависимости:
  - `_closeSyncController.shouldAllowCloseWithoutSyncFailure(...)`
- Нужен для: fallback-ветки «закрыть локально без upload» в auto-upload режиме.

### \_promptCloseStoreUploadDecision(StoreSyncStatus, ...)

- Зависимости:
  - `_closeSyncController.promptCloseStoreUploadDecision(...)`
- Нужен для: prompt-потока по решению пользователя (сейчас напрямую не
  вызывается из этого файла).

## 8. Внешние вызовы MainStoreAsyncNotifier (основные точки)

Основные модули, которые используют публичный API нотифаера:

- lifecycle watchers:
  - `lib/shared/widgets/watchers/lifecycle/app_lifecycle_provider.dart`
  - `lib/shared/widgets/watchers/lifecycle/auto_lock_provider.dart`
- UI закрытия/блокировки:
  - `lib/shared/widgets/close_database_button.dart`
  - `lib/shared/widgets/titlebar.dart`
  - `lib/features/password_manager/close_store/close_store_sync_screen.dart`
  - `lib/features/password_manager/lock_store/lock_store_screen.dart`
- открытие/создание:
  - `lib/features/password_manager/create_store/create_store_screen.dart`
  - `lib/features/password_manager/open_store/providers/open_store_form_provider.dart`
  - `lib/features/home/home_screen.dart`
  - `lib/features/home/widgets/recent_database_card.dart`
- backup/settings:
  - `lib/features/settings/ui/settings_sections.dart`
  - `lib/features/password_manager/dashboard/widgets/dashboard_home/dashboard_drawer/dashboard_drawer.dart`
- cloud sync integration:
  - `lib/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart`
  - `lib/features/cloud_sync/snapshot_sync/widgets/cloud_sync_snapshot_sync_listener.dart`

## 9. Короткий итог по связности

`MainStoreAsyncNotifier` — coordinator/facade:

- lifecycle и бизнес-решения о state transition живут здесь;
- filesystem/backup/close-sync вынесены в отдельные контроллеры;
- доступ к БД lifecycle — через `MainStoreManager` внутри `MainStoreRuntime`;
- sync-поведение на close изолировано в `MainStoreCloseSyncController` и связано
  с cloud providers через отдельный слой.

Такое разделение делает нотифаер центральной точкой оркестрации, но без смешения
низкоуровневых реализаций в одном классе.

## 10. Методы, использующие одинаковые сервисы (быстрые пометки)

Ниже группировка вида: сервис/зависимость -> какие методы MainStoreAsyncNotifier
её используют.

MainStoreBackupService (через \_runtime.backupService):

- backupAndMigrateStore

MainStoreBackupController:

- createBackup
- startPeriodicBackup
- stopPeriodicBackup
- isPeriodicBackupActive

MainStoreManager (через \_runtime.manager):

- createStore
- openStore
- backupAndMigrateStore
- closeStore
- lockStore
- unlockStore
- updateStore
- deleteStore
- deleteStoreFromDisk
- syncPendingSnapshotUploadPrompt
- currentDatabase
- currentMainStoreManager

MainStoreStorageController:

- closeStore
- lockStore
- deleteStore
- deleteStoreFromDisk
- getAttachmentsPath
- getDecryptedAttachmentsPath
- createSubfolder
- \_runStartupCleanup

MainStoreCloseSyncController:

- createStore
- closeStore
- lockStore
- unlockStore
- deleteStore
- deleteStoreFromDisk
- resolveCloseStoreUploadDecision
- markSnapshotUploadOnCloseRequired
- syncPendingSnapshotUploadPrompt
- \_tryUploadSnapshotBeforeClose
- \_buildCloseSyncFailure
- \_formatCloseSyncFailureMessage
- \_shouldAllowCloseWithoutSyncFailure
- \_promptCloseStoreUploadDecision

StoreManifestService:

- backupAndMigrateStore

mainStoreOpeningOverlayProvider:

- openStore
- backupAndMigrateStore

closeStoreSyncStatusProvider:

- closeStore
- lockStore
