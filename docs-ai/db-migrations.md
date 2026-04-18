# DB Migrations Guide (MainStore)

## Назначение

Этот гайд описывает, как добавлять **версионированные миграции** для Drift
`MainStore` через каркас в `lib/db_core/migrations/`.

Текущая архитектура:

- раннер: `lib/db_core/migrations/main_store_migration_runner.dart`
- runtime-контекст: `lib/db_core/migrations/main_store_migration_types.dart`
- version-файлы: `lib/db_core/migrations/versions/migration_v{N}.dart`
- вызов раннера: `MainStore.onUpgrade` в `lib/db_core/main_store.dart`

## Правила именования

- Один файл = одна версия схемы.
- Имя файла: `migration_v{N}.dart`.
- Имя функции: `migrateToV{N}`.

Пример для версии 3:

- файл: `migration_v3.dart`
- функция: `Future<void> migrateToV3(...)`

## Пошаговый процесс

1. Поднять версию схемы.

- Изменить `MainConstants.databaseSchemaVersion` в
  `lib/core/constants/main_constants.dart`.

1. Создать migration-файл.

- Путь: `lib/db_core/migrations/versions/migration_v{N}.dart`.
- Сигнатура:

```dart
Future<void> migrateToV3(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  // migration steps
}
```

1. Зарегистрировать миграцию в раннере.

- Открыть `lib/db_core/migrations/main_store_migration_runner.dart`.
- Добавить импорт нового файла.
- Добавить запись в `_mainStoreMigrationsByVersion`:

```dart
final Map<int, MainStoreMigration> _mainStoreMigrationsByVersion = {
  2: migrateToV2,
  3: migrateToV3,
};
```

1. Если в миграции нужны новые зависимости (таблицы/колонки/хуки).

- Добавить поля в `MainStoreMigrationRuntime`
  (`main_store_migration_types.dart`).
- Прокинуть их при создании runtime в `MainStore.onUpgrade` (`main_store.dart`).

1. Реализовать миграционные шаги.

- DDL через `migrator` (`addColumn`, `createTable`, etc).
- DML/SQL через `runtime.customStatement(...)`.
- Если затронута логика history-триггеров, вызвать
  `runtime.reinstallHistoryTriggers()`.

## Шаблон migration-файла

```dart
import 'package:drift/drift.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/db_core/migrations/main_store_migration_types.dart';

Future<void> migrateToV3(
  Migrator migrator,
  MainStoreMigrationRuntime runtime,
) async {
  const logTag = 'MainStoreMigration';
  logInfo('Running migration to schema version 3', tag: logTag);

  // Пример: добавить колонку
  // await migrator.addColumn(runtime.someTable, runtime.someColumn);

  // Пример: backfill
  // await runtime.customStatement('UPDATE ...');

  // Если изменены триггеры истории
  // await runtime.reinstallHistoryTriggers();

  logInfo('Schema version 3 migration completed', tag: logTag);
}
```

## Важные рекомендации

1. Делать миграции минимальными и атомарными.

- Один version-файл должен содержать только изменения своей версии.

1. Не использовать fallback как рабочую миграцию.

- В `MainStore.onUpgrade` есть dev-fallback с пересозданием схемы, потенциально
  деструктивный для данных.
- Для production добавляйте явные migration-скрипты для каждой новой версии.

1. Всегда писать backfill для новых обязательных данных.

- Если добавили новые поля, продумайте перенос старых значений.

1. Проверять совместимость старых данных.

- Не менять смысл enum/string значений без миграции данных.

## Чек-лист перед merge

1. Обновлена `databaseSchemaVersion`.

1. Создан `migration_v{N}.dart`.

1. Миграция зарегистрирована в раннере.

1. При необходимости расширен `MainStoreMigrationRuntime` и wiring в
   `MainStore`.

1. Выполнены проверки.

- Запуск приложения с базой старой версии (миграция проходит).
- Запуск на чистой базе (`onCreate`) без ошибок.
- Данные и индексы/триггеры корректны после апгрейда.

1. Обновлен `CHANGELOG.md`.

## Где смотреть примеры

- migration script: `lib/db_core/migrations/versions/migration_v2.dart`
- runner: `lib/db_core/migrations/main_store_migration_runner.dart`
- runtime context: `lib/db_core/migrations/main_store_migration_types.dart`
- integration point: `lib/db_core/main_store.dart`
