import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/models/db_state.dart';
import 'package:hoplixi/main_store/provider/main_store_provider.dart';

class DecryptedFilesGuardState {
  final Set<String> inUsePaths;
  final DateTime? lastCleanupAt;

  const DecryptedFilesGuardState({
    this.inUsePaths = const <String>{},
    this.lastCleanupAt,
  });

  DecryptedFilesGuardState copyWith({
    Set<String>? inUsePaths,
    DateTime? lastCleanupAt,
  }) {
    return DecryptedFilesGuardState(
      inUsePaths: inUsePaths ?? this.inUsePaths,
      lastCleanupAt: lastCleanupAt ?? this.lastCleanupAt,
    );
  }
}

final decryptedFilesGuardProvider =
    NotifierProvider<DecryptedFilesGuardNotifier, DecryptedFilesGuardState>(
      DecryptedFilesGuardNotifier.new,
    );

class DecryptedFilesGuardNotifier extends Notifier<DecryptedFilesGuardState> {
  static const String _logTag = 'DecryptedFilesGuard';
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _unusedFileMaxAge = Duration(minutes: 15);

  Timer? _cleanupTimer;
  bool _isCleanupInProgress = false;
  String? _lastKnownDecryptedPath;
  bool _hadOpenedSession = false;

  @override
  DecryptedFilesGuardState build() {
    ref.onDispose(_dispose);

    ref.listen(mainStoreProvider, (previous, next) {
      next.whenData((dbState) {
        unawaited(_handleDatabaseStateChanged(previous?.value, dbState));
      });
    });

    final currentDbState = ref.read(mainStoreProvider).value;
    if (currentDbState?.isOpen ?? false) {
      unawaited(_initWhenOpened());
    }

    return const DecryptedFilesGuardState();
  }

  Future<void> _handleDatabaseStateChanged(
    DatabaseState? previous,
    DatabaseState next,
  ) async {
    if (next.isOpen) {
      _hadOpenedSession = true;
      await _initWhenOpened();
      return;
    }

    final isStoreClosedOrLocked = next.isClosed || next.isLocked || next.isIdle;
    if (_hadOpenedSession && isStoreClosedOrLocked) {
      _stopCleanupTimer();
      await cleanupAllDecryptedFiles();
      _hadOpenedSession = false;
      return;
    }

    if (!next.isOpen) {
      _stopCleanupTimer();
    }
  }

  Future<void> _initWhenOpened() async {
    _startCleanupTimerIfNeeded();
    await _refreshDecryptedPath();
    await cleanupUnusedDecryptedFiles();
  }

  Future<void> _refreshDecryptedPath() async {
    final decryptedPath = await ref
        .read(mainStoreProvider.notifier)
        .getDecryptedAttachmentsPath();

    if (decryptedPath != null && decryptedPath.isNotEmpty) {
      _lastKnownDecryptedPath = decryptedPath;
    }
  }

  void registerFileInUse(String path) {
    if (path.isEmpty) return;

    final next = {...state.inUsePaths, path};
    state = state.copyWith(inUsePaths: next);
  }

  void unregisterFileInUse(String path) {
    if (path.isEmpty) return;

    final next = {...state.inUsePaths}..remove(path);
    state = state.copyWith(inUsePaths: next);
  }

  Future<void> cleanupUnusedDecryptedFiles() async {
    if (_isCleanupInProgress) return;

    _isCleanupInProgress = true;
    try {
      await _refreshDecryptedPath();
      final directoryPath = _lastKnownDecryptedPath;
      if (directoryPath == null || directoryPath.isEmpty) {
        return;
      }

      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return;
      }

      final now = DateTime.now();
      final inUse = state.inUsePaths;
      final existingInUse = <String>{};

      await for (final entity in directory.list(recursive: true)) {
        if (entity is! File) continue;

        final filePath = entity.path;
        if (inUse.contains(filePath)) {
          if (await entity.exists()) {
            existingInUse.add(filePath);
          }
          continue;
        }

        try {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          if (age >= _unusedFileMaxAge) {
            await entity.delete();
            logInfo('Deleted stale decrypted file: $filePath', tag: _logTag);
          }
        } catch (e) {
          logWarning(
            'Failed to process decrypted file: $filePath',

            tag: _logTag,
          );
        }
      }

      if (existingInUse.length != inUse.length) {
        state = state.copyWith(inUsePaths: existingInUse, lastCleanupAt: now);
      } else {
        state = state.copyWith(lastCleanupAt: now);
      }
    } finally {
      _isCleanupInProgress = false;
    }
  }

  Future<void> cleanupAllDecryptedFiles() async {
    await _refreshDecryptedPath();
    final directoryPath = _lastKnownDecryptedPath;
    if (directoryPath == null || directoryPath.isEmpty) {
      state = state.copyWith(
        inUsePaths: <String>{},
        lastCleanupAt: DateTime.now(),
      );
      return;
    }

    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      state = state.copyWith(
        inUsePaths: <String>{},
        lastCleanupAt: DateTime.now(),
      );
      return;
    }

    await for (final entity in directory.list(recursive: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (e) {
        logWarning(
          'Failed to delete decrypted entity: ${entity.path}',

          tag: _logTag,
        );
      }
    }

    state = state.copyWith(
      inUsePaths: <String>{},
      lastCleanupAt: DateTime.now(),
    );
    logInfo('All decrypted files were cleaned up', tag: _logTag);
  }

  void _startCleanupTimerIfNeeded() {
    if (_cleanupTimer != null) return;

    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      unawaited(cleanupUnusedDecryptedFiles());
    });
  }

  void _stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  void _dispose() {
    _stopCleanupTimer();
  }
}
