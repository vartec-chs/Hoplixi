import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/builtin_app_credentials.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

/// Сервис хранения и чтения OAuth app credentials.
class AppCredentialsService {
  AppCredentialsService(this._hiveBoxManager);

  static const String _boxName = 'cloud_sync_app_credentials';
  static const String _logTag = 'AppCredentialsService';

  final HiveBoxManager _hiveBoxManager;
  Box<Map>? _box;

  /// Инициализирует зашифрованный Hive box модуля.
  Future<void> initialize() async {
    if (_box?.isOpen ?? false) {
      return;
    }

    _box = await _hiveBoxManager.openBox<Map>(_boxName);
    logInfo('App credentials box initialized', tag: _logTag);
  }

  /// Возвращает все builtin и пользовательские записи.
  Future<List<AppCredentialEntry>> getAll() async {
    _ensureInitialized();

    final entries = [...builtinAppCredentials, ..._readUserEntries()];

    return _sortEntries(entries);
  }

  /// Возвращает только встроенные записи.
  Future<List<AppCredentialEntry>> getBuiltinEntries() async {
    _ensureInitialized();
    return _sortEntries(builtinAppCredentials);
  }

  /// Возвращает только пользовательские записи.
  Future<List<AppCredentialEntry>> getUserEntries() async {
    _ensureInitialized();
    return _sortEntries(_readUserEntries());
  }

  /// Ищет запись по идентификатору среди builtin и пользовательских.
  Future<AppCredentialEntry?> getById(String id) async {
    _ensureInitialized();

    for (final entry in builtinAppCredentials) {
      if (entry.id == id) {
        return entry;
      }
    }

    final data = _box!.get(id);
    if (data == null) {
      return null;
    }

    return AppCredentialEntry.fromJson(Map<String, dynamic>.from(data));
  }

  /// Создаёт или обновляет пользовательскую запись.
  Future<AppCredentialEntry> upsertUserEntry(AppCredentialEntry entry) async {
    _ensureInitialized();

    if (entry.isBuiltin) {
      throw StateError('Builtin credentials are read-only.');
    }

    final existing = await getById(entry.id);
    if (existing?.isBuiltin == true) {
      throw StateError('Builtin credentials cannot be overwritten.');
    }

    final now = DateTime.now();
    final normalized = entry.copyWith(
      name: entry.name.trim(),
      clientId: entry.clientId.trim(),
      clientSecret: _normalizeSecret(entry.clientSecret),
      createdAt: existing?.createdAt ?? entry.createdAt ?? now,
      updatedAt: now,
    );

    await _box!.put(normalized.id, normalized.toJson());
    logInfo(
      'Saved app credentials: ${normalized.id} (${normalized.provider.id})',
      tag: _logTag,
    );

    return normalized;
  }

  /// Удаляет пользовательскую запись.
  Future<void> deleteUserEntry(String id) async {
    _ensureInitialized();

    final existing = await getById(id);
    if (existing == null) {
      return;
    }

    if (existing.isBuiltin) {
      throw StateError('Builtin credentials cannot be deleted.');
    }

    await _box!.delete(id);
    logInfo(
      'Deleted app credentials: ${existing.id} (${existing.provider.id})',
      tag: _logTag,
    );
  }

  /// Освобождает ресурсы сервиса.
  Future<void> dispose() async {
    if (!(_box?.isOpen ?? false)) {
      return;
    }

    await _hiveBoxManager.closeBox(_boxName);
    _box = null;
  }

  void _ensureInitialized() {
    if (_box == null || !(_box!.isOpen)) {
      throw StateError(
        'AppCredentialsService is not initialized. Call initialize() first.',
      );
    }
  }

  List<AppCredentialEntry> _readUserEntries() {
    final entries = <AppCredentialEntry>[];

    for (final raw in _box!.values) {
      try {
        final entry = AppCredentialEntry.fromJson(
          Map<String, dynamic>.from(raw),
        );
        entries.add(entry);
      } catch (error, stackTrace) {
        logError(
          'Failed to parse stored app credentials: $error',
          stackTrace: stackTrace,
          tag: _logTag,
        );
      }
    }

    return entries;
  }

  List<AppCredentialEntry> _sortEntries(List<AppCredentialEntry> entries) {
    final sorted = List<AppCredentialEntry>.from(entries);
    sorted.sort((left, right) {
      final providerCompare = left.provider.id.compareTo(right.provider.id);
      if (providerCompare != 0) {
        return providerCompare;
      }

      final builtinCompare = right.isBuiltin == left.isBuiltin
          ? 0
          : (left.isBuiltin ? -1 : 1);
      if (builtinCompare != 0) {
        return builtinCompare;
      }

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return sorted;
  }

  String? _normalizeSecret(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
