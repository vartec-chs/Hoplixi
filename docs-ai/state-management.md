# Riverpod - Reactive State Management Framework

Riverpod is a reactive caching and data-binding framework for Dart and Flutter applications. It provides a robust solution for managing application state by handling asynchronous code, errors, and loading states automatically. The framework separates business logic from UI components, ensuring testable, scalable, and reusable code that works seamlessly across Flutter widgets, pure Dart applications, and backend services.

The framework consists of three main packages: `riverpod` for pure Dart state management, `flutter_riverpod` for Flutter integration with Consumer widgets, and `hooks_riverpod` for combining with flutter_hooks. Riverpod supports multiple provider types including Provider for synchronous values, FutureProvider for async operations, StreamProvider for reactive streams, and NotifierProvider for mutable state with business logic. The framework features automatic dependency tracking, built-in caching, code generation via `@riverpod` annotations, and comprehensive async state management through the `AsyncValue` type.

## Active Providers List

- Provider
- FutureProvider
- StreamProvider
- NotifierProvider
- AsyncNotifierProvider
- StreamNotifierProvider
- StateProvider (Deprecated, use NotifierProvider or AsyncNotifierProvider instead)
- StateNotifierProvider (Deprecated, use NotifierProvider or AsyncNotifierProvider instead)
- ChangeNotifierProvider (Deprecated, use NotifierProvider or AsyncNotifierProvider instead)

## Provider - Synchronous Read-Only State

Provider exposes a synchronous, immutable value that can be accessed throughout the application. It automatically caches the value and recomputes only when dependencies change.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple value provider
final cityProvider = Provider((ref) => 'London');

// Computed provider that watches other providers
final greetingProvider = Provider((ref) {
  final city = ref.watch(cityProvider);
  return 'Hello from $city';
});

// Using in a widget
class GreetingWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    return Text(greeting); // Displays: "Hello from London"
  }
}
```

## FutureProvider - Asynchronous Data Fetching

FutureProvider handles asynchronous operations and automatically manages loading, error, and data states through AsyncValue. Perfect for API calls, file I/O, and database queries.

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dio = Dio();

// Fetching data from an API
final randomJokeProvider = FutureProvider<Joke>((ref) async {
  final response = await dio.get<Map<String, Object?>>(
    'https://official-joke-api.appspot.com/random_joke',
  );
  return Joke.fromJson(response.data!);
});

class Joke {
  final String setup;
  final String punchline;
  final int id;

  Joke({required this.setup, required this.punchline, required this.id});

  factory Joke.fromJson(Map<String, Object?> json) {
    return Joke(
      setup: json['setup']! as String,
      punchline: json['punchline']! as String,
      id: json['id']! as int,
    );
  }
}

// Consuming async data with error/loading handling
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

## StreamProvider - Real-Time Data Streams

StreamProvider exposes the latest value from a Stream, automatically handling subscription management and providing AsyncValue for state handling.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// WebSocket stream provider
final messageStreamProvider = StreamProvider<String>((ref) async* {
  final channel = IOWebSocketChannel.connect('ws://echo.websocket.org');

  ref.onDispose(() {
    channel.sink.close();
  });

  await for (final message in channel.stream) {
    yield message.toString();
  }
});

// Ticker stream example
final tickerProvider = StreamProvider<int>((ref) async* {
  int count = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield count++;
  }
});

class LiveDataWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageStreamProvider);

    return messages.when(
      data: (message) => Text('Latest: $message'),
      loading: () => Text('Connecting...'),
      error: (err, stack) => Text('Connection error: $err'),
    );
  }
}
```

## StreamNotifierProvider - Real-Time Data Streams with Notifier

StreamNotifierProvider<NotifierT extends StreamNotifier<ValueT>, ValueT> class final Providers
A provider which creates and listen to an StreamNotifier.

This is similar to FutureProvider but allows to perform side-effects.

