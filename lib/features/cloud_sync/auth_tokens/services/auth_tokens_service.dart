import 'package:hive_ce/hive.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/hive_box_manager.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

/// Сервис хранения OAuth токенов в зашифрованном Hive box.
class AuthTokensService {
  AuthTokensService(this._hiveBoxManager);

  static const String _boxName = 'cloud_sync_auth_tokens';
  static const String _logTag = 'AuthTokensService';

  final HiveBoxManager _hiveBoxManager;
  Box<Map>? _box;

  /// Инициализирует box токенов.
  Future<void> initialize() async {
    if (_box?.isOpen ?? false) {
      return;
    }

    _box = await _hiveBoxManager.openBox<Map>(_boxName);
    logInfo('Auth tokens box initialized', tag: _logTag);
  }

  /// Возвращает все токены.
  Future<List<AuthTokenEntry>> getAllTokens() async {
    _ensureInitialized();
    return _sortTokens(_readTokens());
  }

  /// Ищет токен по идентификатору.
  Future<AuthTokenEntry?> getTokenById(String id) async {
    _ensureInitialized();

    final data = _box!.get(id);
    if (data == null) {
      return null;
    }

    return AuthTokenEntry.fromJson(Map<String, dynamic>.from(data));
  }

  /// Возвращает все токены выбранного провайдера.
  Future<List<AuthTokenEntry>> getTokensByProvider(
    CloudSyncProvider provider,
  ) async {
    _ensureInitialized();

    return _sortTokens(
      _readTokens().where((token) => token.provider == provider).toList(),
    );
  }

  /// Сохраняет или обновляет токен.
  Future<AuthTokenEntry> upsertToken(AuthTokenEntry token) async {
    _ensureInitialized();

    final equivalent = _findEquivalentToken(token);
    final existing = await getTokenById(token.id) ?? equivalent;
    final now = DateTime.now();
    final normalized = token.copyWith(
      id: existing?.id ?? token.id,
      accessToken: token.accessToken.trim(),
      refreshToken: _normalizeValue(token.refreshToken),
      tokenType: _normalizeValue(token.tokenType),
      appCredentialId: _normalizeValue(token.appCredentialId),
      appCredentialName: _normalizeValue(token.appCredentialName),
      accountId: _normalizeValue(token.accountId),
      accountEmail: _normalizeValue(token.accountEmail),
      accountName: _normalizeValue(token.accountName),
      createdAt: existing?.createdAt ?? token.createdAt ?? now,
      updatedAt: now,
    );

    await _box!.put(normalized.id, normalized.toJson());
    logInfo(
      'Saved auth token: ${normalized.id} (${normalized.provider.id})',
      tag: _logTag,
    );

    return normalized;
  }

  /// Удаляет токен.
  Future<void> deleteToken(String id) async {
    _ensureInitialized();

    await _box!.delete(id);
    logInfo('Deleted auth token: $id', tag: _logTag);
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
        'AuthTokensService is not initialized. Call initialize() first.',
      );
    }
  }

  List<AuthTokenEntry> _readTokens() {
    final tokens = <AuthTokenEntry>[];

    for (final raw in _box!.values) {
      try {
        tokens.add(AuthTokenEntry.fromJson(Map<String, dynamic>.from(raw)));
      } catch (error, stackTrace) {
        logError(
          'Failed to parse auth token: $error',
          stackTrace: stackTrace,
          tag: _logTag,
        );
      }
    }

    return tokens;
  }

  AuthTokenEntry? _findEquivalentToken(AuthTokenEntry token) {
    final normalizedCredentialId = _normalizeValue(token.appCredentialId);
    final normalizedAccountId = _normalizeValue(token.accountId);
    final normalizedEmail = _normalizeEmail(token.accountEmail);

    if (normalizedAccountId == null && normalizedEmail == null) {
      return null;
    }

    for (final existing in _readTokens()) {
      if (existing.provider != token.provider) {
        continue;
      }

      final existingCredentialId = _normalizeValue(existing.appCredentialId);
      if (existingCredentialId != normalizedCredentialId) {
        continue;
      }

      final existingAccountId = _normalizeValue(existing.accountId);
      if (normalizedAccountId != null &&
          existingAccountId == normalizedAccountId) {
        return existing;
      }

      final existingEmail = _normalizeEmail(existing.accountEmail);
      if (normalizedEmail != null && existingEmail == normalizedEmail) {
        return existing;
      }
    }

    return null;
  }

  List<AuthTokenEntry> _sortTokens(List<AuthTokenEntry> tokens) {
    final sorted = List<AuthTokenEntry>.from(tokens);
    sorted.sort((left, right) {
      final leftDate = left.updatedAt ?? left.createdAt;
      final rightDate = right.updatedAt ?? right.createdAt;
      if (leftDate != null && rightDate != null) {
        return rightDate.compareTo(leftDate);
      }
      if (leftDate != null) {
        return -1;
      }
      if (rightDate != null) {
        return 1;
      }
      return left.displayLabel.compareTo(right.displayLabel);
    });
    return sorted;
  }

  String? _normalizeValue(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizeEmail(String? value) {
    final normalized = _normalizeValue(value);
    return normalized?.toLowerCase();
  }
}
