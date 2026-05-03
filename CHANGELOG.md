# CHANGELOG

## 2026-05-03

### app

- Настроен `flutter_native_splash.yaml`: убраны несуществующие PNG-пути,
  включена splash-конфигурация для Android, iOS, Web и Android 12+.
- В splash-конфигурацию подключён логотип `assets/logo/logo.png` для обычного
  splash и Android 12+.

### note_form

- Добавлена модалка разворачивания Quill-редактора поверх текущего sidebar:
  `showGeneralDialog`, затемнение фона, scale/fade-анимация и закрытие через
  кнопку, barrier и Escape.
- Toolbar и редактор заметки вынесены в переиспользуемые builders; sidebar и
  modal используют один `QuillController`, не пересоздавая документ.
- В развёрнутый Quill modal передан общий обработчик `vault://` ссылок, чтобы
  ссылки на записи Vault работали так же, как в sidebar-редакторе.

## 2026-05-02

### home

- `HomeScreen` переведён на showcase-конфигурацию в стиле официального примера
  `showcaseview`: добавлены глобальная кнопка пропуска, общий ряд действий
  подсказок и автозапуск тура после первого кадра.
- Для `HomeScreen` добавлен custom showcase tooltip на карточке создания
  хранилища через `Showcase.withWidget`, чтобы проверить работу кастомного
  контента поверх home.

### onboarding

- Добавлена архитектура пользовательских гайдов на `showcaseview` с версиями,
  storage прогресса, Riverpod-контроллером, wrapper-виджетом и кнопкой ручного
  запуска.
- Подключены первые независимые гайды для `home`, `create-store`, `dashboard` и
  `/dashboard/passwords/add`.
- Регистрация `ShowcaseView` переведена на экранный lifecycle по официальному
  примеру пакета: экранные scope регистрируют showcase при открытии и снимают
  регистрацию при закрытии.
- Убраны showcase wrapper-виджеты; цели подсказок теперь подключаются напрямую
  через `Showcase`, а ручной запуск использует `ShowcaseView` напрямую.
- Showcase controller упрощён до хранения прогресса и проверки версий; запуск
  туров перенесён в lifecycle реальных экранов.

### shared

- Добавлен `AppActivityScope`, который отключает `TickerMode` и переводит UI в
  `Offstage`, когда приложение не видно, а также подключён к основному bootstrap
  lifecycle-обёртки.
- В `SmoothButton` цвет текста в loading-состоянии больше не жёстко привязан к
  `onPrimary`, чтобы на светлой теме он не становился белым.
- В `SmoothButton` spinner в loading-состоянии тоже переведён на нейтральный
  disabled-цвет вместо белого.
- Tray-интеграция переведена на `TrayService` с Riverpod-состоянием
  `AppActivityMode`; прямые tray callbacks из `TrayWatcher` заменены
  провайдерными вызовами сервиса.
- При переходе приложения в `AppActivityMode.tray` автоблокировка сразу вызывает
  `lockStore()` для открытого хранилища.
- При показе приложения из tray окно возвращается к
  `MainConstants.defaultWindowSize`.

### cloud_sync

- Экран `CloudSyncPlaygroundScreen` переработан в дружелюбный центр управления
  App Credentials, Auth Tokens и Drive Storage API с быстрыми действиями,
  статусами провайдеров и адаптивной раскладкой.
- Виджеты Cloud Sync Center вынесены в `cloud_sync/playground/widgets`, а
  desktop-раскладка расширена отдельной правой колонкой и grid-панелями для
  provider readiness и Drive Storage API.

### home

- `HomeScreen` разбит на отдельные виджеты для header-фона, верхних действий и
  grid-контента; описание действия Cloud Sync переименовано в пользовательский
  текст про управление облачной синхронизацией.

### docs

- В `error-handling.md` добавлено правило для `AppError.feature(...)` как
  локального варианта ошибки внутри одной-двух фич с единым путём до UI, логов,
  snackbar/dialog и сериализации.
- В `agent-architecture-map.md` и `multi-window-architecture.md` добавлен
  `loggerWithTag`/`withTag` как способ объявить сервисный tagged logger field и
  не повторять `tag:` в каждом вызове лога.
- В AI-доки добавлен конкретный пример `LaunchAtStartupService` как образец
  service-level `loggerWithTag(...)`.

### core

- В `AppError` добавлен вариант `feature` для ошибок, привязанных к конкретной
  feature и её коду.
- Исправлен запуск showcase на home: убрана преждевременная фильтрация
  `GlobalKey.currentContext`, а отсутствующие targets теперь пропускаются самим
  `showcaseview`, поэтому ручной и автоматический старт снова показывают
  подсказки.

### custom_icon_packs

- Импорт больших icon packs разгружен для UI: native импорт теперь ограничивает
  частоту progress-событий, а Riverpod state обновляется с throttling.
- `IconPackCatalogService` переведён на thin adapter поверх FRB-API в Rust:
  листинг, чтение SVG и импорт пака теперь идут через native слой.
- Импорт архивов для icon packs расширен до ZIP и 7Z через `archive`; обновлены
  файловый фильтр и тексты выбора источника.
- Исправлено зависание UI импорта на 100%: финальный процент теперь приходит
  после завершения Rust-side staging, а экран выходит из режима импорта сразу
  после `done`, не ожидая повторного перечитывания каталога.
- Добавлено удаление импортированных паков иконок через Rust FRB API с
  подтверждением в UI и обновлением списка после удаления.

### rust_bridge

- `keepass_api` и `icon_pack_catalog_api` разнесены по вложенным Rust-модулям,
  сохранив прежние FRB-экспорты для Dart.
- `crypt_api` разнесён на вложенные Rust-модули `types` и `operations` для более
  читаемой поддержки файлового шифрования.
- Rust FRB API-модули `crypt_api`, `keepass_api` и `icon_pack_catalog_api`
  переведены на папки с `mod.rs`; публичные обёртки оставлены в корне модулей,
  чтобы generated Dart API не уходил во вложенные `operations`/`types` файлы.
- Импорт icon packs из Rust перенесён в blocking task, чтобы распаковка архивов
  и файловые операции не занимали async executor FRB во время больших импортов.
- Добавлен Rust FRB API для icon packs с поддержкой импорта из архива и папки,
  прогрессом через stream и сохранением manifest/index в служебный каталог
  приложения.
- `keepass_api.rs` переведён на актуальный reference API crate `keepass`:
  экспорт групп, записей, иконок и вложений больше не обращается к private полям
  старой модели.

## 2026-05-01

### docs

- В README добавлено упоминание анализа одинаковых паролей в dashboard и
  перехода к редактированию найденной записи.

### password_manager

- `ExpandableListCard` блокирует `copyActions` у удаленных записей blur-overlay
  с подсказкой `Восстановите для использования`.
- В view-экранах форм edit-кнопка теперь блокируется для удалённых записей; при
  загрузке сохраняется `isDeleted` из `record.$1`, чтобы действие редактирования
  оставалось недоступным.
- Autocomplete-поля логина/email больше не изменяют Riverpod provider во время
  build-фазы `RawAutocomplete`: запрос подсказок отложен до завершения текущего
  построения дерева.
- Экран одинаковых паролей повторно запускает анализ после возврата из формы
  редактирования выбранного пароля.
- Мобильный scrim под `FloatingNavBar` переведён на однотонную полупрозрачную
  заливку, чтобы нижняя панель читалась мягче над контентом.
