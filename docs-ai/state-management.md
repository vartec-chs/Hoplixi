# Riverpod State Management

Riverpod is a reactive caching and data-binding framework for Dart/Flutter that
handles async code, errors, and loading states automatically. It separates
business logic from UI, ensuring testable and scalable code.

**Project uses Riverpod 3.0+ without code generation (`@riverpod` not used).**

## Core Concepts

- **Providers** - Expose values (sync/async) and automatically cache results
- **Notifiers** - Manage mutable state with business logic methods
- **AsyncValue** - Type-safe wrapper for async states (loading/data/error)
- **Ref** - Access other providers and manage dependencies
- **Consumer** - Flutter widgets that watch providers and rebuild on changes

## Active Providers

- `Provider` - Synchronous read-only values
- `NotifierProvider` - Mutable state with methods
- `FutureProvider` - Async data fetching
- `StreamProvider` - Real-time data streams
- `AsyncNotifierProvider` - Async mutable state
- `StreamNotifierProvider` - Stream-based mutable state

**Deprecated (don't use):** StateProvider, StateNotifierProvider,
ChangeNotifierProvider

## Provider - Synchronous Values

Exposes immutable, cached values. Automatically recomputes when dependencies
change.

```dart
// Simple value
final cityProvider = Provider((ref) => 'London');

// Computed from other providers
final greetingProvider = Provider((ref) {
  final city = ref.watch(cityProvider);
  return 'Hello from $city';
});

// Usage in widget
class GreetingWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    return Text(greeting);
  }
}
```

## NotifierProvider - Mutable State

Manages mutable state with methods. Encapsulates business logic.

```dart
class TodoList extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => [
    const Todo(id: 'todo-0', description: 'Buy cookies'),
  ];

  void add(String description) {
    state = [...state, Todo(id: _uuid.v4(), description: description)];
  }

  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          Todo(id: todo.id, completed: !todo.completed, description: todo.description)
        else
          todo,
    ];
  }

  void remove(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

final todoListProvider = NotifierProvider<TodoList, List<Todo>>(TodoList.new);

// Computed state
final uncompletedCountProvider = Provider<int>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => !todo.completed).length;
});

// Usage
class TodoWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final count = ref.watch(uncompletedCountProvider);

    return Column(
      children: [
        Text('$count tasks remaining'),
        ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return CheckboxListTile(
              value: todo.completed,
              title: Text(todo.description),
              onChanged: (_) => ref.read(todoListProvider.notifier).toggle(todo.id),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => ref.read(todoListProvider.notifier).add('New task'),
          child: Text('Add Todo'),
        ),
      ],
    );
  }
}
```

## FutureProvider - Async Data

Handles async operations with automatic loading/error states via AsyncValue.

```dart
final randomJokeProvider = FutureProvider<Joke>((ref) async {
  final response = await dio.get<Map<String, Object?>>(
    'https://official-joke-api.appspot.com/random_joke',
  );
  return Joke.fromJson(response.data!);
});

class JokeWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomJoke = ref.watch(randomJokeProvider);

    return switch (randomJoke) {
      AsyncData(:final value) => Column(
          children: [
            Text(value.setup),
            Text(value.punchline),
          ],
        ),
      AsyncError(:final error) => Text('Error: $error'),
      _ => CircularProgressIndicator(),
    };
  }
}
```

## StreamProvider - Real-Time Streams

Exposes latest value from Stream with automatic subscription management.

```dart
final messageStreamProvider = StreamProvider<String>((ref) async* {
  final channel = IOWebSocketChannel.connect('ws://echo.websocket.org');

  ref.onDispose(() => channel.sink.close());

  await for (final message in channel.stream) {
    yield message.toString();
  }
});

class LiveDataWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageStreamProvider);

    return messages.when(
      data: (message) => Text('Latest: $message'),
      loading: () => Text('Connecting...'),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## AsyncNotifierProvider - Async Mutable State

Manages async mutable state with AsyncValue for loading/error handling.

```dart
class TodoListAsync extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    // Initial async load
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      Todo(id: 'todo-0', description: 'Buy cookies'),
    ];
  }

  Future<void> add(String description) async {
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return [...current, Todo(id: _uuid.v4(), description: description)];
    });
  }

  Future<void> toggle(String id) async {
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return [
        for (final todo in current)
          if (todo.id == id)
            Todo(id: todo.id, description: todo.description, completed: !todo.completed)
          else
            todo,
      ];
    });
  }

  Future<void> remove(String id) async {
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return current.where((t) => t.id != id).toList();
    });
  }
}

final todoListAsyncProvider = AsyncNotifierProvider<TodoListAsync, List<Todo>>(
  TodoListAsync.new,
);
```

## ProviderScope - Root Setup

ProviderScope stores all provider states and enables Riverpod functionality.

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Testing with overrides
void testMain() {
  runApp(
    ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(MockApi()),
        userIdProvider.overrideWithValue('test-user-123'),
      ],
      child: MyTestApp(),
    ),
  );
}
```

## Consumer Widgets

ConsumerWidget replaces StatelessWidget, ConsumerStatefulWidget replaces
StatefulWidget.

