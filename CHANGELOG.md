# CHANGELOG

## 2026-04-21

### db_core (opening state)

- Удалён отдельный `mainStoreOpeningOverlayProvider`: глобальный overlay
  открытия хранилища теперь определяется напрямую по `DatabaseState`, а не по
  побочному boolean-провайдеру.
- В `DatabaseStatus` добавлено явное состояние `opening`; `MainStoreAsyncNotifier`
  переводит хранилище в него в начале `openStore(...)`, а migration-flow
  использует тот же статус уже на этапе `backup -> migrate -> open`.
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
