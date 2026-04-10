import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/db_core/models/store_key_config.dart';
import 'package:path/path.dart' as p;

/// Файловый сервис для чтения и записи [StoreKeyConfig].
class StoreKeyConfigService {
  static const String fileName = 'store_key.json';

  const StoreKeyConfigService._();

  /// Путь к файлу конфига для директории хранилища.
  static String configFilePath(String storageDir) => p.join(storageDir, fileName);

  /// Записать конфиг на диск в директорию [storageDir].
  static Future<void> writeTo(
    String storageDir,
    StoreKeyConfig config,
  ) async {
    final file = File(configFilePath(storageDir));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config.toJson()),
      flush: true,
    );
  }

  /// Прочитать конфиг из директории [storageDir].
  ///
  /// Возвращает `null`, если файл отсутствует.
  static Future<StoreKeyConfig?> readFrom(String storageDir) async {
    final file = File(configFilePath(storageDir));
    if (!await file.exists()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return StoreKeyConfig.fromJson(json);
  }

  /// Удалить файл конфига из директории [storageDir].
  static Future<void> deleteFrom(String storageDir) async {
    final file = File(configFilePath(storageDir));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

extension StoreKeyConfigPersistence on StoreKeyConfig {
  /// Сохранить конфиг в директории [storageDir].
  Future<void> writeTo(String storageDir) =>
      StoreKeyConfigService.writeTo(storageDir, this);
}
