import 'package:flutter/services.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/services/local_auth_failure.dart';
import 'package:local_auth/local_auth.dart';
import 'package:result_dart/result_dart.dart';
import 'package:universal_platform/universal_platform.dart';

class LocalAuthService {
  final LocalAuthentication _auth;

  LocalAuthService(this._auth);

  /// Проверяет, доступна ли биометрия на устройстве
  Future<bool> get isBiometricsAvailable async {
    if (UniversalPlatform.isWindows || UniversalPlatform.isLinux) {
      // На десктопах часто нет биометрии или она работает иначе,
      // но local_auth поддерживает Windows.
      // Проверим поддержку.
      return await _auth.isDeviceSupported();
    }

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e, s) {
      logError(
        'Error checking biometrics availability',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Получает список доступных методов биометрии
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e, s) {
      logError('Error getting available biometrics', error: e, stackTrace: s);
      return <BiometricType>[];
    }
  }

  /// Пытается аутентифицировать пользователя
  ///
  /// [localizedReason] - сообщение, которое увидит пользователь
  AsyncResultDart<bool, LocalAuthFailure> authenticate({
    required String localizedReason,
    bool sensitiveTransaction = false,
    bool persistAcrossBackgrounding = true,
    bool biometricOnly = false,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        sensitiveTransaction: sensitiveTransaction,
        persistAcrossBackgrounding: persistAcrossBackgrounding,
      );

      if (didAuthenticate) {
        return const Success(true);
      } else {
        // Пользователь отменил или не прошел проверку, но без исключения
        return const Failure(LocalAuthFailure.canceled());
      }
    } on LocalAuthException catch (e, s) {
      logError('Authentication error', error: e, stackTrace: s);

      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return const Failure(LocalAuthFailure.notAvailable());
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          return const Failure(LocalAuthFailure.notEnrolled());
        case LocalAuthExceptionCode.temporaryLockout:
          return const Failure(LocalAuthFailure.lockedOut());
        case LocalAuthExceptionCode.biometricLockout:
          return const Failure(LocalAuthFailure.permanentlyLockedOut());
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          return const Failure(LocalAuthFailure.canceled());
        case LocalAuthExceptionCode.timeout:
          return Failure(
            LocalAuthFailure.other(e.description ?? 'Authentication timeout'),
          );
        default:
          return Failure(
            LocalAuthFailure.other(
              e.description ?? 'Unknown authentication error',
            ),
          );
      }
    } on PlatformException catch (e, s) {
      logError(
        'Platform exception during authentication',
        error: e,
        stackTrace: s,
      );
      return Failure(LocalAuthFailure.other(e.message ?? 'Platform error'));
    } catch (e, s) {
      logError('Unknown authentication error', error: e, stackTrace: s);
      return Failure(LocalAuthFailure.other(e.toString()));
    }
  }

  /// Аутентифицирует пользователя только с помощью биометрии (без пина/пароля)
  ///
  /// [localizedReason] - сообщение, которое увидит пользователь
  AsyncResult<bool> authenticateBiometricOnly({
    required String localizedReason,
    bool sensitiveTransaction = false,
    bool persistAcrossBackgrounding = true,
  }) async {
    return authenticate(
      localizedReason: localizedReason,
      biometricOnly: true,
      sensitiveTransaction: sensitiveTransaction,
      persistAcrossBackgrounding: persistAcrossBackgrounding,
    );
  }

  /// Проверяет, доступна ли биометрия и настроена ли она на устройстве
  Future<bool> get isBiometricOnlyAvailable async {
    if (!await isBiometricsAvailable) {
      return false;
    }

    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }
}
