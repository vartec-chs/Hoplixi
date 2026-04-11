import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/setup/di_init.dart';
import 'package:hoplixi/features/local_send/models/history_item.dart';

final localSendHistoryServiceProvider = Provider<LocalSendHistoryService>((
  ref,
) {
  return LocalSendHistoryService();
});

class LocalSendHistoryService {
  static const String _boxName = 'local_send_history';
  static const String _historyKey = 'items';
  static const String _logTag = 'LocalSendHistoryService';

  LocalSendHistoryService() : _hiveBoxManager = getIt<HiveBoxManager>();

  final HiveBoxManager _hiveBoxManager;
  Box<List<dynamic>>? _box;

  Future<Box<List<dynamic>>> _getBox() async {
    if (_box?.isOpen ?? false) {
      return _box!;
    }

    _box = await _hiveBoxManager.openBox<List<dynamic>>(_boxName);
    return _box!;
  }

  Future<List<HistoryItem>> loadHistory() async {
    try {
      final box = await _getBox();
      final rawItems = box.get(_historyKey);
      if (rawItems is! List) {
        return [];
      }

      return rawItems
          .whereType<Map>()
          .map(
            (item) => HistoryItem.fromJson(
              item.map(
                (key, value) =>
                    MapEntry(key.toString(), _normalizeJsonValue(value)),
              ),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      logError(
        'Failed to load local send history: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
      return [];
    }
  }

  Future<void> saveHistory(List<HistoryItem> items) async {
    try {
      final box = await _getBox();
      final jsonList = items
          .map((item) => item.toJson())
          .toList(growable: false);
      await box.put(_historyKey, jsonList);
    } catch (error, stackTrace) {
      logError(
        'Failed to save local send history: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  Future<void> clearHistory() async {
    try {
      final box = await _getBox();
      await box.delete(_historyKey);
    } catch (error, stackTrace) {
      logError(
        'Failed to clear local send history: $error',
        stackTrace: stackTrace,
        tag: _logTag,
      );
    }
  }

  dynamic _normalizeJsonValue(Object? value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _normalizeJsonValue(nestedValue)),
      );
    }

    if (value is List) {
      return value.map(_normalizeJsonValue).toList(growable: false);
    }

    return value;
  }
}
