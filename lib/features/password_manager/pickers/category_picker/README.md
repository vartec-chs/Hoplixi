# Category Picker

Компонент выбора категории с модальным окном WoltModalSheet, поддержкой пагинации и фильтрации.

## Основные возможности

- ✅ Модальное окно с WoltModalSheet
- ✅ Список категорий на slivers (SliverList)
- ✅ Автоматическая пагинация при скролле
- ✅ Фильтрация по типу и поисковому запросу
- ✅ Дебаунсинг поискового запроса (300ms)
- ✅ Работа через коллбэки (без глобального state)
- ✅ AsyncNotifierProvider для управления состоянием
- ✅ Интеграция с CategoryDao через providers

## Использование

### Простой пример

```dart
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';

class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryPickerField(
          selectedCategoryId: _selectedCategoryId,
          selectedCategoryName: _selectedCategoryName,
          onCategorySelected: (id, name) {
            setState(() {
              _selectedCategoryId = id;
              _selectedCategoryName = name;
            });
          },
        ),
      ],
    );
  }
}
```

### Настройка поля

```dart
CategoryPickerField(
  selectedCategoryId: _selectedCategoryId,
  selectedCategoryName: _selectedCategoryName,
  onCategorySelected: (id, name) {
    // Обработка выбора
  },
  label: 'Категория проекта',
  hintText: 'Выберите категорию для проекта',
  enabled: true, // или false для disabled состояния
)
```

### Прямой вызов модального окна

Если нужно открыть модальное окно программно:

```dart
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';

void _openCategoryPicker() {
  CategoryPickerModal.show(
    context: context,
    currentCategoryId: _selectedCategoryId,
    onCategorySelected: (categoryId, categoryName) {
      setState(() {
        _selectedCategoryId = categoryId;
        _selectedCategoryName = categoryName;
      });
    },
  );
}
```

## Архитектура

### Провайдеры

1. **categoryFilterProvider** - управляет фильтрами (поиск, тип)
2. **categoryListProvider** - управляет списком категорий с пагинацией

### Виджеты

1. **CategoryPickerField** - текстовое поле для выбора
2. **CategoryPickerModal** - модальное окно с WoltModalSheet
3. **CategoryPickerFilters** - панель фильтров
4. **CategoryPickerItem** - элемент списка категорий

### Модели

- **CategoryPaginationState** - состояние пагинации списка
- **CategoriesFilter** - фильтр для категорий

## Пагинация

Пагинация работает автоматически:
- Размер страницы: 20 элементов
- Автоматическая подгрузка при прокрутке до конца списка
- Индикатор загрузки при подгрузке новой страницы

## Фильтрация

Доступные фильтры:
- **Поиск** - по названию категории (с дебаунсингом 300ms)
- **Тип** - Все / Логин / Карта / Заметка / Файл

Фильтры автоматически сбрасывают пагинацию и перезагружают список.

## Интеграция с DAO

Компонент использует `CategoryDao` через `categoryDaoProvider`:
```dart
final categoryDao = await ref.read(categoryDaoProvider.future);
final categories = await categoryDao.getCategoryCardsFiltered(filter);
```

## Обработка ошибок

- Ошибки загрузки отображаются в модальном окне
- Пустой список показывает соответствующее сообщение
- Ошибки логируются через `AppLogger`