- Добавлен dashboard-экран анализа одинаковых паролей: отдельный пункт `Дубли`
  для паролей запускает проверку активных записей после первого кадра,
  показывает группы совпадений без раскрытия значения пароля и открывает
  редактирование выбранной записи по клику.
- На мобильном экране анализа одинаковых паролей скрыт dashboard FAB, чтобы
  нижние действия не перекрывали результаты проверки.
- Добавлены shared widgets `LoginAutocompleteField` и `EmailAutocompleteField`:
  поля используют общую декорацию `primaryInputDecoration` и показывают до 10
  подсказок из текущего store.
- Провайдер подсказок логина/email переведен на `AutoDisposeAsyncNotifier` со
  state и SQL-запросами `UNION ... LIMIT 10` вместо загрузки всех записей через
  DAO.
- В форме пароля поля логина и email переведены на новые autocomplete-виджеты.
- Autocomplete-поля подключены в формах контакта, Wi-Fi и OTP для email,
  username и account name.

## 2026-04-29

### home

- `HomeScreen` теперь отключает декоративные анимации, когда приложение не
  находится в активном lifecycle-состоянии.

### password_generator

- В генератор паролей добавлено редактирование набора символов для каждой
  категории через кнопку редактирования или двойной клик по опции.
- Пользовательские наборы символов генератора сохраняются в профилях и
  восстанавливаются при выборе профиля.

### password_manager (close store sync)

- `LockStoreScreen` теперь показывает отдельный текст проверки синхронизации при
  initial loading `currentStoreSyncProvider` и временно блокирует действия до
  получения sync status.
- `LockStoreScreen` теперь также блокирует разблокировку и выход во время общего
  `isSyncInProgress`, показывая текст текущей cloud sync операции.
- Close-store sync dialog при успешном upload показывает короткое состояние
  завершения с галочкой и только после этого автоматически закрывается.
- За мобильный `FloatingNavBar` добавлено градиентное затемнение, которое
  усиливает контраст нижней навигации над контентом.
- Мобильный `FloatingNavBar` сделан полупрозрачным, чтобы контент под ним мягко
  просматривался через панель.
- Мобильный `FloatingNavBar` переведён в glass-стиль с blur-фоном, прозрачным
  градиентом и более выраженной светлой границей.
- `SnapshotSyncService.loadStatus()` теперь повторяет чтение remote manifest при
  временных cloud storage `network`/`timeout` ошибках, чтобы нестабильное
  соединение не превращалось сразу в ложный `remoteMissing`.
- `MobileCloudSyncOverlay` снова заметно показывает initial cloud-check hint:
  длительность увеличена до 2 секунд, добавлен fallback-текст для старта sync до
  первого progress event.
- `MobileCloudSyncOverlay` больше не показывает delayed check hint после уже
  завершённого сравнения локальной и облачной версий; для loading используется
  cached sync status.
- Во время первичной загрузки sync status overlay показывает нейтральный статус
  проверки даже до того, как станет известно наличие cloud binding.
- Close-store snapshot sync больше не редиректит на отдельный route: состояние
  `closeStoreSyncStatusProvider` отображается глобальным незакрываемым диалогом
  поверх текущего экрана.
- Содержимое `CloseStoreSyncScreen` вынесено в общий widget и переиспользуется
  route-экраном и новым dialog host.
- Если пользователь вручную пропускает upload при закрытии, требование upload
  сохраняется для этого же store и prompt снова появляется при следующем
  закрытии, пока локальная snapshot-версия не будет отправлена или
  синхронизирована.
- `closeStore`/`lockStore` перед закрытием учитывают текущий cached sync
  snapshot: если статус текущего store `localNewer`, close-sync tracking
  принудительно помечается как требующий upload.
- Close-sync dialog теперь открывается сразу при активной фазе close-sync
  (`checking`/prompt/upload), а не только после начала публикации upload status.
- Для фазы `checking` добавлен отдельный контент диалога: показывается проверка
  snapshot-версий без преждевременного prompt из cached status.
- Удалён промежуточный `closeStoreSyncStatusProvider`; close-sync dialog теперь
  напрямую читает `mainStoreCloseSyncProvider` как единственный source of truth.
- `currentStoreSyncSnapshotProvider` переименован в
  `cachedCurrentStoreSyncStatusProvider`, чтобы явно обозначить кеш последнего
  sync status открытого store.

### db_core (crud dao tuples)

- Старый `StoreCleanupService` удалён; очистка хранилища теперь использует use
  case `PerformStoreCleanup` и provider `performStoreCleanupProvider`.
- Startup cleanup при `createStore`/`openStore` остаётся неблокирующим через
  `unawaited(runStartupCleanup(session))`.

- В `lib/main_db/core/daos/crud` добавлен общий generic alias
  `VaultItemWith<T> = (VaultItemsData, T)`.
- CRUD-DAO в папке переведены на `VaultItemWith<T>`, чтобы убрать повторение
  `VaultItemsData` в сигнатурах JOIN-результатов.

### password_manager (wifi form)

- `WifiOsBridge` переведён на `AsyncResultDart` из `result_dart`; локальный
  `WifiOsResult` удалён, а экраны Wi-Fi формы переведены на обработку результата
  через `fold()`.

### password_manager (close store sync texts)

- Обновлены тексты `CloseStoreSyncContent`: экран явно сообщает, что
  синхронизация происходит после закрытия БД, и предупреждает, что отказ от
  отправки актуальной версии на разных устройствах может привести к неразрешимым
  конфликтам.

### password_manager (close store sync animation)

- `CloseStoreSyncContent` получил мягкую анимацию появления и плавный
  `AnimatedSwitcher` для смены состояния внутри экрана закрытия.

### cloud_sync (dio smart retry)

- `CloudSyncHttpClient` подключён к `dio_smart_retry`: retry теперь
  автоматически срабатывает для подходящих сетевых и HTTP status ошибок, а 401
  по-прежнему уходит в existing OAuth refresh flow.
- В `StoreSyncStatus` добавлен typed `StoreSyncActivity`; `_resolveConflict` и
  обычный `syncNow` сразу публикуют `preparingUpload/preparingDownload`, а
  progress events переводят состояние в `uploading/downloading`, чтобы UI
  мгновенно показывал текущую cloud sync операцию.
- `resolveConflictWithUpload/Download` публикуют состояние подготовки синхронно
  на входе, до любых `await`, чтобы пользователь сразу видел заблокированный
  sync flow.
- `currentStoreSyncProvider` больше не затирает активный remote download status
  дефолтным locked-status при переходе на `LockStoreScreen`.

### password_manager (dashboard animation setting)

- Порог, при котором dashboard использует анимированные `SliverAnimatedList` /
  `SliverAnimatedGrid`, вынесен в отдельную настройку в `SettingsPrefs` и теперь
  редактируется в секции Dashboard на экране `SettingsScreen`.
- Добавлен общий switch для полного отключения анимаций dashboard: при
  выключении список, сетка и diff-обновления переходят в статичный режим.

### password_generator (widgets split)

- В `PasswordGeneratorWidget` вынесены отдельные виджеты в папку
  `lib/features/password_generator/widgets` без использования `part`.

### password_manager (dashboard menu backup)

- В popup-меню dashboard app bar добавлен пункт `Бэкап сейчас`, который
  запускает ручное создание бэкапа для открытого хранилища.

## 2026-04-28

### cloud_sync (snapshot sync)

- `SnapshotSyncService` и `StoreSnapshotManifestBuilder` переведены с удалённого
  `MainStoreStorageService` на new `MainStoreFileService`.