```dart
// Stateless consumer
class CounterDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}

// Consumer builder for partial rebuilds
class OptimizedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveWidget(), // Won't rebuild
        Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(counterProvider);
            return Text('$count');
          },
        ),
      ],
    );
  }
}

// Stateful consumer
class CounterPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends ConsumerState<CounterPage> {
  @override
  void initState() {
    super.initState();

    // Listen for side effects
    ref.listenManual(
      errorProvider,
      (previous, next) {
        if (next.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${next.error}')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);

    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## AsyncValue - Type-Safe Async State

AsyncValue represents async operation state with type-safe pattern matching.

### Creating AsyncValue

```dart
// Loading state
state = const AsyncValue.loading();
state = const AsyncLoading();

// Data state
state = AsyncValue.data(myData);
state = AsyncData(myData);

// Error state
state = AsyncValue.error(error, stackTrace);
state = AsyncError(error, stackTrace);

// Guard - automatically wraps in try-catch
state = await AsyncValue.guard(() async {
  return await fetchData();
});
```

### Consuming AsyncValue

```dart
final dataProvider = FutureProvider<String>((ref) async {
  await Future.delayed(Duration(seconds: 2));
  return 'Success data';
});

// Pattern matching with switch
class AsyncWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(dataProvider);

    return switch (asyncValue) {
      AsyncData(:final value) => Text('Success: $value'),
      AsyncError(:final error) => ErrorWidget(error),
      _ => CircularProgressIndicator(),
    };
  }
}

// Pattern matching with when
class AsyncWhenWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(dataProvider);

    return asyncValue.when(
      data: (data) => Text('Data: $data'),
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Error: $error'),
    );
  }
}

// Handling refresh state
class RefreshableWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);

    return Stack(
      children: [
        if (data.isRefreshing || data.isReloading)
          LinearProgressIndicator(),
        if (data.hasValue) Text('Current: ${data.value}'),
        ElevatedButton(
          onPressed: () => ref.refresh(dataProvider),
          child: Text('Refresh'),
        ),
      ],
    );
  }
}
```

## Ref Methods

- `ref.watch()` - Subscribe and rebuild on changes
- `ref.read()` - One-time read without subscription
- `ref.listen()` - Side effects without rebuilding
- `ref.refresh()` - Force provider rebuild
- `ref.invalidate()` - Mark provider as stale

```dart
// ref.watch - Reactive subscription
final computedProvider = Provider((ref) {
  final count = ref.watch(counterProvider); // Rebuilds when changes
  final multiplier = ref.watch(multiplierProvider);
  return count * multiplier;
});

// ref.read - One-time read
final actionProvider = Provider((ref) {
  return () {
    final currentCount = ref.read(counterProvider);
    ref.read(counterProvider.notifier).state = currentCount + 1;
  };
});

// ref.listen - Side effects
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      if (next == null && previous != null) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    return Scaffold(body: Text('Home'));
  }
}

// Lifecycle methods
final resourceProvider = Provider((ref) {
  final resource = Resource();

  ref.onDispose(() => resource.dispose());
  ref.onCancel(() => print('Last listener removed'));
  ref.onResume(() => print('New listener added'));

  return resource;
});
```

## Repository Pattern

Clean architecture with dependency injection and testable logic.

```dart
// Infrastructure
final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  ref.onDispose(dio.close);
  return dio;
});

// Repository
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<List<User>> getUsers();
}

class UserRepositoryImpl implements UserRepository {
  final Ref ref;

  UserRepositoryImpl(this.ref);

  @override
  Future<User> getUser(String id) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/users/$id');
    return User.fromJson(response.data);
  }

  @override
  Future<List<User>> getUsers() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/users');
    return (response.data as List).map((json) => User.fromJson(json)).toList();
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref);
});

// Use case
class UserList extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final repository = ref.watch(userRepositoryProvider);
    return repository.getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(userRepositoryProvider);
      return repository.getUsers();
    });
  }
}

final userListProvider = AsyncNotifierProvider<UserList, List<User>>(
  UserList.new,
);

// Testing with mocks
void main() {
  runApp(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(MockUserRepository()),
      ],
      child: MyApp(),
    ),
  );
}
```

## Provider Families

Create parameterized provider instances with automatic caching.

```dart
// Single parameter
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final response = await http.get('https://api.example.com/users/$userId');
  return User.fromJson(jsonDecode(response.body));
});

// Usage: ref.watch(userProvider('user-123'))

// Multiple parameters with named args
final userPostsProvider = FutureProvider.family<List<Post>, ({String userId, int page})>(
  (ref, params) async {
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts(userId: params.userId, page: params.page);
  },
);

// Usage: ref.watch(userPostsProvider((userId: 'abc', page: 1)))

// Filtered list
enum TodoFilter { all, active, completed }

final filteredTodosProvider = Provider.family<List<Todo>, TodoFilter>((ref, filter) {
  final todos = ref.watch(todoListProvider);

  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.completed).toList(),
    TodoFilter.completed => todos.where((t) => t.completed).toList(),
  };
});

class FilteredTodoList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(todoFilterProvider);
    final filteredTodos = ref.watch(filteredTodosProvider(filter));

    return ListView.builder(
      itemCount: filteredTodos.length,
      itemBuilder: (context, index) => TodoItem(filteredTodos[index]),
    );
  }
}
```

## Summary

Riverpod 3.0+ provides reactive state management with:

- Automatic dependency tracking and caching
- Built-in async handling with AsyncValue
- Type-safe provider composition
- Clean architecture with repository pattern
- Easy testing with provider overrides
- No code generation required (unlike older patterns)
