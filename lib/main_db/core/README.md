# Hoplixi Core Database Layer (`lib/main_db/core`)

Данная директория содержит ядро базы данных проекта Hoplixi. Оно спроектировано
как независимый модуль (Pure Dart), который может использоваться как во
Flutter-приложении, так и в CLI-утилитах.

## Важно

Обновление этого README и поддержание его в актуальном состоянии является
критически важным для обеспечения понимания архитектуры ядра базы данных всеми
участниками команды. После внесения изменений в структуру баз данных, логику
DAOs или сервисов, пожалуйста,обновляйте этот документ, чтобы он отражал текущую
реализацию.

## Точка входа

### [MainStore](./main_store.dart) — сборка ядра БД

- `main_store.dart` объединяет таблицы, DAOs, индексы и триггеры в единую
  Drift-конфигурацию.
- Класс `MainStore` должен оставаться тонким: orchestration и прикладная логика
  выносятся в `services/`.
- Публичные поверхности ядра собраны в `tables/tables.dart`, `daos/daos.dart` и
  `models/dto/dto.dart`.

## Архитектурные слои

### 1. [Tables](./tables/) — Определение схемы (DDL)

Низкоуровневое описание таблиц Drift, индексов и триггеров.

- Каждая сущность разделена на `*_items.dart` (текущие данные) и
  `*_history.dart` (таблицы для snapshot-ов истории).
- Содержит SQL-триггеры для обеспечения целостности данных и автоматического
  ведения истории.
- [all_table_indexes.dart](./tables/all_table_indexes.dart) — агрегатор всех
  индексов
- [all_table_triggers.dart](./tables/all_table_triggers.dart) — агрегатор всех
  триггеров.

### 2. [DAOs](./daos) — Data Access Objects

Объекты доступа к данным, инкапсулирующие конкретные SQL/Drift запросы.

- **Base**: Папка `base/` содержит простые, "тупые" DAOs, которые делают базовые
  операции чтения и записи без orchestration-логики. Внутри она уже разделена по
  доменам (`api_key/`, `contact/`, `document/`, `system/` и т.д.).
- **Filters**: Папка `filters/` содержит более "умные" filter DAOs: они собирают
  параметры запроса, применяют фильтрацию, сортировку и поиск по спискам.
- **Security Policy**: Filter/Card DAOs **запрещено** читать секретные поля. Они
  возвращают только метаданные и флаги наличия секретов (`hasPassword`, `hasKey`
  и т.д.).
- **Item DAOs**: Содержат CRUD операции и **отдельные явные методы** для
  получения каждого секрета по требованию.
- **Public surface**: [daos.dart](./daos/daos.dart) агрегирует экспортируемые
  DAOs и фильтры для удобного импорта; отдельный агрегатор
  [filters/daos.dart](./daos/filters/daos.dart) используется для filter-слоя.

### 3. [Models](./models/) — Модели данных, DTO и мапперы

- **DTO**: Основная модельная прослойка для чтения и записи данных.
  - `dto/` содержит DTO текущих сущностей, общие базовые DTO
    (`vault_item_base_dto.dart`, `store_dto.dart`, `file_metadata_dto.dart`),
    системные DTO и утилиты (`converters.dart`, `filter_meta_dto.dart`,
    `field_update.dart`).
  - `dto_history/` содержит snapshot DTO для истории изменений.
  - `filters/` содержит модели фильтрации, сортировки и поисковых параметров.
  - `graph_data.dart`, `db_ciphers.dart` и `icon_source.dart` содержат
    вспомогательные модельные типы, используемые ядром БД и UI-слоями.
- **Mappers**: В `mappers/` лежат extension-методы, преобразующие Drift Data
  Classes в DTO для текущих данных и history snapshot-ов.
- **Public surface**: `dto/dto.dart` агрегирует экспортируемые DTO для удобного
  импорта из других слоёв.

#### History-фильтры для `VaultSnapshotsHistory` и `VaultEventsHistory`

Для таблиц истории используются отдельные модели фильтрации:

- `VaultSnapshotHistoryFilter` — фильтр для `vault_snapshots_history`
  (`VaultSnapshotsHistory`). Используется, когда нужен список restorable
  snapshot-ов: по item, типу, action, категории, состояниям item на момент
  snapshot-а, временным диапазонам, `usedCount` и `recentScore`.
- `VaultEventHistoryFilter` — фильтр для `vault_events_history`
  (`VaultEventsHistory`). Используется для audit/event-ленты: по item, action,
  типу item, actor type, категории, связанному snapshot и времени события.

