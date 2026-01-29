# Управление боковой панелью (Sidebar) в Dashboard

## Обзор

Система управления боковой панелью в Dashboard теперь поддерживает произвольные роуты, а не только формы. Это позволяет открывать sidebar для любых типов контента.

## Как это работает

### Автоматическое открытие sidebar

Sidebar автоматически открывается для:

1. **Форм создания/редактирования** — все роуты, содержащие паттерны форм (`/password/`, `/note/`, `/bank-card/`, `/file/`, `/otp/`)
2. **Destinations с флагом `opensSidebar: true`** — категории, иконки, теги
3. **Пользовательских роутов** — любые роуты, добавленные в `EntityTypeRouting._sidebarRoutes`

### Добавление нового роута для sidebar

Чтобы добавить новый роут, который должен открывать sidebar:

1. Откройте файл `lib/features/password_manager/dashboard/models/entity_type.dart`
2. Найдите константу `_sidebarRoutes`
3. Добавьте ваш путь в список

**Пример:**

```dart
static const List<String> _sidebarRoutes = [
  '/dashboard/detail/',      // Просмотр деталей
  '/dashboard/preview/',     // Предпросмотр
  '/dashboard/settings/',    // Настройки (если нужен sidebar)
];
```

### Проверка используется через `String.contains`

Система использует `location.contains(route)`, поэтому можно указывать:
- Полные пути: `/dashboard/detail/`
- Части путей: `/detail/` (будет совпадать с любым путем, содержащим эту часть)

**Внимание:** Будьте осторожны с короткими паттернами, чтобы избежать ложных срабатываний.

## Примеры использования

### Пример 1: Добавление роута просмотра деталей

```dart
static const List<String> _sidebarRoutes = [
  '/dashboard/detail/',
];
```

Теперь при переходе на `/dashboard/detail/password/123` sidebar откроется автоматически.

### Пример 2: Добавление роута предпросмотра файлов

```dart
static const List<String> _sidebarRoutes = [
  '/dashboard/file/preview/',
];
```

### Пример 3: Несколько роутов

```dart
static const List<String> _sidebarRoutes = [
  '/dashboard/detail/',
  '/dashboard/preview/',
  '/dashboard/comparison/',
];
```

## Программное управление sidebar

Вы можете управлять sidebar программно через `dashboardSidebarKey`:

```dart
// Закрыть sidebar
dashboardSidebarKey.currentState?.closeSidebar();

// Открыть sidebar
dashboardSidebarKey.currentState?.openSidebar();

// Переключить состояние
dashboardSidebarKey.currentState?.toggleSidebar();

// Проверить, открыт ли sidebar
final isOpen = dashboardSidebarKey.currentState?.isSidebarOpen ?? false;
```

## Архитектура

### Основные компоненты

1. **`EntityTypeRouting.shouldOpenSidebar()`** — центральный метод проверки
2. **`EntityTypeRouting._sidebarRoutes`** — конфигурация дополнительных путей
3. **`DashboardLayout._shouldOpenSidebar()`** — обертка для использования в виджете
4. **`DashboardDestination.opensSidebar`** — флаг для navigation destinations

### Логика открытия

```dart
Sidebar открывается если:
├─ selectedIndex > 0 (выбраны категории/иконки/теги)
└─ EntityTypeRouting.shouldOpenSidebar(location) == true
   ├─ isAnyFormRoute(location) — любая форма
   └─ _sidebarRoutes содержит часть пути
```

### Анимация

Sidebar использует `AnimationController` для плавного открытия/закрытия:
- Длительность: 300ms
- Кривая: `Curves.easeInOut`
- Срабатывает через `addPostFrameCallback` для корректной синхронизации

## Desktop vs Mobile

### Desktop Layout
- NavigationRail слева
- DashboardHomeScreenV2 по центру (всегда видим)
- Sidebar справа (выезжает с анимацией)

### Mobile Layout
- BottomNavigationBar внизу (скрывается при sidebar route)
- ExpandableFAB по центру (скрывается при sidebar route)
- widget.child занимает весь экран

## Миграция с старой системы

Старая система проверяла только формы через `_isFormRoute()`. Новая система:

- ✅ Поддерживает формы (обратная совместимость)
- ✅ Поддерживает destinations с `opensSidebar: true`
- ✅ Поддерживает произвольные роуты через `_sidebarRoutes`

Никаких изменений в существующем коде не требуется — все работает автоматически!

## Отладка

Если sidebar не открывается:

1. Проверьте, что путь правильно добавлен в `_sidebarRoutes`
2. Убедитесь, что используется `context.push()` или `context.go()`
3. Проверьте, что роут зарегистрирован в `router.dart`
4. Добавьте логирование:

```dart
bool _shouldOpenSidebar(String location) {
  final result = EntityTypeRouting.shouldOpenSidebar(location);
  debugPrint('shouldOpenSidebar($location) = $result');
  return result;
}
```

## Рекомендации

1. **Используйте trailing slash** в путях для точности: `/detail/` вместо `/detail`
2. **Избегайте конфликтов** — не добавляйте слишком короткие паттерны
3. **Тестируйте** на desktop и mobile — поведение может отличаться
4. **Документируйте** новые роуты при их добавлении

## Заключение

Новая система управления sidebar гибкая и расширяемая. Она поддерживает любые роуты и при этом сохраняет обратную совместимость с существующим кодом форм.