The syntax for using this provider is slightly different from the others in that the provider's function doesn't receive a "ref" (and in case of family, doesn't receive an argument either). Instead the ref (and argument) are directly accessible in the associated StreamNotifier.

## NotifierProvider - Mutable State with Business Logic

NotifierProvider manages mutable state with methods for state manipulation. The class-based approach encapsulates business logic and provides a clean API for state updates.

```dart
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Todo {
  final String id;
  final String description;
  final bool completed;

  const Todo({
    required this.id,
    required this.description,
    this.completed = false,
  });
}

// Notifier class with mutable state
class TodoList extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => [
    const Todo(id: 'todo-0', description: 'Buy cookies'),
    const Todo(id: 'todo-1', description: 'Star Riverpod'),
  ];

  void add(String description) {
    state = [...state, Todo(id: _uuid.v4(), description: description)];
  }

  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          Todo(
            id: todo.id,
            completed: !todo.completed,
            description: todo.description,
          )
        else
          todo,
    ];
  }

  void remove(Todo target) {
    state = state.where((todo) => todo.id != target.id).toList();
  }
}

final todoListProvider = NotifierProvider<TodoList, List<Todo>>(TodoList.new);

// Derived computed state
final uncompletedTodosProvider = Provider<int>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => !todo.completed).length;
});

// Using in UI
class TodoListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final uncompletedCount = ref.watch(uncompletedTodosProvider);

    return Column(
      children: [
        Text('$uncompletedCount tasks remaining'),
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
          onPressed: () {
            ref.read(todoListProvider.notifier).add('New task');
          },
          child: Text('Add Todo'),
        ),
      ],
    );
  }
}
```

## AsyncNotifierProvider — Асинхронное состояние 

AsyncNotifierProvider используется, когда состояние требует асинхронной загрузки, работы с API, файлами или долгих операций.
Он работает с типом AsyncValue, который покрывает три состояния:
- AsyncLoading
- AsyncData
- AsyncError
AsyncNotifier инкапсулирует бизнес-логику и позволяет удобно обновлять состояние.

```dart
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class TodoListAsync extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    // Имитируем загрузку
    await Future.delayed(const Duration(milliseconds: 300));

    return const [
      Todo(id: 'todo-0', description: 'Buy cookies'),
      Todo(id: 'todo-1', description: 'Learn AsyncNotifier'),
    ];
  }

  /// Добавить задачу
  Future<void> add(String description) async {
    // Обновление с учётом существующего AsyncValue
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return [
        ...current,
        Todo(id: _uuid.v4(), description: description),
      ];
    });
  }

  /// Переключить completed
  Future<void> toggle(String id) async {
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return [
        for (final todo in current)
          if (todo.id == id)
            Todo(
              id: todo.id,
              description: todo.description,
              completed: !todo.completed,
            )
          else
            todo,
      ];
    });
  }

  /// Удаление
  Future<void> remove(Todo target) async {
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return current.where((t) => t.id != target.id).toList();
    });
  }
}
```

## @riverpod Annotation - Code Generation (No used)

The @riverpod annotation generates boilerplate code for providers, creating type-safe providers with automatic parameter handling and family support. 


## ProviderScope - Root Container Setup

ProviderScope is the root widget that stores all provider states. It enables Riverpod functionality for the entire application and supports overriding providers for testing.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    // Wrap app with ProviderScope to enable Riverpod
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
        // Override providers for testing
        apiProvider.overrideWithValue(MockApi()),
        userIdProvider.overrideWithValue('test-user-123'),
      ],
      child: MyTestApp(),
    ),
  );
}

// Multiple ProviderScopes for isolation
Widget buildNestedScopes() {
  return ProviderScope(
    child: MaterialApp(
      home: ProviderScope(
        overrides: [
          themeProvider.overrideWithValue(ThemeData.dark()),
        ],
        child: MyPage(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeView(),
    );
  }
}
```

## Consumer Widgets - Flutter Integration

Consumer widgets provide access to WidgetRef for watching providers. ConsumerWidget replaces StatelessWidget, while ConsumerStatefulWidget replaces StatefulWidget.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ConsumerWidget for stateless widgets
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

// ConsumerStatefulWidget for stateful widgets
class CounterPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends ConsumerState<CounterPage> {
  @override
  void initState() {
    super.initState();

    // Listen for changes in initState
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
    // ref.watch rebuilds on changes
    final count = ref.watch(counterProvider);

    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        // ref.read for one-time access
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## AsyncValue - Type-Safe Async State

AsyncValue represents the state of an asynchronous operation with type-safe pattern matching for loading, data, and error states.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dataProvider = FutureProvider<String>((ref) async {
  await Future.delayed(Duration(seconds: 2));
  if (DateTime.now().second % 2 == 0) {
    throw Exception('Random error occurred');
  }
  return 'Success data';
});

// Pattern matching with when
class AsyncWidget extends ConsumerWidget {
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

// Pattern matching with switch
class SwitchAsyncWidget extends ConsumerWidget {
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

// Handling refresh state
class RefreshableWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider);

    return Stack(
      children: [
        // Show loading indicator while refreshing
        if (data.isRefreshing || data.isReloading)
          LinearProgressIndicator(),

        // Always show previous data during refresh
        if (data.hasValue)
          Text('Current: ${data.value}'),

        ElevatedButton(
          onPressed: () => ref.refresh(dataProvider),
          child: Text('Refresh'),
        ),
      ],
    );
  }
}

// Transform AsyncValue
final transformedProvider = Provider<AsyncValue<int>>((ref) {
  final data = ref.watch(dataProvider);
  return data.whenData((value) => value.length);
});
```

## Ref Methods - Provider Interaction

Ref provides methods for interacting with providers: watch for reactive dependencies, read for one-time access, and listen for side effects.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final counterProvider = StateProvider((ref) => 0);
final multiplierProvider = StateProvider((ref) => 2);

// ref.watch - Reactive subscription
final computedProvider = Provider((ref) {
  final count = ref.watch(counterProvider); // Rebuilds when changes
  final multiplier = ref.watch(multiplierProvider);
  return count * multiplier;
});

// ref.read - One-time read without subscription
final actionProvider = Provider((ref) {
  return () {
    final currentCount = ref.read(counterProvider);
    ref.read(counterProvider.notifier).state = currentCount + 1;
  };
});

// ref.listen - Side effects
final authProvider = StateProvider<User?>((ref) => null);

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for navigation side effects
    ref.listen(authProvider, (previous, next) {
      if (next == null && previous != null) {
        // User logged out - navigate to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    return Scaffold(body: Text('Home'));
  }
}

// ref.refresh - Force provider rebuild
class RefreshExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.refresh(dataProvider); // Refetch data
      },
      child: Text('Refresh'),
    );
  }
}

