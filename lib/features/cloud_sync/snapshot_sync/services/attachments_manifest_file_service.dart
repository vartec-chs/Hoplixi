import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/attachments_manifest.dart';
import 'package:path/path.dart' as p;

class AttachmentsManifestFileService {
  static const String fileName = 'attachments_manifest.json';

  const AttachmentsManifestFileService._();

  static String manifestFilePath(String storageDir) => p.join(storageDir, fileName);

  static Future<void> writeTo(
    String storageDir,
    AttachmentsManifest manifest,
  ) async {
    final file = File(manifestFilePath(storageDir));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
  }

  static Future<AttachmentsManifest?> readFrom(String storageDir) async {
    final file = File(manifestFilePath(storageDir));
    if (!await file.exists()) {
      return null;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return AttachmentsManifest.fromJson(json);
  }
}
