# CHANGELOG

## 2026-04-18

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

### db_core (history triggers)

- Исправлены SQL-шаблоны history-триггеров в
  `lib/db_core/triggers/*_triggers.dart`: убраны ошибочные лишние запятые в
  списках колонок `vault_item_history` после добавления
  `icon_source`/`icon_value`.

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
