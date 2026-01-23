# Tags Picker

Компонент выбора тегов с поддержкой множественного выбора, пагинации и фильтрации.

## Основные возможности

- ✅ Множественный выбор тегов
- ✅ Ограничение максимального количества выбираемых тегов (опционально)
- ✅ Пагинация на скролле (20 элементов на страницу)
- ✅ Фильтрация по названию и типу
- ✅ Поддержка клавиатуры (Enter/Space - открыть, Delete/Backspace - очистить)
- ✅ Доступность (Semantics, FocusNode)
- ✅ Отображение выбранных тегов в виде чипсов с возможностью удаления
- ✅ Счетчик выбранных тегов в модальном окне
- ✅ Визуальная индикация выбора
- ✅ Дебаунсинг поискового запроса (300мс)

## Использование

### Базовое использование (без ограничений)

```dart
import 'package:hoplixi/features/password_manager/pickers/tags_picker/tags_picker.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<String> _tagIds = [];
  List<String> _tagNames = [];

  @override
  Widget build(BuildContext context) {
    return TagPickerField(
      selectedTagIds: _tagIds,
      selectedTagNames: _tagNames,
      onTagsSelected: (ids, names) {
        setState(() {
          _tagIds = ids;
          _tagNames = names;
        });
      },
    );
  }
}
```

### С ограничением количества тегов

```dart
TagPickerField(
  selectedTagIds: _tagIds,
  selectedTagNames: _tagNames,
  maxTagPicks: 5, // Максимум 5 тегов
  label: 'Теги проекта',
  hintText: 'Добавьте теги',
  onTagsSelected: (ids, names) {
    setState(() {
      _tagIds = ids;
      _tagNames = names;
    });
  },
)
```

### С внешним FocusNode

```dart
final _focusNode = FocusNode();

TagPickerField(
  selectedTagIds: _tagIds,
  selectedTagNames: _tagNames,
  focusNode: _focusNode,
  autofocus: true,
  onTagsSelected: (ids, names) {
    setState(() {
      _tagIds = ids;
      _tagNames = names;
    });
  },
)
```

## Параметры TagPickerField

| Параметр | Тип | Обязательный | По умолчанию | Описание |
|----------|-----|--------------|--------------|----------|
| `onTagsSelected` | `Function(List<String>, List<String>)` | ✅ | - | Коллбэк при изменении выбора тегов |
| `selectedTagIds` | `List<String>` | ❌ | `[]` | Список ID выбранных тегов |
| `selectedTagNames` | `List<String>` | ❌ | `[]` | Список имен выбранных тегов |
| `maxTagPicks` | `int?` | ❌ | `null` | Максимальное количество тегов (null = без ограничений) |
| `label` | `String` | ❌ | `'Теги'` | Метка поля |
| `hintText` | `String` | ❌ | `'Выберите теги'` | Подсказка при пустом поле |
| `enabled` | `bool` | ❌ | `true` | Доступность поля |
| `focusNode` | `FocusNode?` | ❌ | `null` | FocusNode для управления фокусом |
| `autofocus` | `bool` | ❌ | `false` | Автоматический фокус |

## Архитектура

### Провайдеры (Riverpod)

- **`tagPickerListProvider`** - AsyncNotifierProvider для списка тегов с пагинацией
- **`tagPickerFilterProvider`** - NotifierProvider для фильтров

### Модели (Freezed)

- **`TagPaginationState`** - состояние пагинации (items, hasMore, isLoading, error, currentPage, totalCount)
- **`TagPickerState`** - состояние пикера (tags, isLoading, pagination)

### Виджеты

- **`TagPickerField`** - основное поле выбора с чипсами выбранных тегов
- **`TagPickerModal`** - модальное окно WoltModalSheet со списком тегов
- **`TagPickerItem`** - элемент списка тегов с чекбоксом
- **`TagPickerFilters`** - панель фильтров (поиск + типы)

## Клавиатурные сокращения

- **Enter / Space** - открыть модальное окно выбора
- **Delete / Backspace** - очистить все выбранные теги
- **Click на X в чипе** - удалить конкретный тег

## Интеграция с DAO

Компонент использует:
- `TagDao.getTagCardsFiltered(TagsFilter)` для получения тегов
- `TagsFilter` для фильтрации по query, type, color, датам

## Настройка пагинации

Количество элементов на страницу: `20` (константа `_pageSize` в `TagListNotifier`)

Автоматическая подгрузка происходит при скролле до последнего элемента.

## Кастомизация фильтров

Типы тегов в фильтре:
- Все
- Логин
- Карта
- Заметка
- Файл

Фильтры обновляются с дебаунсингом 300мс для поискового запроса.

## Генерация кода

После изменения моделей запустите:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

или

```bash
build_ranner.bat
```

## Примеры использования

### Форма создания записи с тегами

```dart
class CreateEntryForm extends StatefulWidget {
  @override
  State<CreateEntryForm> createState() => _CreateEntryFormState();
}

class _CreateEntryFormState extends State<CreateEntryForm> {
  final _formKey = GlobalKey<FormState>();
  List<String> _tagIds = [];
  List<String> _tagNames = [];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Другие поля формы...
          
          TagPickerField(
            selectedTagIds: _tagIds,
            selectedTagNames: _tagNames,
            maxTagPicks: 10,
            label: 'Теги записи',
            hintText: 'Добавьте теги для организации',
            onTagsSelected: (ids, names) {
              setState(() {
                _tagIds = ids;
                _tagNames = names;
              });
            },
          ),
          
          // Кнопка сохранения...
        ],
      ),
    );
  }
}
```

### Фильтр по тегам

```dart
class TagFilterWidget extends StatefulWidget {
  final Function(List<String> tagIds) onFilterChanged;

  const TagFilterWidget({required this.onFilterChanged});

  @override
  State<TagFilterWidget> createState() => _TagFilterWidgetState();
}

class _TagFilterWidgetState extends State<TagFilterWidget> {
  List<String> _selectedTagIds = [];
  List<String> _selectedTagNames = [];

  @override
  Widget build(BuildContext context) {
    return TagPickerField(
      selectedTagIds: _selectedTagIds,
      selectedTagNames: _selectedTagNames,
      label: 'Фильтр по тегам',
      hintText: 'Выберите теги для фильтрации',
      onTagsSelected: (ids, names) {
        setState(() {
          _selectedTagIds = ids;
          _selectedTagNames = names;
        });
        widget.onFilterChanged(ids);
      },
    );
  }
}
```