Используйте фабрики `.create(...)`: они нормализуют строковые параметры
(`trim`), убирают пустые значения из списков и дедуплицируют коллекции. `query`
предназначен для поиска по `name` / `description`. History-фильтры не должны
возвращать секретные поля; они работают только с metadata/history-таблицами.

Пример фильтра snapshot-истории:

```dart
final filter = VaultSnapshotHistoryFilter.create(
  itemId: itemId,
  actions: const [
    VaultEventHistoryAction.created,
    VaultEventHistoryAction.updated,
    VaultEventHistoryAction.restored,
  ],
  types: const [VaultItemType.password],
  isDeleted: false,
  historyCreatedAfter: from,
  historyCreatedBefore: to,
  sortBy: SnapshotHistorySortBy.historyCreatedAt,
  sortDirection: SortDirection.desc,
  limit: 50,
);
```

Пример фильтра event-истории:

```dart
final filter = VaultEventHistoryFilter.create(
  itemIds: itemIds,
  actions: const [
    VaultEventHistoryAction.updated,
    VaultEventHistoryAction.deleted,
    VaultEventHistoryAction.recovered,
  ],
  actorTypes: const [
    VaultHistoryActorType.user,
    VaultHistoryActorType.sync,
  ],
  hasSnapshot: true,
  eventCreatedAfter: from,
  eventCreatedBefore: to,
  sortBy: EventHistorySortBy.eventCreatedAt,
  sortDirection: SortDirection.desc,
  limit: 100,
);
```

### 4. [Repositories](./repositories/) — Репозитории

Репозитории объединяют несколько DAOs для выполнения задач уровня домена.

- Содержат логику сборки сложных DTO (например, ViewDto вместе с тегами и
  категориями).
- Инкапсулируют детали реализации Drift внутри себя.

### 5. [Services](./services/) — Бизнес-логика

Верхний уровень ядра БД.

- Сервисы объединяют repositories и DAOs для выполнения сложных операций.
- Координируют транзакции, историю изменений и связи.
- Основные фасады лежат в корне `services/`: `vault_items_state_service.dart`,
  `vault_item_mutation_service.dart` и `vault_typed_view_resolver.dart`.
- Папка `entities/` содержит CRUD-сервисы по типам данных, `history/` — запись
  snapshot/event history и политику истории, `relations/` — текущие и
  snapshot-связи.
- **Result Pattern**: Все публичные методы возвращают `DbResult<T, DBCoreError>`
  из пакета `result_dart`.
- Подробное описание в [README сервисов](./services/README.md).

### 6. [Errors](./errors/) — Система ошибок

Независимая от Flutter система обработки исключений.

- [db_result.dart](./errors/db_result.dart) — typed result-обёртка для публичных
  методов ядра.
- [db_error.dart](./errors/db_error.dart) — типизированные ошибки базы данных.
- [db_exception_mapper.dart](./errors/db_exception_mapper.dart) — преобразование
  SQLite-ошибок в `DBCoreError`.
- [db_constraint_registry.dart](./errors/db_constraint_registry.dart) — маппинг
  имен SQL-ограничений в человекочитаемые сообщения.

### 7. [Config](./config/) — Конфигурация ядра

Параметры и ключи, которые используются внутри `core` для работы со store-level
настройками.

- [store_settings_keys.dart](./config/store_settings_keys.dart) — перечисление
  canonical-ключей настроек хранилища и маппинг между enum и storage key.

### 8. [Validators](./validators/) — Валидация

Логика проверки данных перед записью в БД, дополняющая SQL-ограничения.

### 9. [Migrations](./migrations/) — Миграции

Управление версиями схемы базы данных.

## Основные принципы (Mandates)

1. **Безопасность (Secrets Isolation)**: Секретные поля (пароли, ключи,
   приватные ключи) никогда не должны попадать в результаты запросов списков или
   фильтров.
2. **Целостность (History)**: Любое изменение данных (insert, update, delete)
   должно сопровождаться созданием snapshot-а в таблицах истории и записью
   события в аудит-лог.
3. **Изоляция (Pure Dart)**: Внутри `core/` запрещено импортировать Flutter,
   Riverpod или App-level классы (например, `AppError`).
4. **Транзакционность**: Сложные операции, затрагивающие несколько таблиц
   (например, создание элемента + привязка тегов + запись истории), всегда
   выполняются внутри транзакции.

---

_Этот файл является основным руководством для AI-агентов и разработчиков при
работе с ядром базы данных._