- В `MainStoreFileService` добавлены helpers для snapshot sync import-flow:
  построение пути файла БД, подготовка уникальной директории импорта и
  нормализация имени хранилища.

## 2026-04-27

### db_core (new main store UI migration)

- UI и password-manager провайдеры переключены с old `main_store_provider`,
  `dao_providers`, `service_providers`, `db_history_provider` и migration dialog
  на new `lib/main_db/new`.
- В new main-store добавлены совместимые facade-экспорты и методы для
  `mainStoreProvider`, `dataUpdateStreamProvider`, backup orchestrator,
  storage-service providers и путей вложений, чтобы UI работал поверх нового
  `MainStoreManagerNotifier`.
- Исправлены diagnostics после переключения на non-null
  `mainStoreManagerProvider`: удалены лишние null-checks, устаревший
  `withOpacity`, unused поле автобэкапа и async-gap предупреждения в карточке
  recent database.

### db_core (main store manager notifier)

- Добавлена синхронизация на уровне `MainStoreManagerNotifier`: все
  state-changing операции (`createStore`, `openStore`, `closeStore`,
  `lockStore`, `unlockStore`, `deleteStore`, `updateStore`) обёрнуты в
  `_lock.synchronized()` для предотвращения race conditions при одновременных
  вызовах из разных потоков/async-контекстов.

### db_core (dao providers)

- `dao_providers.dart` переведён на `AppError.mainDatabase(...)` для сценария,
  когда хранилище не открыто, и убран лишний неиспользуемый `manager`.

### db_core (main store metadata)

- `MainStoreMetadataService` переведён с `DatabaseError` на `AppError` для
  сценариев `recordNotFound`, `queryFailed` и `updateFailed`.

### archive_storage (import ui)

- `ImportTab` теперь определяет неверный пароль через `AppError.archive` и
  `ArchiveErrorCode.invalidPassword` вместо legacy
  `ArchiveInvalidPasswordError`.

### db_core (main store manager)

- `MainStoreManager.createStore()` и `MainStoreManager.openStore()` теперь
  закрывают ранее открытое хранилище перед открытием нового, чтобы избежать
  утечек ресурсов и конфликтов при переключении между хранилищами.

### docs (db_core)

- Добавлен `docs-ai/new-main-store-missing-old-api.md` со списком old API,
  который ещё не перенесён или не выставлен в new main store manager/provider.

### cloud_sync (snapshot sync)

- Добавлены doc-комментарии к `StoreVersionCompareResult` и `SnapshotSyncStage`
  в модели snapshot sync, а также пояснения к каждому значению enum.

## 2026-04-26

### db_core (new main store manager)

- `DatabaseStatus.closingWithCloudSync` удалён из new-ветки: cloud-sync close
  flow больше не хранится в состоянии БД.
- `MainStoreManagerNotifier.closeStore()` теперь запускает close-sync только
  если `closeSyncTrackingProvider` фиксирует логические изменения текущего
  `StoreMeta.modifiedAt`; прогресс, prompt и ошибка синхронизации вынесены в
  отдельный `mainStoreCloseSyncProvider`.
- В new `MainStoreManagerNotifier` реализованы `lockStore(...)` и
  `unlockStore(...)`: lock закрывает текущую сессию с сохранением path/info в
  `DatabaseStatus.locked`, unlock повторно открывает store и заново стартует
  close-sync tracking.
- В new `MainStoreManager` / `MainStoreManagerNotifier` реализованы
  `deleteStore(...)` и `deleteStoreFromDisk(...)` с закрытием активной сессии,
  удалением history entry и опциональным удалением директории store.
- `MainStoreManager` в new-ветке теперь сам владеет startup cleanup после
  create/open, а provider больше не запускает cleanup повторно при unlock.
- Порядок закрытия в new-ветке изменён на after-close sync:
  `MainStoreManagerNotifier` сначала успешно закрывает store и выставляет
  `DatabaseStatus.closed`, затем запускает snapshot upload и переводит state в
  `DatabaseStatus.idle` только после завершения sync-попытки.
- `mainStoreCloseSyncController.dart` в new-ветке переписан в service +
  `AsyncNotifier` state machine для close-sync (`checking`,
  `waitingForDecision`, `syncing`, `completed`, `skipped`, `failed`).
- Close-sync new-ветки разнесён по слоям:
  `models/main_store_close_sync_state.dart`,
  `services/main_store_close_sync_service.dart` и
  `providers/main_store_close_sync_provider.dart`; сервис больше не зависит от
  `Ref`, а provider получает данные store от manager, сам читает
  binding/token/status и обновляет state.
- Из close-sync service API удалены callback-параметры для prompt/progress flow;
  решение пользователя и progress теперь проходят через state
  `mainStoreCloseSyncProvider`.
- `MainStoreCloseSyncNotifier.uploadSnapshotAfterClose(...)` ждёт решение
  пользователя через внутренний `Completer`, публикуя
  `MainStoreCloseSyncPhase.waitingForDecision` для UI.
- `MainStoreCloseSyncNotifier.uploadSnapshotAfterClose(...)` не принимает
  `logTag` и не импортирует manager-provider; manager передаёт только уже
  прочитанные `StoreInfoDto` и путь текущего хранилища.
- В new `MainStoreManager` добавлен `getStoreInfo()` с `AppError` mapping для
  чтения актуального `StoreMeta` перед close-sync проверкой.
- Добавлен `closeSyncTrackingProvider` для new-ветки: Riverpod-state для
  отслеживания `openedModifiedAt`, `forceUpload` и pending close-sync prompt.
- `CloseSyncTrackingState` оставлен простым immutable state-контейнером, вся
  логика изменения close-sync tracking перенесена в notifier.
- `MainStoreManagerNotifier` теперь стартует close-sync tracking после успешного
  `create/open` и сбрасывает его при закрытии/reset состояния.
- Добавлен `mainStoreManagerStateProvider` для new-ветки:
  `AsyncNotifierProvider<MainStoreManagerNotifier, DatabaseState>` управляет
  состоянием `create/open/close/update` поверх `MainStoreManager` без
  дополнительного lock-слоя.
- `MainStoreManager.openStore(...)` в new-ветке теперь после успешного открытия
  запускает стартовую очистку хранилища через `unawaited(...)`, как
  old-provider.
- В `lib/main_db/new/main_store_manager.dart` возвращено stateful-поведение
  manager как в old-версии: добавлены поля текущего стора (`MainStore`) и
  текущей `Session`, а также геттеры
  `isStoreOpen/currentStore/currentSession/currentStorePath`.
- В `createStore(...)` и `openStore(...)` текущая сессия теперь сохраняется в
  менеджере после успешного открытия.
- В `closeStore(...)` текущий state очищается после успешного закрытия
  соответствующей сессии; в `updateStore(...)` обновляется `currentSession.info`
  для активного стора.
- `closeStore(...)` теперь закрывает именно текущий активный стор из state
  менеджера (`currentSession`), а при передаче неактивной сессии логирует
  warning и всё равно закрывает активную.
- В `MainStoreManager.closeStore(...)` (new-ветка) удалён параметр `session`:
  метод закрывает только текущую активную `currentSession` из внутреннего
  состояния менеджера.
- В `MainStoreManager` (new-ветка) добавлен метод
  `getStoreMeta(MainStore database)` для чтения `StoreMeta` с явным
  `AppError.mainDatabase`-маппингом (`recordNotFound` / `queryFailed`).