// ref.invalidate - Mark provider as stale
final cacheProvider = FutureProvider((ref) async {
  ref.cacheFor(Duration(minutes: 5));
  return fetchExpensiveData();
});

void clearCache(Ref ref) {
  ref.invalidate(cacheProvider); // Clear cache
}

// Lifecycle methods
final resourceProvider = Provider((ref) {
  final resource = Resource();

  ref.onDispose(() {
    resource.dispose(); // Cleanup
  });

  ref.onCancel(() {
    print('Last listener removed');
  });

  ref.onResume(() {
    print('New listener added after cancellation');
  });

  return resource;
});

// Keep provider alive
final importantProvider = Provider.autoDispose((ref) {
  final link = ref.keepAlive();

  // Later, allow disposal
  Timer(Duration(minutes: 5), link.close);

  return 'Important data';
});
```

## Repository Pattern - Dependency Injection

Riverpod enables clean architecture with repository patterns, dependency injection, and testable business logic separation.

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Infrastructure layer
final dioProvider = Provider((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  ref.onDispose(dio.close);
  return dio;
});

// Repository layer
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
    final cancelToken = ref.cancelToken();

    final response = await dio.get(
      '/users',
      cancelToken: cancelToken,
    );

    return (response.data as List)
        .map((json) => User.fromJson(json))
        .toList();
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref);
});

// Domain layer - Use cases
@riverpod
Future<User> fetchUser(Ref ref, String userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser(userId);
}

@riverpod
class UserList extends _$UserList {
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

// Presentation layer
class UserListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userListProvider);

    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => UserTile(user: users[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, _) => ErrorView(error: error),
    );
  }
}

// Testing with mock repositories
class MockUserRepository implements UserRepository {
  @override
  Future<User> getUser(String id) async {
    return User(id: id, name: 'Test User');
  }

  @override
  Future<List<User>> getUsers() async {
    return [User(id: '1', name: 'User 1')];
  }
}

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

## Provider Families - Parameterized Providers

Provider families create multiple instances of providers based on parameters, automatically caching each instance and managing their lifecycle.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Family with single parameter (using code generation)
@riverpod
Future<User> user(Ref ref, String userId) async {
  final response = await http.get('https://api.example.com/users/$userId');
  return User.fromJson(jsonDecode(response.body));
}

// Generated: userProvider(userId)
// Usage: ref.watch(userProvider('user-123'))

// Family with multiple parameters
@riverpod
Future<List<Post>> userPosts(
  Ref ref, {
  required String userId,
  required int page,
  int limit = 10,
}) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.fetchPosts(
    userId: userId,
    page: page,
    limit: limit,
  );
}

// Usage: userPostsProvider(userId: 'abc', page: 1, limit: 20)

// Filtered list example
enum TodoFilter { all, active, completed }

final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

@riverpod
List<Todo> filteredTodos(Ref ref, TodoFilter filter) {
  final todos = ref.watch(todoListProvider);

  return switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((t) => !t.completed).toList(),
    TodoFilter.completed => todos.where((t) => t.completed).toList(),
  };
}

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

// Paginated data with family
@riverpod
class PaginatedPosts extends _$PaginatedPosts {
  @override
  Future<List<Post>> build(int page) async {
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts(page: page);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(page));
  }
}

class PaginatedView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageView.builder(
      itemBuilder: (context, index) {
        final posts = ref.watch(paginatedPostsProvider(index));
        return posts.when(
          data: (posts) => PostList(posts),
          loading: () => LoadingIndicator(),
          error: (err, _) => ErrorView(err),
        );
      },
    );
  }
}
```

## Summary

Riverpod provides a comprehensive solution for state management in Dart and Flutter applications with automatic dependency tracking, built-in caching, and robust async handling. The framework's primary use cases include API data fetching with automatic loading/error states, complex state management with business logic encapsulation, derived/computed state with automatic recomputation, and real-time data streams from WebSockets or Firebase. The reactive architecture ensures UI components automatically rebuild when dependencies change while maintaining performance through intelligent caching.

Integration patterns focus on separating concerns through repository patterns for data access, provider composition for dependent state, and Consumer widgets for UI reactivity. The framework supports code generation via `@riverpod` annotations to reduce boilerplate, provides ProviderScope for dependency injection and testing overrides, and includes lifecycle management with automatic disposal and cleanup. AsyncValue offers type-safe async state handling, while provider families enable parameterized instances with automatic caching. Testing is simplified through provider overrides and ProviderContainer for unit tests, making Riverpod suitable for applications ranging from simple counters to complex enterprise systems with multiple data sources and intricate state relationships.