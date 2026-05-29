# ТЗ для AI-агентов: перевод `vault_db/core` на API-формат

## Цель

Сформировать стабильный API-слой поверх `lib/vault_db/core`, чтобы feature/UI
код работал через явные фасады и контракты, а не через прямой доступ к Drift
DAO, `VaultDB`, repositories или внутренним services.

## Границы задачи

Входит:

- проектирование public API surface для `vault_db/core`;
- разделение read-only API и mutation API;
- стабилизация request/response DTO для feature-слоя;
- единая обработка `DBCoreError` через `DBResult`;
- закрытие прямого доступа feature-слоя к DAO/repository internals.

Не входит без отдельного решения:

- изменение схемы БД;
- миграции Drift;
- изменение UX экранов;
- перенос Flutter/Riverpod внутрь `vault_db/core`;
- импорт `AppError` в `vault_db/core`.

## Архитектурные правила

1. `vault_db/core` остается Pure Dart модулем.
2. В `vault_db/core` нельзя импортировать Flutter, Riverpod, UI helpers,
   `AppError`, Toaster или feature-код.
3. Публичные методы core API возвращают `AsyncDBResult<T>` /
   `DBResult<T, DBCoreError>`.
4. DAO остаются только SQL/Drift слоем.
5. Repositories остаются data composition слоем.
6. Services остаются orchestration/business слоем: history, relations,
   transactions, state changes.
7. API facade становится единственной публичной точкой для app/feature слоя.
8. List/card/read API не возвращает секретные поля.
9. Mutation API должен сохранять текущие гарантии истории, аудита и relations.
10. Feature-слой не должен вызывать `db.*Dao` напрямую.

## Предлагаемая структура API

Создать фасады в `lib/vault_db/core/api/`:

- `vault_api.dart` - главный агрегатор.
- `system_api.dart` - categories, tags, icons, store settings/meta.
- `items_api.dart` - общие vault item операции.
- `entity_cards_api.dart` - read-only карточки и фильтрация сущностей.
- `entity_mutation_api.dart` - create/update/delete/state operations.
- `history_api.dart` - timeline, detail, restore, retention.
- `documents_api.dart` - document versions/pages.
- `files_api.dart` - file metadata/storage-facing contracts без Flutter.

Главный фасад должен собираться из уже существующих зависимостей:

- `VaultDB`
- `VaultRepositories`
- `VaultEntityServices`
- `VaultCardFilterService`
- `VaultHistoryServiceAssembly`
- `VaultItemRelationsService`
- `DocumentVersionService`

## Public Contracts

Для API-слоя нужны отдельные стабильные контракты, если текущие DTO слишком
близки к таблицам/внутренним операциям.

Минимальные группы:

- `*ListRequest` - query, paging, sort, filters.
- `*CreateRequest` - данные создания.
- `*UpdateRequest` - patch/update данные.
- `*Response` - данные для feature/UI слоя.
- `PagedResponse<T>` - список + total/hasMore/limit/offset.

Не смешивать:

- DTO таблиц;
- DTO repository/service слоя;
- UI state модели;
- API request/response контракты.

## Read API

Read-only API должен покрыть:

- список категорий;
- дерево категорий;
- список тегов;
- список custom icons;
- список icon refs;
- карточки vault items по типам;
- поиск linkable vault items;
- получение card/view by id.

Требования:

- поддерживать пагинацию;
- не отдавать секреты;
- возвращать total count там, где UI строит pagination;
- не требовать от feature-слоя знания DAO/filter DAO.

## Mutation API

Mutation API должен покрыть:

- create/update/delete categories;
- create/update/delete tags;
- create/update/delete custom icons;
- create/update/delete icon refs;
- create/update сущностей vault item;
- archive/recover/favorite/pin/delete item;
- update tags/category relations.

Требования:

- выполнять операции через services/repositories, а не напрямую через DAO из
  feature-слоя;
- сохранять history/audit behavior;
- возвращать typed result;
- не бросать исключения наружу как штатный control flow.

## Error Boundary

Внутри `core`:

- использовать `DBCoreError`;
- возвращать `Failure(DBCoreError...)`;
- не маппить в `AppError`;
- не показывать toast/snackbar/dialog.

Снаружи `core`:

- provider/app adapter может маппить `DBCoreError -> AppError`;
- UI решает, как показать ошибку.

## Provider Layer

В `lib/vault_db/providers` добавить app-level providers для API:

- `vaultApiProvider`
- `vaultSystemApiProvider`
- `vaultItemsApiProvider`
- `vaultHistoryApiProvider`

Provider layer отвечает за:

- получение текущей `VaultDB` из `vaultDBProvider`;
- сборку `VaultRepositories`/services/API;
- invalidation после mutations;
- маппинг ошибок для UI при необходимости.

`vault_db/core` не должен зависеть от этих providers.

## Migration Order

1. Зафиксировать public API interfaces без изменения feature-кода.
2. Реализовать `system_api` для categories/tags/icons.
3. Перевести `pickers` и `managers` на `system_api`.
4. Реализовать read API для карточек vault entities.
5. Перевести dashboard/list/filter UI на read API.
6. Реализовать mutation API для entity forms.
7. Перевести forms на mutation API.
8. Закрыть прямой экспорт DAO/repository для feature-слоя, если возможно.
9. Обновить docs-ai router и README для новой точки входа.

## Compatibility Decisions

Перед реализацией агент обязан проверить и явно зафиксировать решения:

- нужны ли `type` у categories/tags в новой `vault_db`;
- нужен ли `itemsCount` у category/tag card DTO;
- icon manager управляет `custom_icons`, `icon_refs` или двумя разделами;
- какие старые DTO можно удалить после миграции;
- какие direct DAO usages временно остаются и почему.

## Done Criteria

Задача считается выполненной, когда:

- feature-слой работает через API/providers, а не через `db.*Dao`;
- публичные API методы возвращают typed result;
- read models не содержат секретов;
- mutations сохраняют history/audit/relations guarantees;
- `dart analyze` не показывает ошибок в затронутых модулях;
- docs обновлены;
- `CHANGELOG.md` обновлен.

## Agent Notes

- Не переписывать все сразу: сначала `system_api`, затем managers/pickers.
- Не добавлять Riverpod/codegen в `core`.
- Не переносить UI-specific типы в `core`.
- Не использовать ad-hoc string filters, если есть typed filter/request model.
- Не удалять старые API до миграции всех ссылок.
