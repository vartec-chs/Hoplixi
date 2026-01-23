# Icon Picker

Компонент для выбора иконок с поиском, пагинацией и превью.

## Структура

```
icon_picker/
├── models/
│   └── icon_picker_state.dart          # Freezed модель состояния
├── provider/
│   ├── icon_picker_filter_provider.dart # Провайдер поиска с дебаунсингом
│   └── icon_picker_list_provider.dart   # Провайдер списка с пагинацией
├── widgets/
│   ├── icon_picker_button.dart          # Основной компонент кнопки выбора
│   ├── icon_picker_card.dart            # Карточка иконки в grid
│   ├── icon_picker_grid.dart            # Сетка иконок с пагинацией
│   └── icon_picker_search_bar.dart      # Поле поиска
├── example/
│   └── icon_picker_example.dart         # Пример использования
├── icon_picker_modal.dart               # Модальное окно выбора
└── icon_picker.dart                     # Экспорт всех компонентов
```

## Использование

### Простое использование

```dart
import 'package:hoplixi/features/password_manager/icon_manager/features/icon_picker/icon_picker.dart';

class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  String? _selectedIconId;

  @override
  Widget build(BuildContext context) {
    return IconPickerButton(
      selectedIconId: _selectedIconId,
      onIconSelected: (iconId) {
        setState(() {
          _selectedIconId = iconId;
        });
      },
      size: 120,  // размер контейнера (опционально, по умолчанию 120)
      hintText: 'Выбрать иконку',  // текст подсказки (опционально)
    );
  }
}
```

### Прямое использование модального окна

```dart
final selectedIconId = await showIconPickerModal(context, ref);

if (selectedIconId != null) {
  print('Выбрана иконка: $selectedIconId');
}
```

## Компоненты

### IconPickerButton

Главный компонент для выбора иконки.

**Параметры:**
- `selectedIconId` (String?) - ID текущей выбранной иконки
- `onIconSelected` (ValueChanged<String?>) - Callback при выборе/удалении иконки
- `size` (double) - Размер контейнера (по умолчанию 120)
- `hintText` (String?) - Текст подсказки когда иконка не выбрана

**Функциональность:**
- Показывает превью выбранной иконки
- Кнопка удаления в правом верхнем углу (при наличии иконки)
- Открывает модальное окно при клике
- Автоматически загружает иконку по ID
- Поддержка SVG и растровых изображений

### showIconPickerModal

Функция для открытия модального окна выбора иконки.

**Параметры:**
- `context` (BuildContext) - Контекст виджета
- `ref` (WidgetRef) - Riverpod ref

**Возвращает:**
- `Future<String?>` - ID выбранной иконки или null при отмене

**Функциональность:**
- WoltModalSheet с полноэкранным режимом
- Поле поиска с дебаунсингом (300ms)
- Сетка иконок 4 колонки
- Автоматическая пагинация при скролле (80% порог)
- Размер страницы: 20 иконок

## Провайдеры

### iconPickerSearchProvider

Управляет поисковым запросом с дебаунсингом.

```dart
// Обновить поиск
ref.read(iconPickerSearchProvider.notifier).updateQuery('svg');

// Очистить поиск
ref.read(iconPickerSearchProvider.notifier).clear();

// Получить текущий запрос
final query = ref.watch(iconPickerSearchProvider);
```

### iconPickerListProvider

Управляет списком иконок с пагинацией.

```dart
// Получить состояние
final asyncState = ref.watch(iconPickerListProvider);

asyncState.when(
  data: (IconPickerState state) {
    // state.items - список иконок
    // state.isLoading - идет загрузка
    // state.hasMore - есть еще данные
    // state.error - ошибка
    // state.currentPage - текущая страница
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Ошибка: $error'),
);

// Загрузить следующую страницу
ref.read(iconPickerListProvider.notifier).loadMore();

// Обновить список
ref.read(iconPickerListProvider.notifier).refresh();
```

## Особенности

### Производительность

- **Дебаунсинг поиска**: 300ms задержка перед обновлением списка
- **Пагинация**: загрузка по 20 иконок
- **Автозагрузка**: при достижении 80% скролла
- **Кэширование**: Riverpod автоматически кэширует состояние

### UI/UX

- Консистентный дизайн с WoltModalSheet
- Поддержка SVG и растровых изображений
- Индикаторы загрузки и ошибок
- Пустые состояния с подсказками
- Кнопка удаления иконки
- Адаптивная высота модального окна (60% экрана)

### Обработка ошибок

- Graceful degradation при ошибках загрузки
- Fallback иконки при ошибках отображения
- Retry механизм для загрузки страниц
- Валидация данных

## Зависимости

- `flutter_riverpod` - State management
- `wolt_modal_sheet` - Модальные окна
- `flutter_svg` - Рендеринг SVG
- `freezed_annotation` - Immutable модели
- `drift` - Database access (через IconDao)

## Примеры

Полный пример использования доступен в `example/icon_picker_example.dart`.
