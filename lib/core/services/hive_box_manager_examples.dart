/// Примеры использования HiveBoxManager
///
/// Этот файл содержит примеры использования HiveBoxManager
/// для работы с зашифрованными Hive боксами
library;

import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hive_ce/hive.dart';

/// Пример 1: Открытие бокса с автоматической генерацией ключа
Future<void> exampleAutoEncryption() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Открыть бокс с автоматической генерацией и сохранением ключа
  final box = await hiveManager.openBox<String>('my_box');

  // Использование бокса
  await box.put('key', 'value');
  final value = box.get('key');
  print(value); // 'value'

  // Закрыть бокс
  await hiveManager.closeBox('my_box');
}

/// Пример 2: Открытие бокса с пользовательским ключом
Future<void> exampleCustomEncryption() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Создать свой ключ (32 байта для AES-256)
  final customKey = List<int>.generate(32, (index) => index);

  // Открыть бокс с пользовательским ключом
  final box = await hiveManager.openBox<Map>(
    'secure_box',
    encryptionKey: customKey,
  );

  // Использование бокса
  await box.put('user', {'name': 'John', 'age': 30});
  final user = box.get('user');
  print(user); // {name: John, age: 30}

  await hiveManager.closeBox('secure_box');
}

/// Пример 3: Работа с ленивым боксом (LazyBox)
/// Ленивые боксы не загружают все данные в память сразу
Future<void> exampleLazyBox() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Открыть ленивый бокс
  final lazyBox = await hiveManager.openLazyBox<String>('lazy_box');

  // Записать данные
  await lazyBox.put('large_data', 'Very large string...');

  // Прочитать данные (загрузка по требованию)
  final data = await lazyBox.get('large_data');
  print(data);

  await hiveManager.closeBox('lazy_box');
}

/// Пример 4: Управление несколькими боксами
Future<void> exampleMultipleBoxes() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Открыть несколько боксов
  final userBox = await hiveManager.openBox<Map>('users');
  final settingsBox = await hiveManager.openBox<dynamic>('settings');
  final cacheBox = await hiveManager.openBox<String>('cache');

  // Работа с разными боксами
  await userBox.put('user1', {'name': 'Alice'});
  await settingsBox.put('theme', 'dark');
  await cacheBox.put('data', 'cached data');

  // Получить открытый бокс
  final existingBox = hiveManager.getBox<Map>('users');
  print(existingBox.get('user1')); // {name: Alice}

  // Проверить, открыт ли бокс
  print(hiveManager.isBoxOpen('users')); // true

  // Закрыть все боксы
  await hiveManager.closeAll();
}

/// Пример 5: Удаление бокса
Future<void> exampleDeleteBox() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Открыть и использовать бокс
  final box = await hiveManager.openBox<String>('temp_box');
  await box.put('temp', 'temporary data');

  // Удалить бокс и его ключ шифрования
  await hiveManager.deleteBox('temp_box');

  // Проверить, существует ли бокс
  final exists = await hiveManager.boxExists('temp_box');
  print(exists); // false
}

/// Пример 6: Экспорт и импорт ключей шифрования
Future<void> exampleBackupAndRestore() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Создать бокс
  final box = await hiveManager.openBox<String>('important_box');
  await box.put('important', 'critical data');
  await hiveManager.closeBox('important_box');

  // Экспортировать ключ для бэкапа
  final exportedKey = await hiveManager.exportBoxKey('important_box');
  print('Exported key: $exportedKey');
  // Сохранить этот ключ в безопасном месте

  // В другом месте или после переустановки приложения:
  // Импортировать ключ
  await hiveManager.importBoxKey('important_box', exportedKey!);

  // Теперь можно открыть бокс с восстановленным ключом
  final restoredBox = await hiveManager.openBox<String>('important_box');
  print(restoredBox.get('important')); // critical data
}

/// Пример 7: Компактирование бокса
/// Компактирование удаляет неиспользуемое пространство
Future<void> exampleCompaction() async {
  final hiveManager = getIt<HiveBoxManager>();

  final box = await hiveManager.openBox<String>('data_box');

  // Добавить и удалить много данных
  for (var i = 0; i < 1000; i++) {
    await box.put('key_$i', 'value_$i');
  }
  for (var i = 0; i < 500; i++) {
    await box.delete('key_$i');
  }

  // Компактировать бокс для освобождения места
  await hiveManager.compactBox('data_box');

  await hiveManager.closeBox('data_box');
}

/// Пример 8: Получение списка всех боксов
Future<void> exampleListAllBoxes() async {
  final hiveManager = getIt<HiveBoxManager>();

  // Создать несколько боксов
  await hiveManager.openBox('box1');
  await hiveManager.openBox('box2');
  await hiveManager.openBox('box3');

  // Получить список всех боксов
  final allBoxNames = await hiveManager.getAllBoxNames();
  print('All boxes: $allBoxNames'); // [box1, box2, box3]

  // Закрыть все
  await hiveManager.closeAll();
}

/// Пример 9: Использование в модели данных
class UserPreferences {
  static const String _boxName = 'user_preferences';
  final HiveBoxManager _manager;
  Box<dynamic>? _box;

  UserPreferences(this._manager);

  Future<void> initialize() async {
    _box = await _manager.openBox(_boxName);
  }

  Future<void> setTheme(String theme) async {
    await _box?.put('theme', theme);
  }

  String? getTheme() {
    return _box?.get('theme');
  }

  Future<void> setLanguage(String language) async {
    await _box?.put('language', language);
  }

  String? getLanguage() {
    return _box?.get('language', defaultValue: 'en');
  }

  Future<void> close() async {
    await _manager.closeBox(_boxName);
  }
}

/// Использование класса UserPreferences
Future<void> exampleUserPreferences() async {
  final hiveManager = getIt<HiveBoxManager>();
  final prefs = UserPreferences(hiveManager);

  await prefs.initialize();

  await prefs.setTheme('dark');
  await prefs.setLanguage('ru');

  print('Theme: ${prefs.getTheme()}'); // Theme: dark
  print('Language: ${prefs.getLanguage()}'); // Language: ru

  await prefs.close();
}

/// Пример 10: Обработка ошибок
Future<void> exampleErrorHandling() async {
  final hiveManager = getIt<HiveBoxManager>();

  try {
    // Попытка получить неоткрытый бокс
    hiveManager.getBox('non_existent_box');
  } catch (e) {
    print('Error: $e'); // StateError: Box non_existent_box is not open
  }

  try {
    // Открыть бокс
    await hiveManager.openBox('test_box');

    // Попытка удалить открытый бокс (менеджер автоматически закроет его)
    await hiveManager.deleteBox('test_box');

    // Успешно удалено
    print('Box deleted successfully');
  } catch (e) {
    print('Error deleting box: $e');
  }
}
