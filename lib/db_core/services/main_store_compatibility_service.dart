import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:hoplixi/db_core/models/store_manifest.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainStoreCompatibilityService {
  const MainStoreCompatibilityService();

  Future<StoreOpenCompatibility> checkOpenCompatibility(
    StoreManifest? manifest,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentAppVersion =
        packageInfo.version +
        (packageInfo.buildNumber.isNotEmpty
            ? '+${packageInfo.buildNumber}'
            : '');
    const currentManifestVersion = MainConstants.storeManifestVersion;
    const currentSchemaVersion = MainConstants.databaseSchemaVersion;

    if (manifest == null) {
      return const StoreOpenCompatibility(
        currentManifestVersion: currentManifestVersion,
        currentSchemaVersion: currentSchemaVersion,
        currentAppVersion: '',
      );
    }

    final storeManifestVersion = manifest.manifestVersion;
    final storeSchemaVersion = manifest.lastMigrationVersion;
    final storeAppVersion = manifest.appVersion?.trim();
    final appVersionComparison = _compareAppVersions(
      storeAppVersion,
      currentAppVersion,
    );

    final manifestVersionTooNew = storeManifestVersion > currentManifestVersion;
    final schemaVersionTooNew =
        storeSchemaVersion != null && storeSchemaVersion > currentSchemaVersion;
    final appVersionTooNew = appVersionComparison > 0;

    final requiresMigration =
        !manifestVersionTooNew &&
        !schemaVersionTooNew &&
        !appVersionTooNew &&
        (storeManifestVersion < currentManifestVersion ||
            storeSchemaVersion == null ||
            storeSchemaVersion < currentSchemaVersion ||
            storeAppVersion == null ||
            storeAppVersion.isEmpty ||
            appVersionComparison < 0);

    return StoreOpenCompatibility(
      currentManifestVersion: currentManifestVersion,
      storeManifestVersion: storeManifestVersion,
      currentSchemaVersion: currentSchemaVersion,
      storeSchemaVersion: storeSchemaVersion,
      currentAppVersion: currentAppVersion,
      storeAppVersion: storeAppVersion,
      requiresMigration: requiresMigration,
      manifestVersionTooNew: manifestVersionTooNew,
      schemaVersionTooNew: schemaVersionTooNew,
      appVersionTooNew: appVersionTooNew,
    );
  }

  DatabaseError? buildCompatibilityError({
    required StoreOpenCompatibility compatibility,
    required String storagePath,
    required bool allowMigration,
  }) {
    if (compatibility.blocksOpen) {
      final reasons = <String>[];

      if (compatibility.manifestVersionTooNew) {
        reasons.add(
          'Версия manifest (${compatibility.storeManifestVersion}) новее поддерживаемой (${compatibility.currentManifestVersion})',
        );
      }
      if (compatibility.schemaVersionTooNew) {
        reasons.add(
          'Версия схемы данных (${compatibility.storeSchemaVersion}) новее поддерживаемой (${compatibility.currentSchemaVersion})',
        );
      }
      if (compatibility.appVersionTooNew) {
        reasons.add(
          'Store был обновлён в версии приложения ${compatibility.storeAppVersion}, а текущая версия приложения ${compatibility.currentAppVersion}',
        );
      }

      return DatabaseError.migrationFailed(
        code: 'DB_STORE_VERSION_TOO_NEW',
        message:
            'Открытие невозможно: ${reasons.join('. ')}. Используйте более новую версию приложения.',
        data: compatibility.toErrorData(storagePath),
        timestamp: DateTime.now(),
      );
    }

    if (compatibility.requiresMigration && !allowMigration) {
      return DatabaseError.migrationFailed(
        code: 'DB_STORE_MIGRATION_REQUIRED',
        message:
            'Хранилище требует миграции перед открытием. Сначала создайте backup, затем выполните миграцию на текущие версии приложения и схемы.',
        data: compatibility.toErrorData(storagePath),
        timestamp: DateTime.now(),
      );
    }

    return null;
  }
}

class StoreOpenCompatibility {
  const StoreOpenCompatibility({
    required this.currentManifestVersion,
    required this.currentSchemaVersion,
    required this.currentAppVersion,
    this.storeManifestVersion,
    this.storeSchemaVersion,
    this.storeAppVersion,
    this.requiresMigration = false,
    this.manifestVersionTooNew = false,
    this.schemaVersionTooNew = false,
    this.appVersionTooNew = false,
  });

  final int currentManifestVersion;
  final int? storeManifestVersion;
  final int currentSchemaVersion;
  final int? storeSchemaVersion;
  final String currentAppVersion;
  final String? storeAppVersion;
  final bool requiresMigration;
  final bool manifestVersionTooNew;
  final bool schemaVersionTooNew;
  final bool appVersionTooNew;

  bool get blocksOpen =>
      manifestVersionTooNew || schemaVersionTooNew || appVersionTooNew;

  Map<String, dynamic> toErrorData(String storagePath) {
    return <String, dynamic>{
      'path': storagePath,
      'currentManifestVersion': currentManifestVersion,
      'storeManifestVersion': storeManifestVersion,
      'currentSchemaVersion': currentSchemaVersion,
      'storeSchemaVersion': storeSchemaVersion,
      'currentAppVersion': currentAppVersion,
      'storeAppVersion': storeAppVersion,
      'requiresMigration': requiresMigration,
      'manifestVersionTooNew': manifestVersionTooNew,
      'schemaVersionTooNew': schemaVersionTooNew,
      'appVersionTooNew': appVersionTooNew,
    };
  }
}

int _compareAppVersions(String? left, String? right) {
  final leftSegments = _parseVersionSegments(left);
  final rightSegments = _parseVersionSegments(right);
  final maxLength = leftSegments.length > rightSegments.length
      ? leftSegments.length
      : rightSegments.length;

  for (var index = 0; index < maxLength; index++) {
    final leftValue = index < leftSegments.length ? leftSegments[index] : 0;
    final rightValue = index < rightSegments.length ? rightSegments[index] : 0;
    if (leftValue != rightValue) {
      return leftValue.compareTo(rightValue);
    }
  }

  return 0;
}

List<int> _parseVersionSegments(String? value) {
  if (value == null || value.trim().isEmpty) {
    return const <int>[0];
  }

  // Build metadata ("+<build>") does not affect semantic version precedence.
  final normalizedValue = _normalizeComparableVersion(value);
  final matches = RegExp(r'\d+').allMatches(normalizedValue);
  final segments = <int>[];
  for (final match in matches) {
    final parsed = int.tryParse(match.group(0) ?? '');
    if (parsed != null) {
      segments.add(parsed);
    }
  }

  return segments.isEmpty ? const <int>[0] : segments;
}

String _normalizeComparableVersion(String value) {
  return value.trim().split('+').first.trim();
}
