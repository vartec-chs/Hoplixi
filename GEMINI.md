# Hoplixi - Инструкции для проекта 🛡️

Добро пожаловать в проект **Hoplixi** — кроссплатформенное защищённое хранилище
данных (пароли, OTP, документы, заметки).

## Обзор проекта

Проект построен на **Flutter** с использованием **Rust** для
высокопроизводительных и безопасных операций (через `flutter_rust_bridge`).

### Технологический стек

- **UI:** Flutter (Material 3)
- **State Management:** Riverpod (3.x)
- **Database:** Drift (ORM) + SQLite3 Multiple Ciphers (`chacha20`, `sqlcipher`)
- **Navigation:** GoRouter
- **Serialization:** Freezed + JSON Serializable
- **Native Bridge:** flutter_rust_bridge (v2)
- **Localization:** Slang (i18n) + intl
- **Error Handling:** result_dart (Result/Either pattern)
- **Theming:** flex_color_scheme

## Архитектура

Проект следует принципам разделения ответственности и организован по слоям и
фичам.

### Структура `lib/`

- `core/`: Глобальные сервисы, утилиты, логгер, тема и константы.
- `features/`: Функциональные модули (home, password_manager, settings,
  cloud_sync и т.д.). Каждая фича содержит свои `models`, `providers`,
  `ui/screens`.
- `main_db/core`: Ядро базы данных (таблицы Drift, DAO, миграции).
- `main_db`: Основная логика для приложения работы с базой данных.
- `routing/`: Конфигурация GoRouter.
- `rust/`: Dart-сторона моста с Rust.
- `shared/`: Общие UI компоненты и виджеты-наблюдатели.
- `setup/`: Логика инициализации и запуска приложения.

### Структура хранилища (Vault)

Каждое хранилище — это папка с:

- `*.hpxdb`: Зашифрованная база данных SQLite.
- `store_manifest.json`: Метаданные и конфигурация ключей.
- `attachments/`: Зашифрованные вложения.

## Разработка и сборка

### Основные команды

- **Установка зависимостей:** `flutter pub get`
- **Генерация кода:** `dart run build_runner build --delete-conflicting-outputs`
  (или используйте `utils_bat/build_runner.bat`)
- **Генерация Rust-моста:** `flutter_rust_bridge_codegen generate` (обычно
  включено в процесс сборки)
- **Запуск (Dev):** `flutter run --flavor dev`
- **Анализ кода:** `flutter analyze`
- **Тестирование:** `flutter test`

### Скрипты (Windows)

- `utils_bat/build_prod.bat`: Сборка релизных версий для Windows/Android.
- `utils_bat/build_runner.bat`: Быстрый запуск генерации кода.

### Окружения (Flavors)

- `dev`: `com.hiplixi.app.dev` (Hoplixi Dev)
- `prod`: `com.hiplixi.app` (Hoplixi)

## Конвенции и правила

### Код и стиль

- **Effective Dart:** Строгое следование официальным гайдлайнам.
- **Immutability:** Всегда используйте `Freezed` для моделей данных и состояний
  провайдеров.
- **Logging:** Не используйте `print`. Используйте `loggerWithTag('TagName')` из
  `lib/core/logger/`.
- **UI:** Предпочитайте композицию виджетов. Используйте `const` конструкторы
  везде, где это возможно.
- **Async:** Используйте `AsyncValue` от Riverpod для обработки асинхронных
  состояний в UI.

### Changelog

- Все значимые изменения в коде, UI, логике, миграциях и документации
  обязательно отражайте в `CHANGELOG.md`.

### Работа с БД

- Новые таблицы добавляются в `lib/main_store/tables/`.
- Операции с данными описываются в `DAO` (`lib/main_store/dao/`).
- При изменении схемы БД не забывайте про миграции в
  `lib/main_store/migrations/`.

### Локализация

- Добавляйте строки в `lib/l10n/strings_ru.i18n.json` (и `en`).
- Запускайте `build_runner` для обновления сгенерированных файлов Slang.

### MCP сервера (инструменты для агентов)

- Вместо `dart` и `flutter` команд используй Dart MCP

## Подробная документация

- `docs-ai/agent-architecture-map.md`: Подробная карта расположения модулей.
- `docs-ai/rust-integration.md`: Особенности работы с Rust-мостом.
- `AGENTS.md`: Полная информация для агентов.
- `README.md`: Общая информация и инструкции по установке.
- `CHANGELOG.md`: История изменений и релизов.
