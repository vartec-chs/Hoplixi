WARNING (drift): It looks like you've created the database class MainStore
multiple times. When these two databases use the same QueryExecutor, race
conditions will occur and might corrupt the database. Try to follow the advice
at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what
you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true Here
is the stacktrace from when the database was opened a second time: #0
GeneratedDatabase._handleInstantiated
(package:drift/src/runtime/api/db_base.dart:96:30) db_base.dart:96 #1
GeneratedDatabase.\_whenConstructed
(package:drift/src/runtime/api/db_base.dart:73:12) db_base.dart:73 #2 new
GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
db_base.dart:64 #3 new _$MainStore
(package:hoplixi/main_store/main_store.g.dart:15379:34) main_store.g.dart:15379
#4 new MainStore (package:hoplixi/main_store/main_store.dart) #5
MainStoreManager.\_createDatabaseConnection
(package:hoplixi/main_store/main_store_manager.dart:758:24)
main_store_manager.dart:758 #6 MainStoreManager.openStore
(package:hoplixi/main_store/main_store_manager.dart:250:30)
main_store_manager.dart:250 <asynchronous suspension> #7
MainStoreAsyncNotifier.openStore
(package:hoplixi/main_store/provider/main_store_provider.dart:211:22)
main_store_provider.dart:211 <asynchronous suspension> #8
RecentDatabaseCard.\_openDatabase
(package:hoplixi/features/home/widgets/recent_database_card.dart:123:21)
recent_database_card.dart:123 <asynchronous suspension> This warning will only
appear on debug builds.
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ #0 AppLogger.\_log (package:hoplixi/core/logger/app_logger.dart:223:26)
app_logger.dart:223 │ #1 AppLogger.info
(package:hoplixi/core/logger/app_logger.dart:121:5) app_logger.dart:121
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 2025-12-29 23:10:34.648
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ ℹ️ [MainStore] Installing triggers...
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ #0 AppLogger.\_log (package:hoplixi/core/logger/app_logger.dart:223:26)
app_logger.dart:223 │ #1 AppLogger.info
(package:hoplixi/core/logger/app_logger.dart:121:5) app_logger.dart:121
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 2025-12-29 23:10:34.649
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ ℹ️ [MainStore] Installing triggers...
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ SqliteException(5): while executing, database is locked, database is locked
(code 5) │ Causing statement: DROP TRIGGER IF EXISTS password_update_history;,
parameters:
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ #0 package:sqlite3/src/implementation/exception.dart 95:3 throwException
exception.dart:95 │ #1 package:sqlite3/src/implementation/database.dart 306:9
DatabaseImplementation.execute database.dart:306 │ #2
package:drift/src/sqlite3/database.dart 145:16 Sqlite3Delegate.runWithArgsSync
database.dart:145 │ #3 package:drift/native.dart 425:30
\_NativeDelegate.runCustom.<fn> native.dart:425 │ #4 package:drift/native.dart
425:19 \_NativeDelegate.runCustom native.dart:425 │ #5
package:drift/src/runtime/executor/helpers/engines.dart 116:19
\_BaseExecutor.runCustom.<fn> engines.dart:116 │ #6
package:drift/src/runtime/executor/helpers/engines.dart 62:20
\_BaseExecutor.\_synchronized engines.dart:62 │ #7
package:drift/src/runtime/executor/helpers/engines.dart 112:12
\_BaseExecutor.runCustom engines.dart:112
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 2025-12-29 23:10:34.665
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ ❌ [MainStore] Failed to install triggers
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ #0 AppLogger.\_log (package:hoplixi/core/logger/app_logger.dart:229:26)
app_logger.dart:229 │ #1 AppLogger.error
(package:hoplixi/core/logger/app_logger.dart:156:5) app_logger.dart:156
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ 2025-12-29 23:10:34.743
├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
│ ❌ [MainStoreManager] Failed to verify database connection:
SqliteException(5): while executing, database is locked, database is locked
(code 5) │ ❌ Causing statement: DROP TRIGGER IF EXISTS
password_update_history;, parameters:
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