### docs (agents / errors)

- Обновлён `AGENTS.md` под новую систему ошибок: правило для доменных/DB-flow
  переведено с `DatabaseError` на типизированные результаты с `AppError`
  (`ResultDart<T, AppError>` / `AsyncResultDart<T, AppError>`).
- В `AGENTS.md` добавлено явное требование не бросать исключения в
  business/domain-слое и конвертировать boundary-исключения в
  `Failure(AppError...)`.
- В done criteria `AGENTS.md` уточнено, что явная обработка ошибок должна идти
  через typed results и `AppError` mapping.
- `docs-ai/error-handling.md` синхронизирован с новой моделью ошибок:
  рекомендации и guideline закрепляют `Failure(AppError...)`, а устаревший
  пример `DatabaseError` заменён на секцию про проектный `AppError`.

## 2026-04-25

### db_core (update store usecase)

- Реализован новый use case `lib/main_db/new/usecases/update_main_store.dart`
  для обновления metadata хранилища в открытой `Session` (имя, описание,
  хеш/соль пароля).
- `MainStoreManager` в new-ветке переведён на `UpdateMainStore`:
  `updateStore(...)` больше не `UnimplementedError` и выполняет синхронизацию
  истории (`DatabaseHistoryService`) по аналогии с old-реализацией.

### db_core (usecases utils)

- Общий обработчик ошибок `_handleError` вынесен из `create_main_store.dart` и
  `open_main_store.dart` в `lib/main_db/new/usecases/utils/error_handling.dart`.
- `CreateMainStore` и `OpenMainStore` переведены на общий helper
  `handleMainStoreUseCaseError(...)` без изменения сценариев обработки ошибок.

### db_core (compatibility model)

- `StoreOpenCompatibility` вынесен из
  `lib/main_db/new/services/main_store_compatibility_service/main_store_compatibility_service.dart`
  в отдельную модель
  `lib/main_db/new/services/main_store_compatibility_service/model/store_open_compatibility.dart`.

### core/errors (main db codes)

- В `MainDatabaseErrorCode` добавлены коды `DB_STORE_MIGRATION_REQUIRED` и
  `DB_STORE_VERSION_TOO_NEW` для явного различения сценариев обязательной
  миграции и слишком новой версии хранилища.

### db_core (history provider)

- Добавлен провайдер `dbHistoryProvider` для new-ветки в
  `lib/main_db/new/providers/db_history_provider.dart`: создаёт
  `DatabaseHistoryService`, вызывает `initialize()` и возвращает готовый инстанс
  через `FutureProvider`.
- Добавлен barrel-export `lib/main_db/new/providers/index.dart` для
  централизованного импорта провайдеров new-ветки.

### db_core (main store provider)

- Добавлен `mainStoreServiceProvider` в
  `lib/main_db/new/providers/main_store_service_provider.dart`: провайдер
  ожидает `dbHistoryProvider`, после чего создаёт `MainStoreService` с
  инициализированным `DatabaseHistoryService`.
- Обновлён экспорт new-провайдеров в `lib/main_db/new/providers/index.dart`.

### db_core (new main store factory)

- Добавлен use case `OpenMainStore` для new-ветки: открытие стора вынесено из
  будущего `MainStoreService` в отдельный слой с чтением `store_manifest.json`,
  деривацией ключа, подключением `MainStore`, fallback-подбором `DBCipher` и
  возвратом `Session`.
- В new-ветку добавлен `MainStoreCompatibilityService` на `AppError`: проверяет
  `manifestVersion`, `lastMigrationVersion` и `appVersion`, блокирует слишком
  новые хранилища и явно сообщает о требуемой миграции.
- `MainStoreFileService` получил `resolveExistingStoragePath(...)`, чтобы
  `openStore` принимал как директорию хранилища, так и прямой путь к файлу БД.
- `MainStoreService.openStore(...)` подключён к `OpenMainStore` и после
  успешного открытия создаёт или обновляет запись `DatabaseHistoryService`;
  ошибка history логируется warning и не отменяет открытую сессию.
- Добавлен use case `CloseMainStore` для закрытия `MainStore`; новый
  `MainStoreManager.closeStore(...)` принимает `Session` явно и не хранит
  состояние открытого стора внутри manager.
- `MainStoreManager` оставлен stateless-оркестратором use case’ов:
  `createStore/openStore` возвращают `Session`, а владение текущей сессией будет
  вынесено в отдельный provider.
- Поток создания нового стора вынесен из `MainStoreFactory` в use case
  `CreateMainStore` (`lib/main_db/new/usecases/create_main_store.dart`) с единым
  входом `call(...)`; `MainStoreService` теперь зависит от use case.
- `main_store_factory.dart` оставлен как временная совместимая обёртка над
  `CreateMainStore` для старых импортов.
- Низкоуровневый поток `createStore(...)` в новой DB-ветке перенесён из
  `MainStoreService` в `MainStoreFactory`: подготовка директории, создание
  encrypted `MainStore`, запись `store_meta`, cleanup при ошибках и возврат
  `Session`.
- `MainStoreService` оставлен тонкой оболочкой над `MainStoreFactory` с
  синхронизацией через `Lock` и делегированием вспомогательных методов путей.
- `MainStoreFactory` теперь использует существующий `MainStoreConnectionService`
  для создания encrypted `MainStore`, без дублирования setup
  SQLite/PRAGMA/cipher в factory.
- `MainStoreConnectionService` переведён с `DatabaseError` на `AppError`;
  временный маппинг ошибок подключения в `MainStoreFactory` удалён.
- Логирование в `MainStoreConnectionService` переведено с `debugPrint` на
  проектные `logInfo/logWarning/logError`.
- `MainStoreFactory.createStore(...)` снова использует Argon2/HKDF-деривацию
  через `DbKeyDerivationService`: генерирует `argon2Salt`, передаёт в SQLite
  derived `pragmaKey` вместо master password и пишет `keyConfig` в
  `store_manifest.json`.
- В `DbKeyDerivationService` сохранён размер соли как в старой реализации:
  `saltLength = 32` (256 бит).
- `MainStoreService.createStore(...)` после успешного `CreateMainStore` создаёт
  запись в `DatabaseHistoryService` с путём стора, id, именем, описанием и
  опционально сохранённым master password.
- Для записи history используется фактический `session.storeDirectoryPath`,
  возвращённый `CreateMainStore`, без повторного вычисления пути в сервисе.
- Ошибка записи в `DatabaseHistoryService` больше не делает `createStore(...)`
  неуспешным: созданная сессия возвращается как `Success(session)`, а сбой
  history логируется как warning.
- Методы путей и операций директории стора (`getAttachmentsPath`,
  `getDecryptedAttachmentsPath`, `storageDirectoryExists`,
  `deleteStorageDirectory`) вынесены из `CreateMainStore` в отдельный
  `MainStoreFileService`.
- Поиск файла базы (`findDatabaseFile`) также перенесён в
  `MainStoreFileService`; `CreateMainStore` использует сервис вместо
  собственного метода.
- `CreateMainStore` стал устойчивее к будущим сбоям: путь директории строится
  один раз из уже нормализованного имени, backup-имя для папок без БД больше не
  берётся из raw `storeName`, а cleanup директории выполняется даже если
  закрытие частично созданного `MainStore` завершилось ошибкой.
- `CreateMainStore.normalizeStorageName(...)` теперь отсекает имена, которые
  могут превратиться в некорректный путь (`.`, `..`, имена только из точек и
  Windows-reserved имена вроде `CON`, `NUL`, `COM1`, `LPT1`).

