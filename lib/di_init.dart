import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';
import 'package:local_auth/local_auth.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // Инициализация FlutterSecureStorage
  getIt.registerSingleton<FlutterSecureStorage>(setupSecureStorage());

  // Инициализация LocalAuthentication и LocalAuthService (до AppStorageService)
  getIt.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  final localAuthService = LocalAuthService(LocalAuthentication());
  getIt.registerSingleton<LocalAuthService>(localAuthService);

  // Инициализация унифицированного сервиса хранения с поддержкой биометрии
  final appStorageService = await AppStorageService.init(
    secureStorage: getIt<FlutterSecureStorage>(),
    localAuthService: localAuthService,
  );
  getIt.registerSingleton<AppStorageService>(appStorageService);

  // Инициализация HiveBoxManager
  final hiveBoxManager = HiveBoxManager(getIt<FlutterSecureStorage>());
  await hiveBoxManager.initialize();
  getIt.registerSingleton<HiveBoxManager>(hiveBoxManager);

  // Инициализация DatabaseHistoryService
  final databaseHistoryService = DatabaseHistoryService();
  await databaseHistoryService.initialize();
  getIt.registerSingleton<DatabaseHistoryService>(databaseHistoryService);
}

FlutterSecureStorage setupSecureStorage() {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(),
    webOptions: WebOptions(),
  );
}
