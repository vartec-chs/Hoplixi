# Riverpod 3.x State Management (Manual-first, LLM Guide)

Единый справочник для генерации и ревью кода на Riverpod 3.x в этом проекте.

## Цель и рамки

- Используем **Riverpod 3.x+** без codegen (`@riverpod` не является дефолтом).
- Основной стиль: **manual API** (`Provider`, `NotifierProvider`,
  `FutureProvider`, `StreamProvider`, `AsyncNotifierProvider`,
  `StreamNotifierProvider`).
- Legacy подходы (`StateProvider`, `StateNotifierProvider`,
  `ChangeNotifierProvider`) в новом коде не использовать.
- Сначала проектируем **state + lifecycle + mutation API**, затем выбираем тип
  провайдера.

---

## Быстрый выбор провайдера

1. Синхронное read-only значение → `Provider<T>`
2. Только async-загрузка (`Future`) → `FutureProvider<T>`
3. Только поток (`Stream`) → `StreamProvider<T>`
4. Нужны методы изменения состояния (`save/add/toggle/reload`) →
   - синхронно: `NotifierProvider<NotifierT, StateT>`
   - асинхронно: `AsyncNotifierProvider<NotifierT, StateT>`
   - stream + методы: `StreamNotifierProvider<NotifierT, StateT>`

Правило: если UI вызывает `.notifier` методы — почти всегда нужен Notifier.

---

## Базовый setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}
```

Для unit-тестов без Flutter используем `ProviderContainer`.

---

## Каноничные паттерны провайдеров

### 1) Provider (синхронное вычисление)

```dart
final taxRateProvider = Provider<double>((ref) => 0.2);
```

### 2) FutureProvider (read-only async)

```dart
final userProvider = FutureProvider<User>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.fetchCurrentUser();
});
```

### 3) StreamProvider (read-only stream)

```dart
final tickerProvider = StreamProvider<int>((ref) async* {
  var i = 0;
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield i++;
  }
});
```

### 4) NotifierProvider (sync mutable state)

```dart
final counterProvider = NotifierProvider<CounterNotifier, int>(CounterNotifier.new);

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}
```

### 5) AsyncNotifierProvider (основной выбор для CRUD/network)

```dart
final itemsProvider =
    AsyncNotifierProvider<ItemsNotifier, List<Item>>(ItemsNotifier.new);

class ItemsNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async {
    final repo = ref.read(itemsRepositoryProvider);
    return repo.fetchItems();
  }

  Future<void> reload() async {
    final repo = ref.read(itemsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repo.fetchItems);
  }

  Future<void> add(Item item) async {
    final current = state.valueOrNull ?? <Item>[];
    final repo = ref.read(itemsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.createItem(item);
      return [...current, item];
    });
  }
}
```

### 6) StreamNotifierProvider (stream c class API)

```dart
final chatProvider =
    StreamNotifierProvider<ChatNotifier, Message>(ChatNotifier.new);

class ChatNotifier extends StreamNotifier<Message> {
  @override
  Stream<Message> build() {
    final chatApi = ref.read(chatApiProvider);
    return chatApi.messages();
  }
}
```

---

## Family (обязательно для параметризованных сценариев)

`Family` = независимое состояние на каждый параметр (ментально
`Map<Param, State>`).

Требования:

- параметр должен иметь стабильные `==` и `hashCode`;
- обычно вместе с `autoDispose`, чтобы не накапливать редко используемые
  инстансы.

### Functional family

```dart
final userByIdProvider = FutureProvider.autoDispose.family<User, String>((ref, id) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.fetchUser(id);
});
```

### Notifier family (manual-класс с параметром)

```dart
final wifiFormProvider = AsyncNotifierProvider.autoDispose
    .family<WifiFormNotifier, WifiFormState, String?>(WifiFormNotifier.new);

class WifiFormNotifier extends AsyncNotifier<WifiFormState> {
  WifiFormNotifier(this.wifiId);

  final String? wifiId;

  @override
  Future<WifiFormState> build() async {
    final repo = ref.read(wifiRepositoryProvider);
    if (wifiId == null) return WifiFormState.empty();
    return repo.loadForm(wifiId!);
  }

