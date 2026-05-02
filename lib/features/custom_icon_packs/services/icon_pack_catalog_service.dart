import 'dart:async';

import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_entry.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_summary.dart';
import 'package:hoplixi/rust/api/icon_pack_catalog_api.dart' as rust;
import 'package:hoplixi/rust/api/icon_pack_catalog_api/types.dart' as rust_types;

typedef IconPackImportProgress =
    void Function(int current, int total, String currentFile);

class IconPackCatalogService {
  const IconPackCatalogService({this.rootPath});

  static const String _logTag = 'IconPackCatalogService';
  static final RegExp _nativeErrorPattern = RegExp(
    r'ICON_PACK_ERROR\[(?<code>[a-z_]+)\]:\s*(?<message>.*)',
    dotAll: true,
  );

  final String? rootPath;

  static String normalizePackKey(String value) {
    var normalized = value.trim().toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    return normalized;
  }

  static String normalizeIconPathWithoutExtension(String value) {
    final normalizedPath = value.replaceAll('\\', '/').trim();
    final segments = normalizedPath
        .split('/')
        .map((segment) {
          var normalized = segment.trim().toLowerCase();
          normalized = normalized.replaceAll(RegExp(r'\s+'), '_');
          normalized = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
          return normalized;
        })
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return 'icon';
    }

