import 'dart:async';

import 'package:hoplixi/vault_db/core/api/vault_core_api.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'ivault_session_holder.dart';

class VaultSessionHolder implements IVaultSessionHolder {
  final StreamController<Session?> _sessionController =
      StreamController<Session?>.broadcast();

  Session? _currentSession;

  @override
  Session? get currentSession => _currentSession;

  @override
  VaultCoreApi? get currentApi => _currentSession?.api;

  @override
  VaultDB? get currentDB => currentApi?.db;

  @override
  String? get currentStorePath => _currentSession?.storeDirectoryPath;

  @override
  bool get isStoreOpen => currentApi != null && _currentSession != null;

  @override
  Stream<Session?> get sessionStream => _sessionController.stream;

  @override
  void updateSession(Session session) {
    _currentSession = session;
    _sessionController.add(session);
  }

  @override
  void clearSessionIfMatches(Session session) {
    if (_currentSession == null) {
      return;
    }

    final isSameStorePath =
        _currentSession!.storeDirectoryPath == session.storeDirectoryPath;
    final isSameStoreInstance = identical(currentDB, session.api.db);

    if (isSameStorePath || isSameStoreInstance) {
      clearSession();
    }
  }

  @override
  void clearSession() {
    _currentSession = null;
    _sessionController.add(null);
  }

  /// Освобождение ресурсов при уничтожении
  void dispose() {
    _sessionController.close();
  }
}