  Future<void> save(WifiFormState form) async {
    final repo = ref.read(wifiRepositoryProvider);
    await repo.saveForm(wifiId, form);
    state = AsyncData(form);
  }
}
```

### Invalidate family

```dart
ref.invalidate(userByIdProvider('42')); // конкретный ключ
ref.invalidate(userByIdProvider);       // все ключи family
```

---

## AutoDispose и lifecycle

Применяй `autoDispose`, если состояние:

- временное;
- экран-специфичное;
- family-инстанс, который не нужен постоянно.

Lifecycle hooks:

- `ref.onCancel`
- `ref.onResume`
- `ref.onDispose`

```dart
final resourceProvider = Provider.autoDispose<Resource>((ref) {
  final resource = Resource();
  ref.onDispose(resource.dispose);
  return resource;
});
```

Важно: в `onDispose` не запускать side-effects, меняющие другие провайдеры.

---

## Ref API: что когда использовать

- `ref.watch(...)` — реактивная подписка (UI и зависимости между провайдерами)
  (build-методы, `when`/`maybeWhen`, `select`).
- `ref.read(...)` — одноразовое чтение (кнопки, команды, callbacks)
  (`onPressed`, `initState`, `async gaps`).
- `ref.listen(...)` — сайд-эффекты (snackbar, navigation, analytics)
  (build-методы `ref.listen(userProvider, (prev, next) { ... })`).
- `ref.listenManual(...)` — сайд-эффекты с контролем `mounted` (для async gaps).
- `ref.refresh(provider)` — invalidate + немедленный read (пересоздать провайдер
  и сразу получить новое значение).
- `ref.invalidate(provider)` — пометить устаревшим, пересчёт при следующем
  чтении (не пересчитывает сразу, только помечает как "грязный").

---

## AsyncValue: стандарт обработки async состояния

Создание:

```dart
state = const AsyncLoading();
state = AsyncData(value);
state = AsyncError(error, stackTrace);
state = await AsyncValue.guard(() async => await repo.load());
```

Потребление (UI):

```dart
final value = ref.watch(itemsProvider);

return value.when(
  data: (items) => ItemsList(items: items),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, st) => ErrorView(error: e),
);
```

---

## Riverpod 3.x: что важно помнить

1. Включен automatic retry по умолчанию (при исключениях).
2. Ошибки чтения зависимостей могут быть обёрнуты в `ProviderException`.
3. Вне видимости части listeners/providers могут быть paused (влияет на
   lifecycle).
4. Legacy provider types вынесены в `legacy.dart`; в новом коде это не дефолт.

---

## UI и async gaps (`context.mounted`)

После `await` виджет может быть размонтирован:

```dart
onPressed: () async {
  await ref.read(itemsProvider.notifier).reload();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Updated')),
  );
}
```

---

## Производительность

- Сначала профилирование, потом оптимизация.
- Для уменьшения rebuild: `select` / `selectAsync`.
- Выделяй мелкие виджеты, где `Consumer` нужен только локально.
- Не помещай тяжёлую логику в `build()` виджета.

```dart
final userNameProvider = Provider<String>((ref) {
  return ref.watch(userProvider.select((u) => u.name));
});
```

---

## Repository pattern и DI

- Инфраструктура (API/DB clients) как `Provider`.
- Репозитории как `Provider<RepoInterface>`.
- Use-case состояние как `Notifier/AsyncNotifier`.
- UI не должен знать детали API/DB, только читает state и вызывает методы
  `.notifier`.

---

## Overrides и тестирование

### Unit test

```dart
test('loads user', () async {
  final container = ProviderContainer.test(
    overrides: [
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
    ],
  );

  final user = await container.read(userProvider.future);
  expect(user.id, 'test-id');
});
```

### Widget test

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
    ],
    child: const App(),
  ),
);
```

Если `autoDispose` мешает тесту, удерживай провайдер через
`container.listen(...)`.

---

## Experimental API (использовать осознанно)

- `Mutation` — удобные статусы write-операций (`idle/pending/success/error`).
- Offline persistence — сохранение состояния Notifier между перезапусками.

Использовать только если действительно нужно и команда согласовала подход.

---

## DO / DON'T для LLM

### DO

- Объявляй провайдеры как top-level `final`.
- Клади бизнес-логику в `Notifier`/`AsyncNotifier`.
- Для параметров используй `family`.
- Для async CRUD предпочитай `AsyncNotifierProvider`.
- Используй `AsyncValue.guard` для единообразной обработки ошибок.

### DON'T

- Не создавай провайдеры динамически во время выполнения.
- Не используй legacy API без явного требования.
- Не клади ephemeral UI-state в глобальные бизнес-провайдеры.
- Не делай `initState` основным механизмом инициализации бизнес-логики.

---

## Минимальный production-ready шаблон

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final itemsProvider =
    AsyncNotifierProvider<ItemsNotifier, List<String>>(ItemsNotifier.new);

class ItemsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final repo = ref.read(itemsRepositoryProvider);
    return repo.fetchItems();
  }

  Future<void> reload() async {
    final repo = ref.read(itemsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repo.fetchItems);
  }
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);

    return MaterialApp(
      home: Scaffold(
        body: items.when(
          data: (v) => ListView(children: [for (final e in v) Text(e)]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('$e')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => ref.read(itemsProvider.notifier).reload(),
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

void main() {
  runApp(const ProviderScope(child: App()));
}
```

---

## Короткий итог

Этот документ — единый source of truth по Riverpod state management для LLM в
проекте: manual-first, Riverpod 3.x, без codegen-first и без legacy-by-default.
