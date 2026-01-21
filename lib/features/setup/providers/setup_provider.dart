import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/theme/theme_provider.dart';
import 'package:hoplixi/di_init.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

/// Состояние мастера настройки
class SetupState {
  final int currentPage;
  final int totalPages;
  final ThemeMode selectedTheme;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final Map<Permission, PermissionStatus> permissionStatuses;
  final bool allPermissionsGranted;
  final bool isLoading;

  const SetupState({
    this.currentPage = 0,
    this.totalPages = 4,
    this.selectedTheme = ThemeMode.system,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.permissionStatuses = const {},
    this.allPermissionsGranted = false,
    this.isLoading = false,
  });

  SetupState copyWith({
    int? currentPage,
    int? totalPages,
    ThemeMode? selectedTheme,
    bool? biometricEnabled,
    bool? biometricAvailable,
    Map<Permission, PermissionStatus>? permissionStatuses,
    bool? allPermissionsGranted,
    bool? isLoading,
  }) {
    return SetupState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      permissionStatuses: permissionStatuses ?? this.permissionStatuses,
      allPermissionsGranted:
          allPermissionsGranted ?? this.allPermissionsGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Можно ли перейти на следующую страницу
  bool get canGoNext => currentPage < totalPages - 1;

  /// Можно ли вернуться назад
  bool get canGoBack => currentPage > 0;

  /// Последняя страница
  bool get isLastPage => currentPage == totalPages - 1;

  /// Первая страница
  bool get isFirstPage => currentPage == 0;
}

/// Провайдер состояния мастера настройки
class SetupNotifier extends Notifier<SetupState> {
  late final LocalAuthentication _localAuth;
  late final AppStorageService _storage;

  /// Требуемые разрешения для мобильных платформ
  static const List<Permission> requiredPermissions = [
    Permission.camera,
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.audio,
    Permission.manageExternalStorage,
  ];

  @override
  SetupState build() {
    _localAuth = LocalAuthentication();
    _storage = getIt<AppStorageService>();

    // Определяем количество страниц в зависимости от платформы
    final totalPages = UniversalPlatform.isDesktop ? 3 : 4;

    // Отложенная инициализация после возврата начального состояния
    Future.microtask(() => _initializeState());

    return SetupState(totalPages: totalPages);
  }

  /// Инициализация состояния
  Future<void> _initializeState() async {
    state = state.copyWith(isLoading: true);

    // Проверяем доступность биометрии
    final biometricAvailable = await _checkBiometricAvailability();

    // Загружаем текущую тему
    final themeAsync = ref.read(themeProvider);
    final currentTheme = themeAsync.value ?? ThemeMode.system;

    // Проверяем разрешения (только для мобильных)
    Map<Permission, PermissionStatus> permissionStatuses = {};
    if (!UniversalPlatform.isDesktop) {
      permissionStatuses = await _checkPermissions();
    }

    final allPermissionsGranted = permissionStatuses.values.every(
      (s) => s.isGranted,
    );

    state = state.copyWith(
      biometricAvailable: biometricAvailable,
      selectedTheme: currentTheme,
      permissionStatuses: permissionStatuses,
      allPermissionsGranted: allPermissionsGranted,
      isLoading: false,
    );
  }

  /// Проверка доступности биометрии
  Future<bool> _checkBiometricAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Проверка статуса разрешений
  Future<Map<Permission, PermissionStatus>> _checkPermissions() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in requiredPermissions) {
      statuses[permission] = await permission.status;
    }
    return statuses;
  }

  /// Перейти на следующую страницу
  void nextPage() {
    if (state.canGoNext) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Перейти на предыдущую страницу
  void previousPage() {
    if (state.canGoBack) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Перейти на конкретную страницу
  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  /// Установить тему
  Future<void> setTheme(ThemeMode themeMode) async {
    state = state.copyWith(selectedTheme: themeMode);

    final themeNotifier = ref.read(themeProvider.notifier);
    switch (themeMode) {
      case ThemeMode.light:
        await themeNotifier.setLightTheme();
        break;
      case ThemeMode.dark:
        await themeNotifier.setDarkTheme();
        break;
      case ThemeMode.system:
        await themeNotifier.setSystemTheme();
        break;
    }
  }

  /// Включить/выключить биометрию
  Future<void> setBiometric(bool enabled) async {
    if (!state.biometricAvailable) return;

    if (enabled) {
      // Попытка аутентификации для подтверждения
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Подтвердите включение биометрии',
        );

        if (authenticated) {
          await _storage.set(AppKeys.biometricEnabled, true);
          state = state.copyWith(biometricEnabled: true);
        }
      } catch (e) {
        // Аутентификация не удалась
      }
    } else {
      await _storage.set(AppKeys.biometricEnabled, false);
      state = state.copyWith(biometricEnabled: false);
    }
  }

  /// Запросить разрешение
  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();
    final updatedStatuses = Map<Permission, PermissionStatus>.from(
      state.permissionStatuses,
    );
    updatedStatuses[permission] = status;

    final allGranted = updatedStatuses.values.every((s) => s.isGranted);

    state = state.copyWith(
      permissionStatuses: updatedStatuses,
      allPermissionsGranted: allGranted,
    );
  }

  /// Запросить все разрешения
  Future<void> requestAllPermissions() async {
    state = state.copyWith(isLoading: true);

    final statuses = await requiredPermissions.request();

    final allGranted = statuses.values.every((s) => s.isGranted);

    state = state.copyWith(
      permissionStatuses: statuses,
      allPermissionsGranted: allGranted,
      isLoading: false,
    );
  }

  /// Завершить настройку
  Future<void> completeSetup() async {
    await _storage.set(AppKeys.setupCompleted, true);
  }
}

/// Провайдер для мастера настройки
final setupProvider = NotifierProvider<SetupNotifier, SetupState>(
  SetupNotifier.new,
);