### db_core (store cleanup)

- `PerformStoreCleanup.call(...)` теперь возвращает структурированный
  `StoreCleanupResult` вместо `Future<void>`: вызывающий код получает явный
  статус сценария (`completed`, `skippedByInterval`, `failed`) и детали
  выполнения (параметры cleanup history, число удалённых orphaned-файлов, текст
  ошибки при падении).
- В `PerformStoreCleanup` и `StoreCleanupResult` магические числовые литералы
  (дефолты интервала/лимитов и служебный `0`) вынесены в `static const` поля,
  чтобы упростить поддержку и исключить дублирование чисел в коде.

### db_core (archive service)

- В `lib/db_core/new/services/archive_service/archive_service.dart` служебные
  модели изолятов (`ArchiveParams`, `UnarchiveParams`, `ArchiveProgressMessage`,
  `ArchiveIsolateResult`) вынесены в отдельную папку
  `lib/db_core/new/services/archive_service/models`, добавлен barrel-export
  `models/models.dart`, а `ArchiveService` переведён на импорт этих моделей.
- В `lib/db_core/new/services/archive_service/archive_service.dart` тип ошибок в
  `ResultDart` заменён с `DatabaseError` на `AppError`, а все `Failure` ветки
  переведены на `AppError.fileSystem` / `AppError.archive` (включая конвертацию
  исключений через `toFileSystemAppError`).

### core/errors

- Добавлен новый тип ошибок архивации: `ArchiveErrorCode` в
  `lib/core/errors/error_enums/archive_errors.dart` и новый вариант
  `AppError.archive(...)` в `lib/core/errors/app_error.dart`.
- Обновлены экспорты `error_enums.dart` и сгенерированные файлы
  `app_error.freezed.dart`/`app_error.g.dart` для сериализации и union-case
  архивации.
- Extension `FileErrorToAppErrorExtension` для конвертации базовых файловых
  ошибок (`FileSystemException`, `IOException`, `Object`) в
  `AppError.fileSystem` вынесен в отдельную папку расширений:
  `lib/core/errors/extensions/file_error_to_app_error_extension.dart`.
- Добавлен barrel-export `lib/core/errors/extensions/extensions.dart` и
  подключение расширений через `lib/core/errors/errors.dart`.

### db_core (new main store service)

- `MainStoreService.createStore(...)` в новой DB-ветке переписан как
  низкоуровневое создание стора: подготовка директории, создание encrypted
  `MainStore`, первичная запись `store_meta` через DAO и возврат открытой сессии
  без подключения history/manifest/runtime-сервисов.

## 2026-04-21

### db_core (opening state)

- Удалён отдельный `mainStoreOpeningOverlayProvider`: глобальный overlay
  открытия хранилища теперь определяется напрямую по `DatabaseState`, а не по
  побочному boolean-провайдеру.
- В `DatabaseStatus` добавлено явное состояние `opening`;
  `MainStoreAsyncNotifier` переводит хранилище в него в начале `openStore(...)`,
  а migration-flow использует тот же статус уже на этапе
  `backup -> migrate -> open`.
- Обновлены потребители UI-состояния открытия: `AppRuntimeWrapper`,
  `RecentDatabaseCard` и status bar теперь различают `opening` и обычный
  `loading`.

### db_core (runtime split)

- `MainStoreManager` вынесен из `MainStoreRuntime` в отдельный
  `mainStoreManagerRuntimeProvider`, чтобы runtime больше не смешивал manager и
  service-зависимости в одном объекте.
- `MainStoreAsyncNotifier`, `MainStoreStorageController`,
  `MainStoreBackupController`, `MainStoreBackupOrchestrator` и
  `MainStoreCloseSyncController` переведены на явные зависимости
  `manager + runtime`, без доступа к manager через `runtime.manager`.
- `MainStoreBackupService` также вынесен из `MainStoreRuntime` в отдельный
  `mainStoreBackupServiceProvider`; backup-поток теперь получает сервис
  напрямую, а runtime оставлен только для maintenance-зависимостей.
- `MainStoreMaintenanceService` вынесен из `MainStoreRuntime` в отдельный
  `mainStoreMaintenanceServiceProvider`; после этого `MainStoreRuntime` и
  `mainStoreRuntimeProvider` полностью удалены, а storage-операции получают
  maintenance-сервис напрямую.
- В `MainStoreAsyncNotifier` удалены приватные helpers `_handleOpenStoreSuccess`
  / `_handleOpenStoreFailure`: open-flow теперь замкнут локально внутри
  `_openStore()`, без лишнего прыжка по файлу.

### db_core (backup isolation)

- Backup-логика полностью вынесена из `MainStoreAsyncNotifier` в отдельный
  orchestration-слой
  `lib/db_core/provider/main_store_backup_orchestrator_provider.dart`.
- В `MainStoreAsyncNotifier` удалены backup-методы и backup-controller
  зависимости (`createBackup`, `startPeriodicBackup`, `stopPeriodicBackup`,
  `isPeriodicBackupActive`, `backupAndMigrateStore`), чтобы notifier больше не
  зависел от backup-потока.
- Добавлены `openStoreWithMigration(...)` и `setOpenFailure(...)` как
  backup-agnostic API для сценариев миграции/ошибок открытия без возврата
  backup-логики в notifier.
- UI и sync-слои переведены на новый backup provider: `settings_sections.dart`,
  `titlebar.dart`, `dashboard_drawer.dart`,
  `cloud_sync_snapshot_sync_listener.dart`, `store_open_migration_dialog.dart`.

### docs-ai

- Добавлен подробный технический разбор связей и зависимостей
  `MainStoreAsyncNotifier` в `docs-ai/main-store-async-notifier-analysis.md`:
  карта используемых сервисов/контроллеров/провайдеров, внутренняя call-graph
  логика, и матрица зависимостей по каждому публичному и приватному методу.
- В `docs-ai/main-store-async-notifier-analysis.md` добавлена отдельная секция
  «Методы, использующие одинаковые сервисы» с группировкой
  `сервис -> список методов`, чтобы быстро находить повторяющиеся зависимости
  (например, для backup/storage/close-sync сценариев).

## 2026-04-20

### db_core (main_store_provider)

- `lib/db_core/provider/main_store_provider.dart` декомпозирован на отдельные
  модули библиотеки (`backup`, `lifecycle`, `snapshot_sync`, `storage`) без
  изменения публичного API `mainStoreProvider` / `MainStoreAsyncNotifier`.
- В корневом файле провайдера оставлен только entrypoint библиотеки, общее
  состояние/таймеры и короткие delegating-методы, чтобы lifecycle стора,
  backup-логика, cloud close-sync и storage-операции больше не были смешаны в
  одном 1400+ строковом файле.
- В `closeStore()` убран обязательный preflight remote status-check перед
  закрытием: если `currentStoreSyncProvider` уже загрузил актуальный
  `StoreSyncStatus`, close-flow теперь переиспользует его `remoteManifest` и
  пересчитывает только локальный snapshot; повторный сетевой `loadStatus()`
  остаётся только fallback для offline-skipped/отсутствующего кеша.
- Fake-модульность через `part` заменена на явные standalone-компоненты:
  добавлены `main_store_runtime_provider.dart`,
  `main_store_backup_controller.dart`, `main_store_storage_controller.dart` и
  `main_store_close_sync_controller.dart`, а `MainStoreAsyncNotifier` превращён
  в тонкий session/lifecycle facade.
