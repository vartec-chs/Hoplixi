# Добавление новой сущности хранилища (по шаблону `password`)

Практическая инструкция для быстрого внедрения новых типов сущностей (например:
`wifi`, `identity`, `license`, `apiKey`) в архитектуру Hoplixi.

> Базовый принцип проекта: **Table-Per-Type**
>
> - Общие поля сущности хранятся в `vault_items`
> - Специфичные поля хранятся в отдельной таблице `<entity>_items`
> - Для истории используется `vault_item_history` + `<entity>_history`

---

## Этап 0. Спроектировать модель сущности

Перед кодом зафиксируй:

- `entityId` для Dashboard (пример: `passwords`, `otps`)
- `vaultType` для БД (пример: `password`, `otp`)
- список специфичных полей
- обязательные поля и `CHECK`-ограничения
- что попадает в карточку списка (`*CardDto`)
- что нужно для формы create/edit/view

Рекомендуемый нейминг:

- таблица: `<entity>_items`
- history-таблица: `<entity>_history`
- CRUD DAO: `<Entity>Dao`
- Filter DAO: `<Entity>FilterDao`
- DTO: `<entity>_dto.dart`, `<entity>_history_dto.dart`
- фильтр: `<entities>_filter.dart`

---

## Этап 1. Добавить enum-типы

Файл: `lib/main_store/models/enums/entity_types.dart`

1. Добавь новый `VaultItemType`.
2. Добавь маппинг в `VaultItemTypeX.value` и `VaultItemTypeX.fromString`.
3. Если сущность участвует в категориях/тегах — добавь новый
   `CategoryType`/`TagType` и их extension-мэппинг.

Также обнови Dashboard enum:

- `lib/features/password_manager/dashboard/models/entity_type.dart`
  - новый `EntityType`
  - `fromId`, `toTagType`, `toCategoryType`

---

## Этап 2. Создать таблицы Drift

Минимум 2 таблицы:

1. `lib/main_store/tables/<entity>_items.dart`
   - `itemId` как PK + FK -> `vault_items.id` (`ON DELETE CASCADE`)
   - только специфичные поля
   - `tableName`
   - `customConstraints` (если нужны)

2. `lib/main_store/tables/<entity>_history.dart`
   - `historyId` как PK + FK -> `vault_item_history.id`
   - snapshot специфичных полей

И подключи их в экспорты:

- `lib/main_store/tables/index.dart`

---

## Этап 3. Подключить таблицы и DAO в MainStore

Файл: `lib/main_store/main_store.dart`

1. Добавь новые таблицы в `@DriftDatabase(tables: [...])`.
2. Добавь DAO в `@DriftDatabase(daos: [...])`.
3. При необходимости добавь `watchDataChanged` readsFrom.
4. Добавь/обнови индексы под типичные `WHERE`/`ORDER BY`, но SQL индексы храни в
   отдельном файле (рекомендуемо: `lib/main_store/indexes/index.dart`), а в
   `_installIndexes()` только разворачивай общий список (например
   `for (final sql in allMainStoreIndexes)`).

> Рекомендация по структуре:
>
> - `lib/main_store/indexes/index.dart` — exports
> - `lib/main_store/indexes/main_store_indexes.dart` —
>   `const List<String> allMainStoreIndexes`
> - `main_store.dart` — только выполнение SQL из списка

Если это миграция существующей БД:

- увеличь `databaseSchemaVersion` в `lib/core/constants/main_constants.dart`
- добавь `onUpgrade` шаги для старых баз

---

## Этап 4. Реализовать CRUD DAO

Пример-референс: `lib/main_store/dao/password_dao.dart`

Создай `lib/main_store/dao/<entity>_dao.dart`:

- DAO должен `implements BaseMainEntityDao`
  (`lib/main_store/models/base_main_entity_dao.dart`)
- обязательно реализуй: `softDelete`, `restoreFromDeleted`, `permanentDelete`,
  `toggleFavorite`, `togglePin`, `toggleArchive`, `incrementUsage`

- `getAll...()` (JOIN `vault_items` + `<entity>_items`)
- `getById()`
- `watchAll...()`
- `create...()`
  - вставка в `vault_items` (`type: VaultItemType.<newType>`)
  - вставка в `<entity>_items`
  - синхронизация тегов через `vaultItemDao`, если нужно
- `update...()`
  - обновление общих полей в `vault_items`
  - обновление специфичных полей в `<entity>_items`
- при необходимости `getSensitiveFieldById()` для безопасного копирования

Подключи DAO в:

- `lib/main_store/dao/index.dart`
- `lib/main_store/provider/dao_providers.dart` (обязательно добавить
  `FutureProvider` для CRUD DAO, history DAO и filter DAO)

---

## Этап 5. Создать DTO и filter-модель

### DTO

Файл: `lib/main_store/models/dto/<entity>_dto.dart`

Обычно нужны:

- `Create<Entity>Dto`
- `Update<Entity>Dto`
- `Get<Entity>Dto` (опционально)
- `<Entity>CardDto implements BaseCardDto`

Обнови экспорт:

- `lib/main_store/models/dto/index.dart`

### Filter model

Файл: `lib/main_store/models/filter/<entities>_filter.dart`

- `@freezed` фильтр с полем `base: BaseFilter`
- enum сортировки `<Entities>SortField`
- `create(...)` с нормализацией входных строк
- helper `hasActiveConstraints`

Обнови экспорт:

- `lib/main_store/models/filter/index.dart`

---

## Этап 6. Реализовать Filter DAO

Референс: `lib/main_store/dao/filters_dao/password_filter_dao.dart`

Создай `lib/main_store/dao/filters_dao/<entity>_filter_dao.dart`:

- `implements FilterDao<<Entities>Filter, <Entity>CardDto>`
- `getFiltered(filter)`
  - JOIN с `vault_items` и связанными таблицами
  - `_buildWhereExpression` (base + entity specific)
  - `_buildOrderBy`
  - пагинация через `limit/offset`
  - маппинг в `<Entity>CardDto`
- `countFiltered(filter)`

Подключи экспорт:

- `lib/main_store/dao/filters_dao/filters_dao.dart`

---

## Этап 7. Подключить list/filter провайдеры Dashboard

### Провайдер фильтра

Создай:

- `lib/features/password_manager/dashboard/providers/filter_providers/<entity>_filter_provider.dart`

По шаблону `password_filter_provider.dart`:

- слушает `baseFilterProvider`
- хранит entity-specific поля
- умеет `reset/clear/update`

Подключи в index провайдеров фильтров.

### Интеграция в `paginatedListProvider`

Файл: `lib/features/password_manager/dashboard/providers/list_provider.dart`

Обнови switch-блоки:

- подписки `_subscribeToTypeSpecificProviders()`
- выбор DAO `_daoForType()`
- сборка фильтра `_buildFilter()`
- tab-фильтры `_getTabFilter(...)`
- операции действий (`toggle/delete/restore/permanentDelete`) через сервисы

### Переключение типа сущности в UI

Обязательно подключи новый тип к выпадающему выбору:

- `lib/features/password_manager/dashboard/widgets/dashboard_home/entity_type_dropdown.dart`
  - `EntityTypeCompactDropdown`
  - `EntityTypeFullDropdown` (описание нового типа)

---

## Этап 8. Карточки для общего списка (grid/list)

Создай:

- `lib/features/password_manager/dashboard/widgets/cards/<entity>/<entity>_grid.dart`
- `lib/features/password_manager/dashboard/widgets/cards/<entity>/<entity>_list_card.dart`

Требования:

- DTO: `<Entity>CardDto`
- коллбэки как у `PasswordListCard`/`PasswordGridCard`
- действия copy/open/edit/history при необходимости
- единый стиль через shared card-компоненты проекта

Интеграция:

- `lib/features/password_manager/dashboard/screens/dashboard_home_builders.dart`
  - добавить ветки в `buildListCardFor(...)` и grid builder

---

## Этап 9. UI формы create/edit/view

Структура как у `password_form`:

- `lib/features/password_manager/forms/<entity>_form/models/<entity>_form_state.dart`
- `lib/features/password_manager/forms/<entity>_form/providers/<entity>_form_provider.dart`
- `lib/features/password_manager/forms/<entity>_form/screens/<entity>_form_screen.dart`
- `lib/features/password_manager/forms/<entity>_form/screens/<entity>_view_screen.dart`

Что обязательно:

- `initForCreate`, `initForEdit`, `save`
- валидация полей в provider + вывод ошибок в `TextFormField`/полях формы
- общие ошибки сохранения/операций показывать через `Toaster.error(...)`
- View-экран должен быть максимально информативным
- секретные поля в View не грузить автоматически в открытом виде: получать
  отдельным DAO-запросом по явному действию пользователя (например, тап/кнопка
  «Показать» или «Скопировать»)
- `dataRefreshTriggerProvider` после create/update/delete

Интеграция роутинга-обёрток:

- `lib/features/password_manager/dashboard/widgets/entity_add_edit.dart`
- `lib/features/password_manager/dashboard/widgets/entity_view.dart`

