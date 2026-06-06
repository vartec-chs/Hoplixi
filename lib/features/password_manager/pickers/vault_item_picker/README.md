# Vault Item Picker

Компонент выбора объектов хранилища для создания связей между vault items.
Состоит из поля формы и модального окна WoltModalSheet с фильтрацией и
постраничной загрузкой.

## Основные возможности

- Модальное окно с `WoltModalSheet`
- Поле формы `VaultItemPickerField` для одиночного выбора
- Автоматическая пагинация при прокрутке
- Поиск по названию и описанию объекта с debounce 300ms
- Фильтрация по типам `VaultItemType`
- Фильтрация по категориям через существующий `CategoryPickerField`
- Исключение текущего объекта через `excludeItemId`
- Восстановление отображаемых данных по `selectedItemId`
- Работа через коллбэки без глобального UI-state

## Использование

### Поле выбора

```dart
import 'package:hoplixi/features/password_manager/pickers/vault_item_picker/vault_item_picker.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';

class LinkPickerExample extends StatefulWidget {
  const LinkPickerExample({super.key});

  @override
  State<LinkPickerExample> createState() => _LinkPickerExampleState();
}

class _LinkPickerExampleState extends State<LinkPickerExample> {
  String? _selectedItemId;
  String? _selectedItemName;
  VaultItemType? _selectedItemType;

  @override
  Widget build(BuildContext context) {
    return VaultItemPickerField(
      selectedItemId: _selectedItemId,
      selectedItemName: _selectedItemName,
      selectedItemType: _selectedItemType,
      excludeItemId: currentItemId,
      onItemSelected: (item) {
        setState(() {
          _selectedItemId = item?.id;
          _selectedItemName = item?.name;
          _selectedItemType = item?.vaultItemType;
        });
      },
    );
  }
}
```

### Настройка поля

```dart
VaultItemPickerField(
  selectedItemId: _linkedItemId,
  selectedItemName: _linkedItemName,
  selectedItemType: _linkedItemType,
  selectedItemDescription: _linkedItemDescription,
  excludeItemId: editingItemId,
  label: 'Связанный объект',
  hintText: 'Выберите объект для связи',
  enabled: true,
  onItemSelected: (item) {
    // item == null означает очистку выбора.
  },
)
```

Если передан только `selectedItemId`, поле само загрузит название, тип и
описание через `VaultItemRepository.getById`.

### Прямой вызов модального окна

```dart
import 'package:hoplixi/features/password_manager/pickers/vault_item_picker/vault_item_picker.dart';

Future<void> insertLink(BuildContext context, WidgetRef ref) async {
  final item = await showVaultItemPickerModal(
    context,
    ref,
    excludeItemId: currentItemId,
  );

  if (item == null) return;

  // Используйте item.id, item.name и item.vaultItemType для создания связи.
}
```

## Архитектура

### Публичный API

1. `VaultItemPickerField` - поле формы для выбора одного объекта.
2. `showVaultItemPickerModal` - модальное окно выбора объекта.
3. `LinkedVaultItemCardDto` - минимальная модель выбранного объекта:
   `id`, `name`, `vaultItemType`, `description`.

Экспортировать и импортировать picker нужно через:

```dart
import 'package:hoplixi/features/password_manager/pickers/vault_item_picker/vault_item_picker.dart';
```

### Загрузка данных

Модальное окно читает репозитории через `vaultRepositories`:

```dart
final repos = await ref.read(vaultRepositories.future);
final result = await repos.vaultItem.searchLinkableItems(
  query: query,
  excludeItemId: excludeItemId,
  types: selectedTypes,
  categoryIds: selectedCategoryIds,
  limit: 20,
  offset: offset,
);
```

`VaultItemRepository.searchLinkableItems` делегирует SQL-запрос в
`VaultItemsDao.searchActiveVaultItems`.

## Пагинация

Пагинация работает автоматически:

- размер страницы: 20 элементов
- следующая страница загружается при прокрутке ближе к концу списка
- `offset` равен текущему количеству загруженных элементов
- индикатор загрузки показывается внизу списка

## Фильтрация

Доступные фильтры:

- поиск по названию и описанию объекта
- типы объектов (`VaultItemType`)
- категории через `CategoryPickerField` в режиме фильтра

Любое изменение фильтра сбрасывает список, `offset` и загружает первую страницу
заново.

## Обработка ошибок

- Ошибка первой загрузки отображается в модальном окне с кнопкой повтора.
- Ошибка подгрузки страницы останавливает индикатор загрузки.
- Пустой список показывает отдельное сообщение.
- Репозиторий возвращает typed result через `AsyncDBResult`.

## Где используется

Сейчас picker применяется для вставки ссылок на vault items в note form:

- `forms/note_form/screens/note_form_screen.dart`
- `forms/note_form/widgets/note_link_button.dart`
