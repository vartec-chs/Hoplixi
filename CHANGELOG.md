# CHANGELOG

## 2026-04-19

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
