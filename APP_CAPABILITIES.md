# Hoplixi: актуальная карта возможностей

Файл собран по AGENTS.md, README.md, CHANGELOG.md, docs-ai и текущему роутингу.
Цель: зафиксировать реальную карту экранов, настроек и рабочих подсистем без
обобщений и пропусков.

## 1. Что такое Hoplixi

Hoplixi это кроссплатформенное защищенное локальное хранилище данных в формате
vault. Внутри одного хранилища живут пароли, OTP, документы, файлы, ключи,
карты, заметки и другие чувствительные записи.

Поддерживаемые платформы:

- Android
- iOS
- Windows
- Linux
- macOS

## 2. Карта экранов и маршрутов

### Старт и onboarding

- `/splash` - стартовый экран-заглушка для bootstrap и перехода в рабочий
  сценарий.
- `/setup` - первый запуск и первоначальная настройка приложения.
- `/home` - домашний хаб с быстрыми входами в vault lifecycle, LocalSend, Cloud
  Sync и служебные разделы.

### Vault lifecycle

- `/create-store` - создание нового локального хранилища.
- `/open-store` - открытие существующего хранилища.
- `/open-store/cloud-import` - привязка или импорт хранилища через Cloud Sync.
- `/lock-store` - ручная блокировка открытого vault.
- `/close-store-sync` - сценарий синхронизации перед закрытием хранилища.
- `/archive-store` - архивирование и экспорт хранилища.

### Dashboard и сущности vault

- `/dashboard` - корневой маршрут dashboard; redirect ведет в default entity.
- `/dashboard/:entity` - рабочий экран сущности.
- `/dashboard/:entity/add` - создание записи.
- `/dashboard/:entity/edit/:id` - редактирование записи.
- `/dashboard/:entity/view/:id` - просмотр записи.
- `/dashboard/:entity/history/:id` - история конкретной записи.
- `/dashboard/:entity/categories` - менеджер категорий для сущности.
- `/dashboard/:entity/categories/add` - добавление категории.
- `/dashboard/:entity/categories/edit/:id` - редактирование категории.
- `/dashboard/:entity/tags` - менеджер тегов для сущности.
- `/dashboard/:entity/tags/add` - добавление тега.
- `/dashboard/:entity/tags/edit/:id` - редактирование тега.
- `/dashboard/:entity/icons` - менеджер иконок для сущности.
- `/dashboard/:entity/icons/add` - добавление иконки.
- `/dashboard/:entity/icons/edit/:id` - редактирование иконки.
- `/dashboard/:entity/import` - импорт для password и OTP сценариев.
- `/dashboard/passwords/duplicates` - поиск и анализ дубликатов паролей.
- `/dashboard/notes/graph` - граф связей для заметок.
- `/dashboard/import/keepass` - отдельный KeePass import flow.

### Cloud Sync

- `/cloud-sync` - экран-полигон Cloud Sync Center.
- `/cloud-sync/storage` - storage sandbox для cloud API.
- `/cloud-sync/app-credentials` - управление OAuth app credentials.
- `/cloud-sync/auth-tokens` - список и управление OAuth токенами.
- `/cloud-sync/auth/progress` - progress route для активного OAuth flow.

### LocalSend

- `/localsend/send` - экран обнаружения и подготовки отправки.
- `/localsend/transfer` - экран активной передачи.
- `/localsend/history` - история отправок и получений.

### Служебные экраны

- `/settings` - системные и продуктовые настройки.
- `/logs` - просмотр логов и crash reports.
- `/component-showcase` - showcase UI-компонентов и дизайн-паттернов.
- `/crypt-test` - технический экран для проверки crypt API.
- `/about/licenses` - экран лицензий зависимостей.

## 3. Что умеет dashboard

Dashboard покрывает основной домен vault и работает как навигационный центр для
записей и управляющих сущностей.

Поддерживаемые типы данных:

- пароли
- OTP и 2FA
- заметки
- банковские карты
- документы
- файлы
- контакты
- API-ключи
- SSH-ключи
- сертификаты
- криптокошельки
- Wi-Fi сети
- личные данные
- лицензионные ключи
- recovery codes
- карты лояльности

Организация данных и работа с контентом:

- фильтрация по типам сущностей
- поиск по данным vault
- фильтрация по категориям и тегам
- категории, теги и кастомные иконки на уровне сущностей
- пользовательские SVG icon packs с импортом из zip и папок
- избранное, pinned, архив и soft delete
- счетчик использования и recent score
- массовые действия в dashboard через multi-select

Работа с паролями и OTP:

- встроенный генератор паролей
- поддержка OTP / 2FA
- QR-сканирование для удобного ввода секретов
- импорт паролей и OTP из отдельных потоков
- анализ дубликатов паролей

История и восстановление:

- фиксация create / modify / delete действий
- общая и типоспецифичные history tables
- просмотр истории изменений по записи
- поиск по истории
- восстановление из истории

Обмен и экспорт:

- отправка выбранных полей записи через `share_plus`
- выбор набора полей в модалке перед отправкой
- сохранение выбранных полей в in-memory LocalSend-буфер для последующей
  отправки как текста

## 4. LocalSend

LocalSend - отдельный модуль локального обмена данными между устройствами в
локальной сети.

Что доступно:

- обнаружение устройств в LAN
- signaling между устройствами
- WebRTC-передача файлов
- передача текста
- отправка архива хранилища
- отправка зашифрованного пакета OAuth-токенов Cloud Sync
- подтверждение входящих подключений
- история отправок и получений
- обработка ошибок, отмены и разрыва соединения

Практические сценарии LocalSend:

- отправка store archive на другое устройство
- перенос cloud sync токенов между устройствами через защищенный пакет
- прием входящего архива и его дальнейший импорт

## 5. Cloud Sync

Cloud Sync реализован как snapshot sync текущего store в облако, а не как
построчная синхронизация базы.

Что уже работает в архитектуре и UI:

- OAuth-авторизация облачных провайдеров
- хранение OAuth токенов и refresh при необходимости
- единый storage-слой поверх разных облаков
- привязка локального store к облачному аккаунту
- upload / download snapshot
- сравнение локальной и удаленной ревизии
- конфликт версий и ручной выбор варианта
- прогресс синхронизации для UI
- сигнал о необходимости переавторизации
- синхронизация перед закрытием хранилища

Экранные точки Cloud Sync:

- `CloudSyncPlaygroundScreen` - центр управления и тестовый полигон.
- `CloudSyncStorageScreen` - ручной sandbox для операций с облачным storage.
- `AppCredentialsScreen` - создание и редактирование OAuth app credentials.
- `AuthTokensScreen` - просмотр и управление сохраненными OAuth токенами.
- `AuthProgressScreen` - отдельный экран активного OAuth flow.

Провайдеры:

- Dropbox
- Google Drive
- OneDrive
- Yandex Disk

Тонкости реализации:

- auth flow умеет выбирать стратегию под platform/provider.
- desktop использует browser-based OAuth с loopback flow.
- mobile использует AppAuth, а Google идет через Google Sign-In.
- storage-layer описывает операции folder list, create, upload, download, copy,
  move и delete.
- runtime storage-реализация сейчас есть для Yandex Drive; остальные провайдеры
  присутствуют в metadata, auth и storage-contract, но не равны по зрелости.

## 6. Настройки приложения

Настройки собраны в одном экране `/settings` и разбиты на секции.

### Внешний вид

- выбор темы приложения через ThemeMode

### Общие

- переключение языка
- автозапуск при старте системы на desktop

### Безопасность

- биометрическая аутентификация
- защита dashboard от скриншотов и записи экрана
- blur overlay в app switcher и recents
- таймаут автоблокировки

### Синхронизация

- авто-отправка snapshot при закрытии, если локальная версия новее
- отображение времени последней синхронизации

### Резервное копирование

- автоматическое резервное копирование
- выбор режима бэкапа: только БД, только зашифрованные файлы или полный бэкап
- настройка интервала автобэкапа
- ограничение числа бэкапов на один store
- путь для backup хранится в prefs, но не вынесен отдельной активной плиткой

### Dashboard

- включение или отключение анимаций dashboard
- glass-эффект нижней навигации на mobile
- выбор цвета подсветки нижней навигации
- порог анимированных элементов для списка и сетки

Что есть в prefs, но не выведено как активный пункт текущего UI:

- `autoSyncEnabled`
- смена PIN как отдельный сценарий
- ручной запуск backup из отдельной плитки

## 7. Безопасность

- шифрование основной БД через SQLite3 Multiple Ciphers
- выбор алгоритма шифрования при создании vault: chacha20 или sqlcipher
- отдельное шифрование файлов и вложений
- мастер-пароль для доступа к хранилищу
- биометрия, PIN и авто-блокировка
- защищенное хранение чувствительных данных и секретов
- write policy для чувствительных настроек
- защита dashboard от screen capture и дополнительный blur overlay

## 8. Файлы, документы и структура хранилища

В проекте есть отдельные подсистемы для файлов и документов, включая хранение
метаданных, страниц документов и связанного OCR-текста.

Текущая структура единицы хранилища:

```text
store_name/
|   store_manifest.json
|   attachments_manifest.json
|   store_name.hplxdb
|---attachments_decrypted/
|---attachments/
```

Назначение файлов:

- store_manifest.json - метаданные store, совместимость версий и keyConfig
- attachments_manifest.json - ревизия, хэш и список файлов вложений для snapshot
  sync
- \*.hplxdb - зашифрованная SQLite3 Multiple Ciphers база

## 9. Технические подсистемы

Ключевые внутренние модули:

- `lib/db_core` для Drift, SQLite и жизненного цикла store
- `lib/features/password_manager` для dashboard, форм и managers
- `lib/features/cloud_sync` для auth, storage и snapshot sync
- `lib/features/local_send` для локального обмена
- `lib/features/custom_icon_packs` для SVG icon packs
- `lib/features/password_generator` для генерации паролей
- `lib/features/logs_viewer` для просмотра логов и crash reports
- `lib/features/multi_window` для multi-window сценариев
- `lib/core/app_prefs` для типобезопасных настроек
- `lib/core/logger` для логирования и crash-репортов
- `lib/routing` на go_router
- `lib/shared/ui` для общих UI-компонентов
- `packages/file_crypto` + Rust интеграция для криптографических операций
- `packages/cloud_storage_sdk` для облачного слоя
- `packages/card_scanner` для сканирования карт
- `packages/secure_clipboard_win` для безопасного clipboard на Windows

## 10. Что заметно изменилось в последних релизах

- добавлены custom SVG icon packs и новый picker
- добавлен режим массовых действий в dashboard
- усилена модель совместимости store_manifest и сценарий backup -> migrate ->
  open
- добавлен каркас версионированных миграций db_core
- расширена документация агента и архитектурная карта
- переработаны Cloud Sync Center и экранные потоки auth / storage
- добавлен и уточнен LocalSend-поток для архива store и cloud sync токенов

## 11. Итог

Hoplixi уже представляет собой полноценную платформу защищенного локального
хранилища с развитым vault-доменом, history, cloud snapshot sync, LocalSend,
сильной security-базой и отдельными экранами для управления настройками,
OAuth-контрактами и техническими сценариями.
