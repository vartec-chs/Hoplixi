import 'dart:async';

import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';
import 'ivault_session_holder.dart';

class VaultSessionHolder implements IVaultSessionHolder {
  final StreamController<Session?> _sessionController =
      StreamController<Session?>.broadcast();

  VaultDB? _currentDB;
  Session? _currentSession;

  @override
  Session? get currentSession => _currentSession;

  @override
  VaultDB? get currentDB => _currentDB;

  @override
  String? get currentStorePath => _currentSession?.storeDirectoryPath;

  @override
  bool get isStoreOpen => _currentDB != null && _currentSession != null;

  @override
  Stream<Session?> get sessionStream => _sessionController.stream;

  @override
  void updateSession(Session session) {
    _currentDB = session.store;
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
    final isSameStoreInstance = identical(_currentDB, session.store);

    if (isSameStorePath || isSameStoreInstance) {
      clearSession();
    }
  }

  @override
  void clearSession() {
    _currentDB = null;
    _currentSession = null;
    _sessionController.add(null);
  }

  /// Освобождение ресурсов при уничтожении
  void dispose() {
    _sessionController.close();
  }
}
