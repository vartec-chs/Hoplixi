import 'package:op_wifi_utils/op_wifi_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:result_dart/result_dart.dart';
import 'package:universal_platform/universal_platform.dart';

class WifiOsBridge {
  const WifiOsBridge._();

  static bool get supportsWifiConnection =>
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  static AsyncResultDart<String, OpWifiUtilsError> getCurrentSsid() async {
    final permissionError = await _ensureLocationPermission();
    if (permissionError != null) {
      return Failure(permissionError);
    }

    final result = await OpWifiUtils.getCurrentSsid();
    if (!result.isSuccess) {
      return Failure(_extractError(result.error.type));
    }

    final ssid = normalizeSsid(result.data);
    if (ssid == null) {
      return const Failure(OpWifiUtilsError.unknownCurrentSsid);
    }

    return Success(ssid);
  }

  static AsyncResultDart<Unit, OpWifiUtilsError> connect({
    required String ssid,
    String? password,
    bool joinOnce = true,
  }) async {
    final normalizedSsid = normalizeSsid(ssid);
    if (normalizedSsid == null) {
      return const Failure(OpWifiUtilsError.ssidMissing);
    }

    final permissionError = await _ensureLocationPermission();
    if (permissionError != null) {
      return Failure(permissionError);
    }

    final result = await OpWifiUtils.connectToWifi(
      ssid: normalizedSsid,
      password: normalizePassword(password),
      joinOnce: joinOnce,
    );

    if (!result.isSuccess) {
      return Failure(_extractError(result.error.type));
    }

    return const Success(unit);
  }

  static String? normalizeSsid(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final unquoted = normalized.replaceAll(RegExp(r'^"+|"+$'), '');
    if (unquoted.isEmpty || unquoted == '<unknown ssid>') {
      return null;
    }

    return unquoted;
  }

  static String? normalizePassword(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String describeError(OpWifiUtilsError error) {
    switch (error) {
      case OpWifiUtilsError.invalidPassword:
        return 'Incorrect Wi-Fi password.';
      case OpWifiUtilsError.invalidSsid:
        return 'The SSID is invalid.';
      case OpWifiUtilsError.ssidMissing:
        return 'SSID is required.';
      case OpWifiUtilsError.alreadyConnected:
        return 'The device is already connected to this Wi-Fi network.';
      case OpWifiUtilsError.unsupportedPlatform:
        return 'Wi-Fi integration is only available on Android and iOS.';
      case OpWifiUtilsError.permissionRequired:
        return 'Location permission is required for Wi-Fi operations.';
      case OpWifiUtilsError.deviceLocationDisabled:
        return 'Enable device location services and try again.';
      case OpWifiUtilsError.unavailable:
        return 'Wi-Fi is currently unavailable. Try again in a moment.';
      case OpWifiUtilsError.readyTimeout:
        return 'Connection attempt timed out.';
      case OpWifiUtilsError.neHotspotUnknown:
        return 'iOS hotspot configuration failed.';
      case OpWifiUtilsError.osUnknown:
        return 'The operating system returned an unknown Wi-Fi error.';
      case OpWifiUtilsError.unknownCurrentSsid:
        return 'Unable to determine the current Wi-Fi network name.';
      case OpWifiUtilsError.unknownError:
        return 'Unknown Wi-Fi error.';
    }
  }

  static OpWifiUtilsError _extractError(Enum type) {
    return type is OpWifiUtilsError ? type : OpWifiUtilsError.unknownError;
  }

  static Future<OpWifiUtilsError?> _ensureLocationPermission() async {
    if (!supportsWifiConnection) {
      return OpWifiUtilsError.unsupportedPlatform;
    }

    final locationPermission = Permission.locationWhenInUse;
    final serviceStatus = await locationPermission.serviceStatus;
    if (serviceStatus != ServiceStatus.enabled) {
      return OpWifiUtilsError.deviceLocationDisabled;
    }

    var status = await locationPermission.status;
    if (status.isGranted) {
      return null;
    }

    status = await locationPermission.request();
    if (status.isGranted) {
      return null;
    }

    return OpWifiUtilsError.permissionRequired;
  }
}
