import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/db_core/old/services/store_manifest_service.dart';
import 'package:path/path.dart' as p;

const int kStorePasswordAttemptBaseLimit = 5;
const int kStorePasswordAttemptMinLimit = 1;
const int kStorePasswordAttemptPenaltyDivisor = 2;
const Duration kStorePasswordAttemptBaseBlockDuration = Duration(minutes: 15);
const int kStorePasswordAttemptBlockDurationMultiplier = 2;

class StorePasswordAttemptStatus {
  const StorePasswordAttemptStatus({
    required this.failureCount,
    required this.maxAttempts,
    required this.penaltyLevel,
    this.blockedUntil,
  });

  final int failureCount;
  final int maxAttempts;
  final int penaltyLevel;
  final DateTime? blockedUntil;

  bool get isBlocked =>
      blockedUntil != null && blockedUntil!.isAfter(DateTime.now());

  int get remainingAttempts =>
      isBlocked ? 0 : math.max(0, maxAttempts - failureCount);

  Duration? get remainingBlockDuration {
    if (!isBlocked || blockedUntil == null) {
      return null;
    }
    return blockedUntil!.difference(DateTime.now());
  }
}

class StorePasswordAttemptLimiterService {
  StorePasswordAttemptLimiterService(this._secureStorage);

  static const String _storageKeyPrefix =
      'hoplixi_store_password_attempt_limiter_v1';

  final FlutterSecureStorage _secureStorage;

  Future<StorePasswordAttemptStatus> getStatus(String storePath) async {
    final identity = await _resolveIdentity(storePath);
    final record = await _readRecord(identity.storageKey);
    if (record == null) {
      return const StorePasswordAttemptStatus(
        failureCount: 0,
        maxAttempts: kStorePasswordAttemptBaseLimit,
        penaltyLevel: 0,
      );
    }

    final penaltyLevel = (record['penaltyLevel'] as num?)?.toInt() ?? 0;
    final blockedUntilRaw = record['blockedUntil'] as String?;
    final blockedUntil = blockedUntilRaw == null
        ? null
        : DateTime.tryParse(blockedUntilRaw);

    if (blockedUntil != null && !blockedUntil.isAfter(DateTime.now())) {
      await _writeRecord(
        identity: identity,
        failureCount: 0,
        penaltyLevel: penaltyLevel,
        blockedUntil: null,
      );
      return StorePasswordAttemptStatus(
        failureCount: 0,
        maxAttempts: _maxAttemptsForPenaltyLevel(penaltyLevel),
        penaltyLevel: penaltyLevel,
      );
    }

    return StorePasswordAttemptStatus(
      failureCount: (record['failureCount'] as num?)?.toInt() ?? 0,
      maxAttempts: _maxAttemptsForPenaltyLevel(penaltyLevel),
      penaltyLevel: penaltyLevel,
      blockedUntil: blockedUntil,
    );
  }

  Future<StorePasswordAttemptStatus> registerFailure(String storePath) async {
    final identity = await _resolveIdentity(storePath);
    final currentStatus = await getStatus(storePath);
    if (currentStatus.isBlocked) {
      return currentStatus;
    }

    final nextFailureCount = currentStatus.failureCount + 1;
    if (nextFailureCount >= currentStatus.maxAttempts) {
      final blockedUntil = DateTime.now().add(
        _blockDurationForPenaltyLevel(currentStatus.penaltyLevel),
      );
      final nextPenaltyLevel = currentStatus.penaltyLevel + 1;

      await _writeRecord(
        identity: identity,
        failureCount: 0,
        penaltyLevel: nextPenaltyLevel,
        blockedUntil: blockedUntil,
      );

      return StorePasswordAttemptStatus(
        failureCount: 0,
        maxAttempts: _maxAttemptsForPenaltyLevel(nextPenaltyLevel),
        penaltyLevel: nextPenaltyLevel,
        blockedUntil: blockedUntil,
      );
    }

    await _writeRecord(
      identity: identity,
      failureCount: nextFailureCount,
      penaltyLevel: currentStatus.penaltyLevel,
      blockedUntil: null,
    );

    return StorePasswordAttemptStatus(
      failureCount: nextFailureCount,
      maxAttempts: currentStatus.maxAttempts,
      penaltyLevel: currentStatus.penaltyLevel,
    );
  }