- `mainStoreManagerProvider` больше не зависит от внутренних геттеров notifier-а
  и строится через `mainStoreRuntimeProvider` + текущее `DatabaseState`, что
  убирает протекание manager-деталей наружу из session-слоя.
- Для новой композиции добавлены unit-тесты на backup-controller и wiring
  `mainStoreManagerProvider`, а существующие widget-тесты экранов
  `close_store_sync` и `lock_store` подтверждают сохранение текущего UI
  поведения.

### cloud_sync / settings

- Добавлена новая настройка `Авто-отправка при закрытии` в секцию
  `Синхронизация`: при включении приложение автоматически отправляет локально
  более новую snapshot-версию в облако при закрытии хранилища без
  дополнительного подтверждения пользователя.
- Close-store sync flow обновлён: prompt
  `Отправить и закрыть / Закрыть без отправки` теперь пропускается, если включён
  новый флаг `autoUploadSnapshotOnCloseEnabled`; экран закрытия сразу показывает
  прогресс синхронизации.
- В `CloseDatabaseButton` добавлен мгновенный visual feedback при закрытии
  хранилища (spinner + блокировка повторного нажатия), чтобы при ожидании
  pre-check cloud sync статуса не создавалось ощущение зависания UI.
- В мобильном сценарии закрытия через dashboard-диалог (`Назад` ->
  `Закрыть базу данных?`) промежуточный `toast` заменён на модальный `overlay` с
  индикатором и блокировкой ввода: пользователь сразу видит, что закрытие
  запущено, и UX остаётся предсказуемым как с cloud sync, так и без неё.
- Исправлен edge-case для авто-отправки при закрытии: если включён
  `autoUploadSnapshotOnCloseEnabled` и сеть недоступна (network/timeout/
  cancelled), ошибка cloud sync больше не блокирует закрытие хранилища;
  close-flow продолжает закрытие локально без загрузки в облако.
- В close-flow добавлен явный pre-check интернета через
  `internetConnectionProvider.hasInternetAccess`: при включённой авто-отправке и
  отсутствии сети cloud upload перед закрытием пропускается сразу, без ожидания
  таймаутов сетевого запроса.

### password_manager / store_settings

- Исправлен `StateError` при закрытии модального окна настроек хранилища:
  `showStoreSettingsModal(...)` больше не использует `WidgetRef` после `await`
  (и потенциального unmount виджета), вместо этого состояние провайдеров
  обновляется через заранее полученный `ProviderContainer`.
- В `showStoreSettingsModal(...)` добавлен `dispose()` для
  `ValueNotifier<int> pageIndexNotifier`, чтобы корректно освобождать ресурсы
  после закрытия модалки.

### windows / runner

- Для Windows runner добавлена single-instance логика в
  `windows/runner/main.cpp` через именованный mutex: повторный запуск больше не
  создаёт вторую копию процесса.
- Добавлена обработка флага запуска `--start-in-tray`: при старте с этим
  аргументом главное окно не показывается автоматически на первом кадре.
- Реализован IPC-сценарий через `RegisterWindowMessage`: если приложение уже
  запущено и пользователь запускает его без `--start-in-tray`, новый процесс
  отправляет запрос существующему экземпляру показать и активировать окно, после
  чего завершается.

## 2026-04-19

### cloud_sync

- Исправлена обработка retry в `CloudSyncAuthInterceptor`: ответы вроде Dropbox
  `409 path/conflict/folder` после успешного refresh больше не маскируются под
  `Failed to refresh OAuth token`, а доходят до storage-слоя как обычные
  API-ошибки.
- В `AppLogger.dioLogPrint()` добавлено редактирование чувствительных полей
  (`Authorization`, `access_token`, `refresh_token`, `client_secret`), чтобы
  OAuth-секреты не попадали в debug-логи cloud sync.
- Исправлен сценарий `close store + cloud sync`: если отправка snapshot перед
  закрытием падает из-за сети/таймаута/авторизации, хранилище больше не
  закрывается молча, ошибка сохраняется в `mainStoreProvider`, показывается в
  UI, а следующий `closeStore()` повторно пытается отправить локально более
  новую версию в облако.
- Убрана безусловная навигация на `home` после failed close из dashboard-диалога
  закрытия хранилища.
- Для сценария `close store` добавлен явный выбор при `localNewer`: экран
  закрытия теперь спрашивает, нужно ли сначала отправить локально более новую
  snapshot-версию в облако, и только после выбора продолжает закрытие.
- Исправлен `MobileCloudSyncOverlay`: overlay снова показывается на мобильном
  dashboard при проверке cloud sync и после завершения проверки, потому что
  виджет больше не теряет remembered binding при переходе
  `AsyncData -> AsyncLoading -> AsyncData`.
- Для сценария `close store` расширен prompt перед upload: теперь экран закрытия
  спрашивает про отправку не только при `localNewer`, но и сразу после первого
  подключения cloud sync, когда `remoteMissing` означает, что облачная
  snapshot-версия ещё не была создана.
- Исправлен показ `close-store-sync`: при входе в сценарий закрытия с cloud sync
  экран теперь открывается напрямую через роутер сразу после перевода
  `mainStoreProvider` в `DatabaseStatus.closingSync`, а не зависит только от
  последующего `redirect`.
- Роутер `close-store-sync` теперь реагирует не только на
  `DatabaseStatus.closingSync`, но и на `closeStoreSyncStatusProvider`, чтобы
  экран закрытия и prompt на upload не терялись, если переходное состояние
  `closingSync` прошло слишком быстро.
- В `closeStore()` initial upload больше не пропускается только из-за
  неизменённого `StoreMeta.modifiedAt`: если текущий sync-статус уже показывает
  `remoteMissing` или `localNewer`, сценарий закрытия всё равно открывает prompt
  и не закрывает хранилище молча.
- Убран прямой вызов `GoRouter` из `main_store_provider`: показ
  `close-store-sync` снова целиком управляется через router listeners, чтобы
  runtime-ошибка навигации внутри provider не маскировалась под failed cloud
  upload при закрытии хранилища.
- Устранён `CircularDependencyError` между `mainStoreProvider` и
  `currentStoreSyncProvider`: `closeStore()` больше не читает
  `currentStoreSyncProvider`, а pending-close флаг синхронизируется в
  `mainStoreProvider` из `current_store_sync_provider` через отдельный метод без
  циклической зависимости Riverpod.
- В `CloudSyncSettingsPage` блок статуса синхронизации вынесен в отдельный файл
  `cloud_sync_status_card.dart` (без `part`), а UI карточки сделан более живым:
  добавлены цветовой статус-баннер с иконкой, информационные чипы и выделенные
  метрики ревизий/времени синхронизации.
- В `CloudSyncStatusCard` исправлена типизация метрик ревизии: значения
  `localManifest/remoteManifest.revision` теперь конвертируются в `String`,
  чтобы исключить ошибку `Object` -> `String` при передаче в UI.

### docs (agent)

- Полностью реструктурирован `AGENTS.md`: файл сокращен до компактного
  entrypoint с обязательным порядком чтения, non-negotiable правилами и
  маршрутизацией по типам задач.
- Добавлен `docs-ai/agent-task-router.md` как единая карта "какой документ
  читать для какой задачи", чтобы агенты быстро брали только релевантный
  контекст.
- Добавлен `docs-ai/agent-architecture-map.md` с краткой навигацией по
  архитектуре и ключевым директориям проекта без дублирования подробных гайдов.
