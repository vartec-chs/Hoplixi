# Store Settings Feature

Фича для управления настройками хранилища (Store Meta).

## Структура

```
store_settings/
├── index.dart                          # Главный экспорт
├── store_settings_modal.dart           # Функция вызова модального окна
├── models/
│   └── store_settings_state.dart       # Состояние настроек
├── providers/
│   └── store_settings_provider.dart    # Провайдер управления состоянием
└── widgets/
    └── store_settings_form.dart        # Форма редактирования
```

## Использование

### Импорт

```dart
import 'package:hoplixi/features/password_manager/store_settings/index.dart';
```

### Показ модального окна

Для показа модального окна используйте единственную функцию
`showStoreSettingsModal`:

```dart
// В любом Consumer-виджете
Future<void> _openSettings() async {
  final result = await showStoreSettingsModal(context, ref);

  if (result == true) {
    // Настройки были сохранены
    print('Settings saved successfully');
  } else {
    // Пользователь отменил или закрыл окно
    print('Settings cancelled');
  }
}
```

### Использование в кнопке

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => showStoreSettingsModal(context, ref),
      tooltip: 'Настройки хранилища',
    );
  }
}
```

## Возможности

- ✅ Редактирование имени хранилища
- ✅ Редактирование описания хранилища
- ✅ Валидация имени (3-50 символов, без спецсимволов)
- ✅ Автоматическая загрузка текущих настроек
- ✅ Сброс изменений к исходным значениям
- ✅ Индикация процесса сохранения
- ✅ Уведомления об ошибках и успехе
- ✅ Работа через Riverpod и result_dart
- ✅ Использование StoreMetaDao

## Провайдер

Провайдер `storeSettingsProvider` автоматически загружает текущие настройки из
базы данных при инициализации и управляет всей бизнес-логикой.

### Методы провайдера

- `updateName(String name)` — обновить имя
- `updateDescription(String? description)` — обновить описание
- `save()` — сохранить изменения (возвращает Result)
- `reset()` — сбросить к исходным значениям
- `clearMessages()` — очистить сообщения об ошибках/успехе

### Состояние

```dart
class StoreSettingsState {
  final String name;              // Текущее имя
  final String? description;      // Текущее описание
  final String newName;           // Новое имя (в процессе редактирования)
  final String? newDescription;   // Новое описание
  final String? nameError;        // Ошибка валидации
  final bool isSaving;            // Флаг сохранения
  final String? saveError;        // Ошибка сохранения
  final String? successMessage;   // Сообщение об успехе

  bool get canSave;               // Можно ли сохранить
}
```

## Интеграция с StoreMetaDao

Фича использует `storeMetaDaoProvider` для работы с мета-информацией хранилища:

- `getStoreMeta()` — получение текущих настроек
- `updateName(String)` — обновление имени
- `updateDescription(String?)` — обновление описания

## Зависимости

- `flutter_riverpod` — управление состоянием
- `wolt_modal_sheet` — модальное окно
- `result_dart` — типобезопасная обработка результатов
- `freezed` — генерация immutable моделей
- Shared UI компоненты:
  - `SmoothButton` — кнопки
  - `NotificationCard` — уведомления об ошибках
  - `primaryInputDecoration` — стилизация текстовых полей
  - `Toaster` — всплывающие уведомления

## Примечания

1. Модальное окно использует `WoltModalSheet` из пакета `wolt_modal_sheet`
2. Все изменения сохраняются в базу данных через `StoreMetaDao`
3. Валидация происходит в реальном времени
4. Кнопка "Сохранить" активна только при наличии валидных изменений
5. При успешном сохранении модальное окно автоматически закрывается
6. Используется паттерн Result для обработки ошибок