  Future<void> reset(String storePath) async {
    final identity = await _resolveIdentity(storePath);
    await _secureStorage.delete(key: identity.storageKey);
  }

  String buildBlockedDescription(StorePasswordAttemptStatus status) {
    final remaining = status.remainingBlockDuration;
    if (remaining == null) {
      return 'Ввод пароля временно заблокирован для этого хранилища.';
    }
    return 'Слишком много неверных попыток. Повторите через ${_formatDuration(remaining)}.';
  }

  String buildFailureDescription(StorePasswordAttemptStatus status) {
    if (status.isBlocked) {
      return buildBlockedDescription(status);
    }

    final remaining = status.remainingAttempts;
    return 'Осталось $remaining ${_pluralize(remaining, 'попытка', 'попытки', 'попыток')}.';
  }

  Future<Map<String, dynamic>?> _readRecord(String storageKey) async {
    final rawValue = await _secureStorage.read(key: storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  Future<void> _writeRecord({
    required _StorePasswordAttemptIdentity identity,
    required int failureCount,
    required int penaltyLevel,
    required DateTime? blockedUntil,
  }) {
    return _secureStorage.write(
      key: identity.storageKey,
      value: jsonEncode({
        'failureCount': failureCount,
        'penaltyLevel': penaltyLevel,
        'blockedUntil': blockedUntil?.toIso8601String(),
        'storeUuid': identity.storeUuid,
        'storeName': identity.storeName,
        'storePath': identity.storePath,
      }),
    );
  }

  Future<_StorePasswordAttemptIdentity> _resolveIdentity(
    String storePath,
  ) async {
    try {
      final manifest = await StoreManifestService.readFrom(storePath);
      final storeUuid = manifest?.storeUuid.trim();
      final manifestName = manifest?.storeName.trim();

      if (storeUuid != null && storeUuid.isNotEmpty) {
        return _StorePasswordAttemptIdentity(
          storageKey: '$_storageKeyPrefix:uuid:$storeUuid',
          storePath: storePath,
          storeUuid: storeUuid,
          storeName: manifestName?.isNotEmpty == true
              ? manifestName!
              : p.basename(storePath),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'StorePasswordAttemptLimiterService: failed to read manifest for $storePath: $error\n$stackTrace',
      );
    }

    final digest = sha256.convert(utf8.encode(storePath)).toString();
    return _StorePasswordAttemptIdentity(
      storageKey: '$_storageKeyPrefix:path:$digest',
      storePath: storePath,
      storeName: p.basename(storePath),
    );
  }

  int _maxAttemptsForPenaltyLevel(int penaltyLevel) {
    var attempts = kStorePasswordAttemptBaseLimit;
    for (var i = 0; i < penaltyLevel; i++) {
      attempts = math.max(
        kStorePasswordAttemptMinLimit,
        attempts ~/ kStorePasswordAttemptPenaltyDivisor,
      );
    }
    return attempts;
  }

  Duration _blockDurationForPenaltyLevel(int penaltyLevel) {
    var duration = kStorePasswordAttemptBaseBlockDuration;
    for (var i = 0; i < penaltyLevel; i++) {
      duration *= kStorePasswordAttemptBlockDurationMultiplier;
    }
    return duration;
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 60) {
      final seconds = math.max(1, duration.inSeconds);
      return '$seconds ${_pluralize(seconds, 'секунду', 'секунды', 'секунд')}';
    }

    if (duration.inMinutes < 60) {
      final minutes = math.max(1, duration.inMinutes.ceil());
      return '$minutes ${_pluralize(minutes, 'минуту', 'минуты', 'минут')}';
    }

    final hours = math.max(1, duration.inHours.ceil());
    return '$hours ${_pluralize(hours, 'час', 'часа', 'часов')}';
  }

  String _pluralize(int value, String one, String few, String many) {
    final mod10 = value % 10;
    final mod100 = value % 100;

    if (mod10 == 1 && mod100 != 11) {
      return one;
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return few;
    }
    return many;
  }
}

class _StorePasswordAttemptIdentity {
  const _StorePasswordAttemptIdentity({
    required this.storageKey,
    required this.storePath,
    required this.storeName,
    this.storeUuid,
  });

  final String storageKey;
  final String storePath;
  final String storeName;
  final String? storeUuid;
}
