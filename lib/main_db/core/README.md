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

- **Base**: Папка `base/` содержит базовые DAOs и общие mixin-ы для построения
  запросов.
- **Filters**: Папка `filters/` содержит filter DAOs для сложной фильтрации и
  поиска по спискам.
- **Security Policy**: Filter/Card DAOs **запрещено** читать секретные поля. Они
  возвращают только метаданные и флаги наличия секретов (`hasPassword`, `hasKey`
  и т.д.).
- **Item DAOs**: Содержат CRUD операции и **отдельные явные методы** для
  получения каждого секрета по требованию.
- **Public surface**: [daos.dart](./daos/daos.dart) агрегирует экспортируемые
  DAOs и фильтры для удобного импорта.

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

Прослойка между DAOs и Сервисами.

- Содержат логику сборки сложных DTO (например, ViewDto вместе с тегами и
  категориями).
- Инкапсулируют детали реализации Drift внутри себя.

### 5. [Services](./services/) — Бизнес-логика

Верхний уровень ядра БД.

- Координируют транзакции, историю изменений и связи.
- **Result Pattern**: Все публичные методы возвращают `DbResult<T, DBCoreError>`
  из пакета `result_dart`.
- Подробное описание в [README сервисов](./services/README.md).

### 6. [Errors](./errors/) — Система ошибок

Независимая от Flutter система обработки исключений.

- [db_error.dart](./errors/db_error.dart) — типизированные ошибки базы данных.
- [db_exception_mapper.dart](./errors/db_exception_mapper.dart) — преобразование
  SQLite-ошибок в `DBCoreError`.
- [db_constraint_registry.dart](./errors/db_constraint_registry.dart) — маппинг
  имен SQL-ограничений в человекочитаемые сообщения.

### 7. [Validators](./validators/) — Валидация

Логика проверки данных перед записью в БД, дополняющая SQL-ограничения.

### 8. [Migrations](./migrations/) — Миграции

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
