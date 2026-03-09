import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_prefs/typed_prefs.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // Инициализация FlutterSecureStorage
  final secureStorage = setupSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  final sharedPreferencesService = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferencesService);

  // Инициализация LocalAuthentication и LocalAuthService (до AppStorageService)
  getIt.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
  final localAuthService = LocalAuthService(LocalAuthentication());
  getIt.registerSingleton<LocalAuthService>(localAuthService);

  // Инициализация унифицированного сервиса хранения с поддержкой биометрии
  final appStorageService = await PreferencesService.initialize(
    secureStorage: secureStorage,
    sharedPreferences: sharedPreferencesService,
  );

  getIt.registerSingleton<PreferencesService>(appStorageService);

  // Инициализация HiveBoxManager
  final hiveBoxManager = HiveBoxManager(getIt<FlutterSecureStorage>());
  await hiveBoxManager.initialize();
  getIt.registerSingleton<HiveBoxManager>(hiveBoxManager);

  // Инициализация DatabaseHistoryService
  final databaseHistoryService = DatabaseHistoryService();
  await databaseHistoryService.initialize();
  getIt.registerSingleton<DatabaseHistoryService>(databaseHistoryService);

  getIt.registerLazySingleton<LaunchAtStartupService>(
    LaunchAtStartupService.new,
  );
}

FlutterSecureStorage setupSecureStorage() {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(storageCipherAlgorithm: .AES_CBC_PKCS7Padding),
    iOptions: IOSOptions(accessibility: .first_unlock, synchronizable: false),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(),
    webOptions: WebOptions(),
  );
}
