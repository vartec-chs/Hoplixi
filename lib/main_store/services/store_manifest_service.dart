import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/main_store/models/store_manifest.dart';
import 'package:path/path.dart' as p;

/// Файловый сервис для чтения и записи [StoreManifest].
class StoreManifestService {
  static const String fileName = 'store_manifest.json';

  const StoreManifestService._();

  /// Путь к файлу манифеста для директории хранилища.
  static String manifestFilePath(String storageDir) =>
      p.join(storageDir, fileName);

  /// Записать манифест на диск в директорию [storageDir].
  static Future<void> writeTo(
    String storageDir,
    StoreManifest manifest,
  ) async {
    final file = File(manifestFilePath(storageDir));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
  }

  /// Прочитать манифест из директории [storageDir].
  ///
  /// Возвращает `null`, если файл отсутствует.
  static Future<StoreManifest?> readFrom(String storageDir) async {
    final file = File(manifestFilePath(storageDir));
    if (!await file.exists()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return StoreManifest.fromJson(json);
  }

  /// Удалить файл манифеста из директории [storageDir].
  static Future<void> deleteFrom(String storageDir) async {
    final file = File(manifestFilePath(storageDir));
    if (await file.exists()) {
      await file.delete();
    }
  }
}

extension StoreManifestPersistence on StoreManifest {
  /// Сохранить манифест в директории [storageDir].
  Future<void> writeTo(String storageDir) =>
      StoreManifestService.writeTo(storageDir, this);
}
