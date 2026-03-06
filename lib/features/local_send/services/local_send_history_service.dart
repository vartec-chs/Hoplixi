import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

final localSendHistoryServiceProvider = Provider<LocalSendHistoryService>((
  ref,
) {
  return LocalSendHistoryService();
});

class LocalSendHistoryService {
  static const _fileName = 'local_send_history.json';

  Future<File> _getFile() async {
    final dir = await path_provider.getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<HistoryItem>> loadHistory() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => HistoryItem.fromJson(e)).toList();
    } catch (e) {
      // Игнорируем ошибки чтения/парсинга и возвращаем пустой список
      return [];
    }
  }

  Future<void> saveHistory(List<HistoryItem> items) async {
    try {
      final file = await _getFile();
      final jsonList = items.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // Ошибка сохранения (можно залогировать)
    }
  }

  Future<void> clearHistory() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ошибка удаления
    }
  }
}