- В `AGENTS.md` добавлен явный приоритет MCP-инструментов: Dart/Flutter MCP для
  Flutter/Dart операций (включая форматирование вместо CLI-команд) и Serena MCP
  для семантического поиска/навигации/рефакторинга.
- В `AGENTS.md` уточнено правило форматирования: вместо CLI-команд `dart format`
  и `flutter format` нужно использовать MCP formatter tools.
- В `AGENTS.md` добавлено правило для Rust: использовать `rust-mcp-server` для
  семантической навигации, рефакторинга и Rust-aware операций вместо generic
  shell-подхода, когда MCP доступен.
- В `docs-ai/agent-task-router.md` добавлены отдельные маршруты для
  форматирования через Dart/Flutter MCP и семантического поиска через Serena
  MCP, а также hard-stop против дефолтного ухода в shell-команды при наличии
  MCP.
- В `docs-ai/agent-task-router.md` добавлен приоритет и отдельный маршрут для
  Rust-задач через `rust-mcp-server`.
- В quick-routing `AGENTS.md` для Rust-bridge добавлено явное указание
  использовать `rust-mcp-server` вместе с `rust-integration.md`.
- Обновлены docs/комментарии под текущую модель хранения ключевой конфигурации:
  `store_key.json` исключен из описаний, данные ключа (`keyConfig`) теперь
  зафиксированы как часть `store_manifest.json`.
- В docs добавлен `attachments_manifest.json` в структуру единицы хранилища и
  описание его роли как манифеста вложений для sync-слоя.
- Полностью актуализирован `APP_CAPABILITIES.md`: обновлены разделы по текущему
  составу фич, модулям, структуре хранилища (`store_manifest.json` +
  `attachments_manifest.json`), cloud/local sync и последним продуктовым
  изменениям.

## 2026-04-18 1.2.0

### component_showcase

- Экран `ComponentShowcaseScreen` адаптирован под мобильные устройства: на узких
  экранах навигация переведена в `Drawer` со списком компонентов, а на широких
  экранах сохранен `NavigationRail`.
- Для стабильного UX добавлен `IndexedStack` в обоих режимах отображения, чтобы
  не терять состояние открытых showcase-экранов при переключении.
- В `component_showcase` добавлен отдельный demo-экран для `Icon Pack Picker` с
  показом прямого вызова `showIconPackPickerModal(...)` и готового
  `IconPackPickerButton` с SVG-превью выбранной иконки.
- В `ButtonShowcaseScreen` расширен раздел `Button Variants`: для каждого
  демонстрируемого варианта добавлены состояния `Default`, `Disabled` и
  `Loading`.

### icon_packs

- Добавлена отдельная file-backed feature пользовательских SVG-паков без
  изменений текущей таблицы `icons`: паки хранятся в служебной директории
  `icon_packs`, для каждого пака формируются `manifest.json` и `index.jsonl`.
- Реализован импорт SVG-паков как из `.zip`-архивов, так и из обычных папок:
  используется staging-папка, нормализация `pack_key`, защита от дублей,
  фильтрация только `.svg`, игнорирование скрытых/служебных файлов и генерация
  стабильных ключей иконок для будущего хранения в БД.
- Добавлен экран управления паками иконок с импортом и просмотром списка
  импортированных паков, а также новый маршрут `/icon-packs` и кнопка перехода
  `Паки иконок` на главном экране.
- Реализован новый Wolt-based picker для паков иконок: пользователь сначала
  выбирает пак, затем SVG-иконку, а результатом становится канонический ключ
  вида `pack_key/icon_key`; для повторного использования добавлен
  `IconPackPickerButton`.
- В модалке выбора иконок из паков добавлено управление цветом предпросмотра:
  пользователь может переключаться между пресетами или выбрать свой цвет для
  визуальной проверки SVG перед выбором иконки.
- Исправлено двойное появление скролла в `IconPackPickerIconPage`: страницы
  picker-модалки переведены на `forceMaxHeight`, чтобы внешний лист не создавал
  второй scroll-container поверх внутренней сетки иконок.
- После этого уточнены ограничения по высоте для страниц icon-pack picker:
  контент страниц снова оборачивается в конечную высоту внутри модалки, чтобы
  `IconPackPickerIconPage` не получал unbounded height и не падал с
  `RenderFlex children have non-zero flex but incoming height constraints are unbounded`.
- Второй шаг picker переведен на `SliverWoltModalSheetPage`: экран выбора иконок
  теперь использует один sliver-scroll контейнер на уровне Wolt, из-за чего
  пропал второй вложенный скролл поверх сетки иконок.
- Файл `icon_pack_picker_modal.dart` декомпозирован: логика оркестрации модалки
  оставлена в основном файле, а UI-части вынесены в отдельные виджеты внутри
  `lib/features/icon_packs/picker/widgets/` без использования `part`-файлов.
- Добавлены отдельные файлы для страницы выбора пака, страницы выбора иконки,
  карточки иконки/SVG-превью и общих empty/error состояний для picker-модалки.

### password_manager (icons migration)

- Для сущностей API key, SSH key, bank card, Wi-Fi, loyalty card и OTP завершено
  сквозное подключение item-иконок через поля `iconSource`/ `iconValue`:
  обновлены DTO карточек, маппинг в filter DAO, отображение в list/grid
  карточках, формы (state/provider/UI) и восстановление из истории.

### password_manager (dashboard bulk actions)

- В dashboard добавлен новый режим массовых действий: long-press по карточке
  теперь включает multi-select режим с выбором нескольких элементов вместо
  немедленного открытия detail-view.
- Для выбранных элементов добавлены массовые операции удаления, архивации,
  добавления в избранное, закрепления, назначения категории и назначения тегов;
  на маленьких экранах эти действия сворачиваются в popup-меню toolbar.
- Прежнее действие long-press перенесено в отдельную header-кнопку `Открыть` в
  list/grid карточках; сама кнопка показывается по hover или в раскрытом
  состоянии карточки списка.
- В bulk-режиме карточки получают visual selection-state, а swipe-действия через
  `Dismissible` временно отключаются, чтобы не конфликтовать с множественным
  выбором.

### db_core (history triggers)

- Исправлены SQL-шаблоны history-триггеров в
  `lib/db_core/triggers/*_triggers.dart`: убраны ошибочные лишние запятые в
  списках колонок `vault_item_history` после добавления
  `icon_source`/`icon_value`.

### db_core (migrations)

- Добавлен каркас версионированных миграций в `lib/db_core/migrations/`:
  выделены раннер, runtime-контекст и файл миграции
  `versions/migration_v2.dart`.

- `MainStore.onUpgrade` переведен на вызов централизованного раннера
  `runMainStoreKnownMigrations(...)`, чтобы новые миграции добавлялись в
  отдельные файлы по версии.

- В `main_store_migration_types.dart` уточнены generic-типы колонок до
  `GeneratedColumn<Object>`, чтобы убрать несовместимость с
  `Migrator.addColumn`.

- Добавлен гайд `docs-ai/db-migrations.md` с пошаговой инструкцией по реализации
  миграций (создание `migration_v{N}`, регистрация в раннере, расширение
  runtime-контекста и проверка перед merge).

### db_core (main_store_manager)

- Файл `lib/db_core/main_store_manager.dart` очищен и упрощён: логика проверки
  совместимости версий/миграции вынесена в `MainStoreCompatibilityService`, а
  сборка и запись `store_manifest.json` — в `MainStoreManifestSyncService`.
