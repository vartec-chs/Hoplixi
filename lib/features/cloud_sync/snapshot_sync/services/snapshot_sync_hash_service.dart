import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class SnapshotSyncHashService {
  const SnapshotSyncHashService();

  Future<String> sha256ForFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String sha256ForString(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  String sha256ForJson(Map<String, dynamic> json) {
    return sha256ForString(const JsonEncoder.withIndent('  ').convert(json));
  }
}
