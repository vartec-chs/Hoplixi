# Localization Guide

Этот документ описывает обязательные правила локализации в Hoplixi.

## Стек

- **`slang: ^4.13.0`** + **`slang_flutter`** + **`slang_build_runner`**
- Исходные файлы: `.i18n.arb` в `lib/l10n/`
- Генерируемые файлы: `lib/generated/l10n/translations.g.dart` (и `_ru.g.dart`,
  `_en.g.dart`)
- Конфигурация: `build.yaml` (секция `slang_build_runner`)

## Поддерживаемые локали

| Код  | Язык    | Статус                      |
| ---- | ------- | --------------------------- |
| `ru` | Русский | ✅ Основной (`base_locale`) |
| `en` | English | 🚧 В процессе               |

## Структура файлов исходников

Исходники хранятся в `lib/l10n/` с обязательной группировкой по **фиче** и
**подтипу**:

```
lib/l10n/
  <feature>/
    <subtype>/
      <feature><Subtype>_ru.i18n.arb   ← базовый (ru)
      <feature><Subtype>_en.i18n.arb   ← перевод (en)
```

Пример — формы дашборда:

```
lib/l10n/
  dashboard/
    forms/
      dashboardForms_ru.i18n.arb
      dashboardForms_en.i18n.arb
    pickers/
      dashboardPickers_ru.i18n.arb
      dashboardPickers_en.i18n.arb
    views/
      dashboardViews_ru.i18n.arb
      dashboardViews_en.i18n.arb
```

> **Правило именования файлов**: `<camelCaseNamespace>_<locale>.i18n.arb` Имя
> файла (без суффикса `_ru`/`_en`) становится **именем пространства имён
> (namespace)**. `dashboardForms` → namespace `dashboard_forms` (slang переводит
> в snake_case).

## Именование ключей в ARB-файлах

Ключи в `.arb` пишутся в **lowerCamelCase** — slang автоматически конвертирует
их в snake_case при кодогенерации.

```json
{
	"@@locale": "ru",
	"saveError": "Ошибка сохранения",
	"checkFormFieldsAndTryAgain": "Проверьте поля формы и попробуйте снова",
	"commonFieldMissing": "{Field} не заполнен",
	"commonFieldEmpty": "{Field} пуст",
	"commonFieldCopied": "{Field} скопирован"
}
```

Правила:

- Используй **семантические** префиксы, привязанные к фиче: `saveError`,
  `apiKeyUpdated`, `wifiCreated`
- Избегай generic-ключей: `title1`, `label`, `ok`
- Параметры именуй с **заглавной буквы** (PascalCase) — слаг генерирует
  `{required Object FieldName}` (`param_case: pascal` в build.yaml)

## Параметризованные ключи

В ARB:

```json
{
	"commonFieldMissing": "{Field} не заполнен"
}
```

Генерируется в Dart:

```dart
String common_field_missing({required Object Field})
```

Использование:

```dart
context.t.dashboard_forms.common_field_missing(Field: context.t.dashboard_forms.password_label)
```

## Использование в Dart-коде

### Импорт

```dart
import 'package:hoplixi/generated/l10n/translations.g.dart';
```

### В виджетах (через BuildContext)

```dart
// Прямое обращение
Text(context.t.dashboard_forms.save_error)

// Через локальную переменную (рекомендуется, если ключей много)
final l10n = context.t.dashboard_forms;
Text(l10n.save_error)
Text(l10n.common_field_missing(Field: l10n.password_label))
```

### Вне BuildContext (в провайдерах / сервисах)

```dart
// Через глобальный геттер t
final msg = t.dashboard_forms.validation_required_name;
```

> `t` — глобальный геттер из `translations.g.dart`, отражает текущую активную
> локаль.

## Добавление нового модуля локализации

### Шаг 1 — Создать папку и ARB-файлы

Пример: хочешь добавить локализацию для экрана «Настройки».

```
lib/l10n/
  settings/
    general/
      settingsGeneral_ru.i18n.arb
      settingsGeneral_en.i18n.arb
```

### Шаг 2 — Заполнить ARB-файлы

`settingsGeneral_ru.i18n.arb`:

```json
{
	"@@locale": "ru",
	"languageSectionTitle": "Язык",
	"themeTitle": "Тема оформления",
	"autoLockTitle": "Таймаут автоблокировки",
	"autoLockSubtitle": "Автоматически блокировать через {Minutes} мин"
}
```

`settingsGeneral_en.i18n.arb`:

```json
{
	"@@locale": "en",
	"languageSectionTitle": "Language",
	"themeTitle": "Theme",
	"autoLockTitle": "Auto-lock timeout",
	"autoLockSubtitle": "Lock automatically after {Minutes} min"
}
```

> **Обязательно**: оба файла должны содержать **одинаковый набор ключей**.

### Шаг 3 — Запустить кодогенерацию

```bash
dart run slang
```

### Шаг 4 — Использовать сгенерированный namespace

Имя файла `settingsGeneral` → namespace `settings_general`:

```dart
Text(context.t.settings_general.language_section_title)
Text(context.t.settings_general.auto_lock_subtitle(Minutes: 5))
```

## Инициализация и переключение языка

### Старт приложения

В `main.dart` — обёртка `TranslationProvider` обязательна:

```dart
runApp(
  ProviderScope(
    child: TranslationProvider(
      child: App(),
    ),
  ),
);
```

Активную локаль устанавливает `LocaleProvider`
(`lib/core/localization/locale_provider.dart`):

- При старте читает сохранённое значение из `AppStorageService` (ключ
  `AppKeys.language`)
- Вызывает `LocaleSettings.setLocaleRaw(code)` для синхронизации со slang
- Fallback: `en`

### Переключение языка в рантайме

Через Riverpod-провайдер:

```dart
await ref.read(localeProvider.notifier).setLocaleCode('ru');
```

Это одновременно:

1. Сохраняет в `AppStorageService`
2. Вызывает `LocaleSettings.setLocaleRaw()`
3. Обновляет `MaterialApp.locale` через
   `TranslationProvider.of(context).flutterLocale`

## Правила синхронизации

- Каждый ключ, добавленный в `_ru.i18n.arb`, **обязан** быть добавлен в
  `_en.i18n.arb` в том же коммите.
- Параметры (плейсхолдеры) должны быть **идентичны** в обоих файлах.
- Не хардкодить пользовательские строки в виджетах, диалогах, формах, тостах и
  сообщениях валидации.

## Checklist при добавлении новых строк

- [ ] Ключи добавлены в оба ARB (`_ru` и `_en`)
- [ ] Параметры в ARB одинаковы в обоих файлах
- [ ] Кодогенерация запущена, файлы `translations.g.dart` обновлены
- [ ] В коде используется `context.t.<namespace>.<key>` — не хардкод
- [ ] Файлы `translations.g.dart` закоммичены вместе с ARB-изменениями

## При добавлении новой локали (в будущем)

- Добавь код локали в `build.yaml` → `autodoc.locales`
- Создай `<name>_<locale>.i18n.arb` для каждого существующего namespace
- Используй `en` как базис для перевода
- Ключевая схема должна оставаться неизменной