---

## Этап 10. Фильтры в модальном окне

Файл: `lib/features/password_manager/dashboard/widgets/modals/filter_modal.dart`

Добавь новый `EntityType` во все relevant switch:

- инициализация локальных фильтров
- сохранение/применение
- очистка
- секции entity-specific полей
- маппинг `CategoryType` и `TagType`

Отдельно проверь экспорт и секцию UI для новой сущности:

- `lib/features/password_manager/dashboard/widgets/dashboard_home/filter_sections/filter_sections.dart`
  - добавь export новой секции
- создай отдельный виджет секции специфичных фильтров (по шаблону
  `password_filter_section.dart`)

---

## Этап 11. History (рекомендуется для parity с password/otp)

1. Создай SQL-триггеры:

- `lib/main_store/triggers/<entities>_triggers.dart`
  - create/drop lists

2. Экспортируй триггеры:

- `lib/main_store/triggers/index.dart`
  - обязательно отдельно держи history-trigger файлы и timestamps-trigger файлы,
    и экспортируй оба набора

3. Подключи в `MainStore._installHistoryTriggers()`:

- drop + create в общие списки
- убедись, что параллельно подключены списки timestamps-триггеров
  (`allTimestampDropTriggers`, `allInsertTimestampTriggers`,
  `allModifiedAtTriggers`) и триггеры обновления meta (`allMetaTouch...`)

4. Реализуй history DAO:

- `lib/main_store/dao/history_dao/<entity>_history_dao.dart`
- DTO: `lib/main_store/models/dto/<entity>_history_dto.dart`
- экспорт в `dao/index.dart` и `models/dto/index.dart`

5. Подключи history UI/list provider при необходимости:

- `lib/features/password_manager/history/providers/history_list_provider.dart`
- `lib/features/password_manager/history/ui/widgets/history_item_card.dart`
  - карточка `HistoryItemCard` должна быть максимально информативной: действие,
    заголовок, ключевые изменённые поля, метки времени, визуальные статусы
    (created/modified/deleted)

---

## Этап 12. Генерация кода и проверка

После изменений запусти:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Минимальные проверки:

1. Создание новой сущности.
2. Редактирование + повторное открытие.
3. Поиск/фильтрация/сортировка/пагинация в Dashboard.
4. Теги/категории/заметки (если есть связи).
5. Карточки list+grid.
6. View screen + copy actions.
7. История изменений (если включена).

---

## Быстрый чеклист «готово к merge»

- [ ] Добавлен новый `VaultItemType` и `EntityType`
- [ ] Созданы `<entity>_items` и `<entity>_history`
- [ ] Подключены в `tables/index.dart` и `main_store.dart`
- [ ] SQL-индексы вынесены в отдельный файл и подключены единым списком в
      `main_store.dart`
- [ ] Реализован `<Entity>Dao` (CRUD)
- [ ] `<Entity>Dao` реализует `BaseMainEntityDao`
- [ ] Реализован `<Entity>FilterDao` + `<Entities>Filter`
- [ ] Созданы DTO (`Create/Update/Card/...`)
- [ ] Добавлены provider-ы DAO (CRUD/history/filter) в `dao_providers.dart`
- [ ] Интегрировано в `list_provider.dart`
- [ ] Добавлены list/grid карточки
- [ ] Добавлены form/view экраны (View с ленивой загрузкой секретных полей)
- [ ] Обновлены `entity_add_edit.dart` и `entity_view.dart`
- [ ] Обновлён `filter_modal.dart` и добавлена секция в `filter_sections.dart`
- [ ] Обновлён `EntityTypeCompactDropdown`/`EntityTypeFullDropdown`
- [ ] (Опционально, но желательно) history triggers + history dao
- [ ] Подключены history + timestamps trigger наборы в MainStore
- [ ] `HistoryItemCard` информативно отображает изменения
- [ ] Сгенерирован код `build_runner`
- [ ] Пройдены smoke-проверки UI + фильтрации

---

## Практический совет по скорости внедрения

Для новой сущности проще идти по стратегии **Copy-Adapt-Trim**:

1. Копируешь `password`-цепочку файлов.
2. Меняешь названия и поля под новую доменную модель.
3. Удаляешь всё лишнее (OTP-связи, миграции, спец-поля), что не нужно новой
   сущности.
4. Только после этого подключаешь в switch-реестры Dashboard/провайдеров.

Так меньше риск пропустить один из обязательных switch-блоков и получить
«частично рабочую» сущность.