    return segments.join('/');
  }

  Future<List<IconPackSummary>> listPacks() async {
    try {
      final rootPath = await _resolveRootPath();
      final packs = await rust.listPacks(rootPath: rootPath);
      return packs.map(_mapSummary).toList(growable: false);
    } catch (error, stackTrace) {
      logError(
        'Failed to read icon packs: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw _mapNativeException(
        error,
        fallbackCode: IconPackCatalogErrorCode.importFailed,
        fallbackMessage: 'Не удалось загрузить список паков.',
      );
    }
  }

  Future<IconPackSummary> importPack({
    required String archivePath,
    required String displayName,
    IconPackImportProgress? onProgress,
  }) async {
    try {
      final rootPath = await _resolveRootPath();
      final stream = rust.importPack(
        rootPath: rootPath,
        archivePath: archivePath,
        displayName: displayName,
      );

      await for (final event in stream) {
        final result = event.when(
          progress: (progress) {
            onProgress?.call(
              progress.current,
              progress.total,
              progress.currentFile,
            );
            return null;
          },
          done: (summary) => _mapSummary(summary),
          error: (error) {
            throw IconPackCatalogException(
              _parseErrorCode(error.code),
              error.message,
            );
          },
        );

        if (result != null) {
          return result;
        }
      }

      throw const IconPackCatalogException(
        IconPackCatalogErrorCode.importFailed,
        'Не удалось импортировать пак иконок.',
      );
    } catch (error, stackTrace) {
      if (error is IconPackCatalogException) {
        rethrow;
      }

      logError(
        'Failed to import icon pack from $archivePath: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw IconPackCatalogException(
        IconPackCatalogErrorCode.importFailed,
        'Не удалось импортировать пак иконок: ${error.toString()}',
      );
    }
  }

  Future<IconPackSummary> importDirectory({
    required String directoryPath,
    required String displayName,
    IconPackImportProgress? onProgress,
  }) async {
    try {
      final rootPath = await _resolveRootPath();
      final stream = rust.importDirectory(
        rootPath: rootPath,
        directoryPath: directoryPath,
        displayName: displayName,
      );

      await for (final event in stream) {
        final result = event.when(
          progress: (progress) {
            onProgress?.call(
              progress.current,
              progress.total,
              progress.currentFile,
            );
            return null;
          },
          done: (summary) => _mapSummary(summary),
          error: (error) {
            throw IconPackCatalogException(
              _parseErrorCode(error.code),
              error.message,
            );
          },
        );

        if (result != null) {
          return result;
        }
      }

      throw const IconPackCatalogException(
        IconPackCatalogErrorCode.importFailed,
        'Не удалось импортировать пак иконок.',
      );
    } catch (error, stackTrace) {
      if (error is IconPackCatalogException) {
        rethrow;
      }

      logError(
        'Failed to import icon pack from directory $directoryPath: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw IconPackCatalogException(
        IconPackCatalogErrorCode.importFailed,
        'Не удалось импортировать пак иконок из папки: ${error.toString()}',
      );
    }
  }

  Future<List<IconPackEntry>> listIcons({
    String? packKey,
    String query = '',
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      final rootPath = await _resolveRootPath();
      final entries = await rust.listIcons(
        rootPath: rootPath,
        packKey: packKey,
        query: query,
        offset: offset,
        limit: limit,
      );
      return entries.map(_mapEntry).toList(growable: false);
    } catch (error, stackTrace) {
      logError(
        'Failed to read icon pack entries: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw _mapNativeException(
        error,
        fallbackCode: IconPackCatalogErrorCode.importFailed,
        fallbackMessage: 'Не удалось загрузить список иконок.',
      );
    }
  }

  Future<void> deletePack(String packKey) async {
    try {
      final rootPath = await _resolveRootPath();
      await rust.deletePack(rootPath: rootPath, packKey: packKey);
    } catch (error, stackTrace) {
      logError(
        'Failed to delete icon pack $packKey: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw _mapNativeException(
        error,
        fallbackCode: IconPackCatalogErrorCode.deleteFailed,
        fallbackMessage: 'Не удалось удалить пак иконок.',
      );
    }
  }

  Future<String?> readSvgByKey(String iconKey) async {
    try {
      final rootPath = await _resolveRootPath();
      return await rust.readSvgByKey(rootPath: rootPath, iconKey: iconKey);
    } catch (error, stackTrace) {
      logError(
        'Failed to read icon pack SVG: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw _mapNativeException(
        error,
        fallbackCode: IconPackCatalogErrorCode.importFailed,
        fallbackMessage: 'Не удалось прочитать SVG-иконку.',
      );
    }
  }

  Future<String> _resolveRootPath() async {
    return rootPath ?? await AppPaths.iconPacksPath;
  }

  static IconPackSummary _mapSummary(rust_types.FrbIconPackSummary summary) {
    return IconPackSummary(
      packKey: summary.packKey,
      displayName: summary.displayName,
      sourceArchiveName: summary.sourceArchiveName,
      importedAt: DateTime.fromMillisecondsSinceEpoch(
        summary.importedAtMillis.toInt(),
        isUtc: true,
      ),
      iconCount: summary.iconCount,
    );
  }

  static IconPackEntry _mapEntry(rust_types.FrbIconPackEntry entry) {
    return IconPackEntry(
      key: entry.key,
      packKey: entry.packKey,
      packName: entry.packName,
      iconKey: entry.iconKey,
      name: entry.name,
      relativePath: entry.relativePath,
      svgPath: entry.svgPath,
      importedAt: DateTime.fromMillisecondsSinceEpoch(
        entry.importedAtMillis.toInt(),
        isUtc: true,
      ),
    );
  }

  static IconPackCatalogException _mapNativeException(
    Object error, {
    required IconPackCatalogErrorCode fallbackCode,
    required String fallbackMessage,
  }) {
    final message = error.toString();
    final match = _nativeErrorPattern.firstMatch(message);
    if (match != null) {
      return IconPackCatalogException(
        _parseErrorCode(match.namedGroup('code') ?? ''),
        match.namedGroup('message')?.trim().isNotEmpty == true
            ? match.namedGroup('message')!.trim()
            : fallbackMessage,
      );
    }

    return IconPackCatalogException(fallbackCode, fallbackMessage);
  }

  static IconPackCatalogErrorCode _parseErrorCode(String value) {
    return switch (value) {
      'duplicate_pack' => IconPackCatalogErrorCode.duplicatePack,
      'invalid_archive' => IconPackCatalogErrorCode.invalidArchive,
      'invalid_directory' => IconPackCatalogErrorCode.invalidDirectory,
      'invalid_pack_name' => IconPackCatalogErrorCode.invalidPackName,
      'no_svg_files' => IconPackCatalogErrorCode.noSvgFiles,
      'pack_not_found' => IconPackCatalogErrorCode.packNotFound,
      _ => IconPackCatalogErrorCode.importFailed,
    };
  }
}

class IconPackCatalogException implements Exception {
  const IconPackCatalogException(this.code, this.message);

  final IconPackCatalogErrorCode code;
  final String message;

  @override
  String toString() => 'IconPackCatalogException($code, $message)';
}

enum IconPackCatalogErrorCode {
  deleteFailed,
  duplicatePack,
  importFailed,
  invalidArchive,
  invalidDirectory,
  invalidPackName,
  noSvgFiles,
  packNotFound,
}
