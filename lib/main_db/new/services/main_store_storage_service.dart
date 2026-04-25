import 'dart:io';

import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:path/path.dart' as p;

class MainStoreFileService {
  static const String _logTag = 'MainStoreFileService';

  static const String attachmentsFolder = 'attachments';
  static const String decryptedAttachmentsFolder = 'attachments_decrypted';

  const MainStoreFileService();

  String getAttachmentsPath(String storePath) {
    return p.join(storePath, attachmentsFolder);
  }

  String getDecryptedAttachmentsPath(String storePath) {
    return p.join(storePath, decryptedAttachmentsFolder);
  }

  Future<bool> storageDirectoryExists(String path) {
    return Directory(path).exists();
  }

  Future<void> deleteStorageDirectory(String path) async {
    await Directory(path).delete(recursive: true);
  }

  Future<String?> findDatabaseFile(String storagePath) async {
    try {
      final dir = Directory(storagePath);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File && file.path.endsWith(MainConstants.dbExtension)) {
          return file.path;
        }
      }

      return null;
    } catch (error, stackTrace) {
      logError(
        'Failed to find database file',
        error: error,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return null;
    }
  }
}