- `MainStoreManager` оставлен как оркестратор жизненного цикла стора без
  изменения публичного API (`createStore/openStore/closeStore/updateStore`).
- Добавлены экспорты новых сервисов в `lib/db_core/services/index.dart`.

### db_core (main_store)

- Из `lib/db_core/main_store.dart` вынесены реализации установки триггеров и
  индексов в отдельные файлы:
  `lib/db_core/main_store_history_triggers_installer.dart` и
  `lib/db_core/main_store_indexes_installer.dart`.
- В `MainStore` оставлены компактные делегирующие методы
  `_installHistoryTriggers` и `_installIndexes`, чтобы упростить поддержку и
  навигацию по файлу.

### db_core (store manifest compatibility)

- В `store_manifest.json` добавлены явные top-level поля `lastMigrationVersion`
  и `appVersion`; версия схемы манифеста повышена до `2`, чтобы отдельно
  отслеживать совместимость данных, миграций и версии приложения.
- При открытии стора добавлена обязательная проверка совместимости между
  `manifestVersion`, `lastMigrationVersion`, `appVersion` из манифеста и
  текущими `storeManifestVersion`, `databaseSchemaVersion` и версией приложения.
- Если хранилище было подготовлено более старой версией приложения/схемы,
  открытие теперь переводится в сценарий `backup -> migrate -> open`: сначала
  создаётся резервная копия, затем выполняется миграция манифеста и только после
  этого стор открывается.
- Если `manifestVersion`, версия схемы данных или версия приложения в
  `store_manifest.json` новее текущего клиента, открытие явно блокируется как
  несовместимое вместо попытки открыть такой стор.
- Backup перед миграцией расширен: вместе с БД и зашифрованными вложениями
  теперь копируются JSON-метаданные стора (`store_manifest.json` и другие
  служебные `.json`-файлы директории хранилища).
- Сценарий предложения миграции подключен в UI открытия стора:
  `OpenStoreScreen`, быстрый вход из `RecentDatabaseCard` и открытие БД по
  launch-path показывают пользователю диалог с предложением создать backup и
  выполнить миграцию.
- Исправлено сравнение `appVersion` в `MainStoreCompatibilityService`: суффикс
  build metadata (`+buildNumber`) больше не влияет на решение о миграции, чтобы
  одинаковая версия приложения с другим номером сборки не считалась
  несовместимой.

### docs (agent)

- В `AGENT.md` добавлено упоминание гайда `docs-ai/db-migrations.md` как
  основного источника по реализации версионированных миграций `MainStore`.

### docs (release)

- Добавлен файл релиз-описания для GitHub Release:
  `docs/release-notes/v1.2.0-github-release.md` на основе изменений версии
  1.2.0.

### docs (readme)

- README обновлён под релиз 1.2.0: добавлен блок с ключевыми нововведениями,
  ссылками на changelog/release notes и уточнением структуры
  `store_manifest.json` и сценария миграции `backup -> migrate -> open`.

### category_manager

- В `CategoryManagerScreen` добавлен скролл для всей формы: контент обернут в
  `Scrollbar`, а `CustomScrollView` переведен на
  `AlwaysScrollableScrollPhysics`, чтобы экран прокручивался стабильно в любом
  состоянии списка/дерева.

### shared_widgets

- В `IconSourcePickerButton` кнопка очистки выбора иконки перенесена из нижнего
  ряда действий в `IconButton` в правом верхнем углу карточки.

### shared_ui

- В `SmoothButton` исправлены цвета для `disabled`-состояния у variant-кнопок
  (foreground/background/border стали state-aware) и добавлен явный цвет
  `CircularProgressIndicator` в режиме `loading`.

## 2026-04-16

### password_manager

- В форму пароля добавлен вызов встроенного генератора паролей: на экране
  `PasswordFormScreen` появилась кнопка генерации, открывающая
  `PasswordGeneratorWidget` в `WoltModalSheet`, с подстановкой выбранного пароля
  в поле формы и синхронизацией через `passwordFormProvider`.
- Для экрана формы пароля добавлены новые ключи локализации в модуле
  `dashboard_forms` (`passwordGeneratorTitle`, `generatePasswordAction`,
  `useGeneratedPassword`) для `ru` и `en`.

## 2026-04-14 (1.1.1)

### docs

- В AGENT.md добавлено обязательное правило для агента фиксировать изменения в
  корневом CHANGELOG.md после любых правок, а также группировать записи по
  фичам/модулям через подзаголовки.

### password_manager

- Добавлена настройка стора для управления инкрементом `usedCount` при
  копировании данных.
- При сохранении настроек стора через `store_settings_provider.dart` теперь явно
  обновляется `store_meta.modified_at`, даже если менялись только значения в
  `store_settings`.
- Логика копирования и условного `incrementUsage` вынесена в общий util
  `lib/features/password_manager/shared/utils/copy_usage_utils.dart`.
- Карточки в `lib/features/password_manager/dashboard/widgets/cards` переведены
  на общий util копирования вместо локального дублирования `Clipboard.setData` и
  `incrementUsage`.
- `view_screen.dart` в `lib/features/password_manager/forms` с существующим
  `incrementUsage` переведен на тот же общий util.
- Исправлен сброс текста при вводе в фильтрах
  `lib/features/password_manager/dashboard/widgets/dashboard_home/filter_sections`
  за счет безопасной синхронизации `TextEditingController` в `didUpdateWidget`.
- Убрано ложное кратковременное появление `MobileCloudSyncOverlay` при открытии
  неподключенного хранилища: overlay теперь ждет подтвержденный `binding`
  текущего store перед показом статуса проверки cloud sync.
- Уточнена логика `MobileCloudSyncOverlay`: удален fallback-показ отложенного
  hint без `binding`, из-за которого overlay мог появляться позже даже у store
  без cloud sync.

### db_core

- В `meta_touch_triggers.dart` добавлены триггеры для `store_settings`, чтобы
  изменения настроек стора тоже обновляли `store_meta.modified_at`.

### local_send

- Большие текстовые сообщения теперь отправляются через `WebRtcTransferService`
  чанками по control-channel вместо одного большого JSON-сообщения, чтобы не
  забивать буфер DataChannel и не подвешивать систему.

### cloud_sync

- HTTP-клиент облачной синхронизации теперь повторяет запрос после refresh
  токена при первом `unauthorized`/`expired_access_token`, чтобы
  Dropbox-операции не требовали второго ручного запроса.
- В `recent_database_card.dart` добавлен автоматический повтор проверки
  cloud-версии при первом auth/timeout-сбое, чтобы кнопка проверки новой версии
  не требовала второго ручного нажатия после простоя или истечения токена.

### security

- Проверено, что в модуле qr_scanner не логируются отсканированные данные; в
  логах остаются только служебные события и формат кода.
- В otp_form_provider удалено логирование данных из сканирования (сырой OTP URI
  и issuer) при обработке QR-кода.

### logs_viewer

- Добавлено копирование конкретной записи лога по долгому нажатию на карточку.
- Переработан UX фильтрации: чипы уровней, dropdown по тегам, корректная очистка
  и синхронизация поисковой строки.
- Поиск расширен по полям stack trace и additionalData; фильтр по тегу и поиск
  сделаны более устойчивыми к регистру и пробелам.
- Обновлен UI карточки лога: новая визуальная иерархия уровня/тегов, встроенная
  кнопка копирования, анимированное раскрытие деталей и форматирование
  дополнительных данных.
