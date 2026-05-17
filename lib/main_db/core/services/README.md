# Core Services (Ядро сервисов базы данных)

Эта папка содержит бизнес-логику для работы с зашифрованным хранилищем (Vault).
Сервисы координируют работу между репозиториями, DAO, системой истории и связями
элементов.

## Основные сервисы

### [vault_items_state_service.dart](./vault_items_state_service.dart)

Общий сервис для изменения состояния vault_items:

- softDelete / recover
- archive / restoreArchived
- favorite / unfavorite
- pin / unpin

Сервис использует `VaultTypedViewResolver` для получения `oldView`, создаёт
snapshot before update и пишет event history. Entity services делегируют эти
операции данному сервису.

### [vault_item_mutation_service.dart](./vault_item_mutation_service.dart)

Сервис для выполнения атомарных изменений (мутаций), общих для всех типов
элементов.

- Управляет массовым обновлением тегов для элемента.
- Управляет сменой категории элемента.
- Обеспечивает транзакционность: создание снимка состояния (snapshot) перед
  изменением и запись события в историю.

### [vault_typed_view_resolver.dart](./vault_typed_view_resolver.dart)

Вспомогательный сервис-"резолвер" для получения типизированных View DTO.

- Принимает `itemId` и `VaultItemType`.
- Перенаправляет запрос в нужный репозиторий в зависимости от типа.
- Используется в системе истории для создания снимков состояния различных типов
  данных.

### [document_version_service.dart](./document_versions/document_version_service.dart)

Сервис для управления версиями документов.

- Создаёт новые версии документа через `createVersion`.
- Активирует выбранную версию через `activateVersion`.
- Возвращает список версий документа через `getVersions`.
- Возвращает детальную карточку версии через `getVersionDetail`.
- Возвращает текущую версию документа через `getCurrentVersion`.
- Удаляет неактивную версию через `deleteVersion`.

Сервис использует `DocumentVersionPolicyService` для валидации входных данных,
`DocumentVersionHashService` для расчёта агрегированного хэша страниц и набор
DAO из `MainStore` для работы с `document_items`, `document_pages`,
`document_versions`, `document_version_pages` и `vault_items`.

---

## Сущности (папка [entities](./entities/))

Каждый файл в этой папке реализует CRUD-операции для конкретного типа данных
(API ключи, пароли, заметки и т.д.). Все сервисы следуют единому паттерну:

1. Выполнение основной операции через репозиторий.
2. Управление связями (теги).
3. **Автоматическое логирование в историю**: создание snapshot-ов состояния и
   запись событий (created, updated, deleted, archived и т.д.).

Отдельно здесь же находится
[VaultCardFilterService](./entities/vault_card_filter_service.dart). Это фасад
только для чтения, который:

- получает нужный filter DAO из `MainStore` в момент вызова;
- предоставляет парные методы `get...` и `count...` для карточных фильтров;
- скрывает прямые обращения к `db.<entity>FilterDao` от feature-слоя.

В результате код, которому нужны списки карточек и их общее количество, работает
через один сервисный слой, а не через прямые DAO-вызовы.

В этой папке нет отдельного общего класса `EntityService`; вместо него лежат
типизированные сервисы сущностей, которые реализуют один и тот же сценарий для
каждого типа данных: репозиторий, связи, история и изменение состояния.

Список сервисов сущностей:

- `api_key_service.dart` — API ключи.
- `bank_card_service.dart` — Банковские карты.
- `certificate_service.dart` — Сертификаты.
- `contact_service.dart` — Контакты.
- `crypto_wallet_service.dart` — Криптокошельки.
- `document_service.dart` — Документы. (Нельзя использовать напрямую нужен
  сервис посредник который будет выполнять работу с файлами)
- `file_service.dart` — Файлы. (Нельзя использовать напрямую нужен сервис
  посредник который будет выполнять работу с файлами)
- `identity_service.dart` — Личные данные (Identity).
- `license_key_service.dart` — Лицензионные ключи.
- `loyalty_card_service.dart` — Карты лояльности.
- `note_service.dart` — Заметки.
- `otp_service.dart` — Одноразовые пароли (OTP/TOTP).
- `password_service.dart` — Пароли.
- `recovery_codes_service.dart` — Коды восстановления.
- `ssh_key_service.dart` — SSH ключи.
- `wifi_service.dart` — Настройки Wi-Fi.

---

## История (папка [history](./history/))

Система для отслеживания изменений и аудита безопасности.

### [vault_history_service.dart](./history/vault_history_service.dart)

Высокоуровневый фасад для работы с историей.

- Проверяет политику истории (включена ли она для данного хранилища).
- Координирует создание снимков (через `VaultSnapshotWriter`) и запись логов
  событий.

### [vault_snapshot_writer.dart](./history/vault_snapshot_writer.dart)

Низкоуровневый компонент для физической записи данных в таблицы истории.

- Содержит логику маппинга текущих View DTO в Companion-объекты таблиц истории.
- Умеет исключать секреты или связи из снимков при необходимости.

### [vault_event_history_service.dart](./history/vault_event_history_service.dart)

Сервис для записи простых событий (Action Log).

- Фиксирует кто, когда и какое действие совершил над элементом (создание,
  удаление, просмотр секрета и т.д.).

### [store_history_policy_service.dart](./history/store_history_policy_service.dart)

Управляет настройками истории для конкретного хранилища.

- Читает настройки: включена ли история, лимиты на количество записей, время
  хранения.

### [history_cleanup_service.dart](./history/history_cleanup_service.dart)

Сервис для автоматической очистки старых записей истории.

- (В разработке) Будет удалять записи, превышающие заданный возраст или лимит
  количества.

---

## Связи (папка [relations](./relations/))

Управление отношениями между объектами.

### [vault_item_relations_service.dart](./relations/vault_item_relations_service.dart)

Работает с "живыми" связями текущих элементов.

- Добавление/удаление/замена тегов.
- Смена категорий.
- Создание и управление перекрестными ссылками между элементами (Item Links).

### [snapshot_relations_service.dart](./relations/snapshot_relations_service.dart)

Управляет связями внутри системы истории.

- Создает копии тегов, категорий и ссылок в момент создания snapshot-а, чтобы
  история была самодостаточной и не зависела от удаления оригинальных тегов или
  категорий.
