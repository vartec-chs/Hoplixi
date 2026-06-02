import 'package:hoplixi/vault_db/core/api/vault_core_api.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';
import 'package:hoplixi/vault_db/models/session.dart';

abstract interface class IVaultSessionHolder {
  /// Текущая активная сессия (null, если хранилище закрыто)
  Session? get currentSession;

  /// Экземпляр открытой базы данных (null, если хранилище закрыто)
  VaultDB? get currentDB;

  /// API текущего открытого хранилища (null, если хранилище закрыто)
  VaultCoreApi? get currentApi;

  /// Путь к директории активного хранилища
  String? get currentStorePath;

  /// Указывает, открыто ли хранилище в данный момент
  bool get isStoreOpen;

  /// Стрим для реактивного отслеживания изменения сессии (для CLI/UI)
  Stream<Session?> get sessionStream;

  /// Установить текущую активную сессию
  void updateSession(Session session);

  /// Сбросить текущую сессию, если она совпадает с переданной
  void clearSessionIfMatches(Session session);

  /// Полностью сбросить текущую сессию
  void clearSession();
}
