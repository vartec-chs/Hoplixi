import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hoplixi/core/services/services.dart';
import 'package:hoplixi/db_core/old/services/db_history_services.dart';
import 'package:hoplixi/features/password_generator/services/password_generator_profile_service.dart';
import 'package:hoplixi/features/password_manager/open_store/services/store_password_attempt_limiter_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_prefs/typed_prefs.dart';

import '../core/app_prefs/app_prefs.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // Инициализация FlutterSecureStorage
  final secureStorage = setupSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  final sharedPreferencesService = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferencesService);

  // Инициализация LocalAuthentication и LocalAuthService (до AppStorageService)
  final localAuth = LocalAuthentication();
  getIt.registerLazySingleton<LocalAuthentication>(() => localAuth);
  final localAuthService = LocalAuthService(localAuth);
  getIt.registerSingleton<LocalAuthService>(localAuthService);

  // Инициализация унифицированного сервиса хранения с поддержкой биометрии
  final appStorageService = await PreferencesService.initialize(
    secureStorage: secureStorage,
    sharedPreferences: sharedPreferencesService,
    writePolicies: {'biometric': BiometricAuthPolicy(localAuth)},
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
  getIt.registerLazySingleton<StorePasswordAttemptLimiterService>(
    () => StorePasswordAttemptLimiterService(getIt<FlutterSecureStorage>()),
  );
  getIt.registerLazySingleton<PasswordGeneratorProfileService>(
    PasswordGeneratorProfileService.new,
  );

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
