/// Быстрый старт: HiveBoxManager
///
/// Основные операции для работы с зашифрованными Hive боксами
library;

import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/setup/di_init.dart';

/// Базовое использование
void quickStart() async {
  // 1. Получить менеджер (уже инициализирован в setupDI)
  final manager = getIt<HiveBoxManager>();

  // 2. Открыть бокс (ключ генерируется автоматически)
  final box = await manager.openBox<String>('my_data');

  // 3. Работа с данными
  await box.put('username', 'John');
  final username = box.get('username');
  print('Username: $username');

  // 4. Закрыть бокс
  await manager.closeBox('my_data');
}

/// Пользовательский ключ
void customKey() async {
  final manager = getIt<HiveBoxManager>();

  // Ваш собственный ключ шифрования (32 байта)
  final myKey = List<int>.generate(32, (i) => i);

  final box = await manager.openBox<Map>('secure_data', encryptionKey: myKey);

  await box.put('password', {'value': 'secret123'});
}

/// Lazy Box для больших данных
void lazyBoxUsage() async {
  final manager = getIt<HiveBoxManager>();

  // Данные не загружаются в память полностью
  final lazyBox = await manager.openLazyBox<String>('big_data');

  await lazyBox.put('file1', 'large content...');

  // Асинхронное чтение
  final content = await lazyBox.get('file1');
  print('Content: $content');
}

/// Бэкап и восстановление
void backupRestore() async {
  final manager = getIt<HiveBoxManager>();

  // БЭКАП: экспортировать ключ
  final key = await manager.exportBoxKey('important_box');
  // Сохраните key в облако или файл

  // ВОССТАНОВЛЕНИЕ: импортировать ключ
  await manager.importBoxKey('important_box', key!);

  // Теперь можно открыть бокс
  await manager.openBox('important_box');
}

/// Очистка и удаление
void cleanup() async {
  final manager = getIt<HiveBoxManager>();

  // Закрыть все боксы
  await manager.closeAll();

  // Удалить конкретный бокс
  await manager.deleteBox('temp_box');

  // Компактировать для освобождения места
  await manager.compactBox('data_box');
}

/// Список всех боксов
void listBoxes() async {
  final manager = getIt<HiveBoxManager>();

  final allBoxes = await manager.getAllBoxNames();
  print('Боксы: $allBoxes');
}
