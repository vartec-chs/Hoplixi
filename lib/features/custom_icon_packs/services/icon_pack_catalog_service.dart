import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/logger/index.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_entry.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_manifest.dart';
import 'package:hoplixi/features/custom_icon_packs/models/icon_pack_summary.dart';
import 'package:path/path.dart' as p;

typedef IconPackImportProgress =
    void Function(int current, int total, String currentFile);

class IconPackCatalogService {
  const IconPackCatalogService({this.rootPath});

  static const String _logTag = 'IconPackCatalogService';
  static const String manifestFileName = 'manifest.json';
  static const String indexFileName = 'index.jsonl';
  static const String iconsFolderName = 'icons';
  static const String _stagingFolderName = '.staging';

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
    final rootDirectory = Directory(await _resolveRootPath());
    if (!await rootDirectory.exists()) {
      return const [];
    }

    final packs = <IconPackSummary>[];
    await for (final entity in rootDirectory.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! Directory) {
        continue;
      }

      final directoryName = p.basename(entity.path);
      if (directoryName.startsWith('.')) {
        continue;
      }

      final manifestFile = File(p.join(entity.path, manifestFileName));
      if (!await manifestFile.exists()) {
        continue;
      }

      try {
        final manifest = IconPackManifest.fromJsonString(
          await manifestFile.readAsString(),
        );
        packs.add(manifest.toSummary());
      } catch (error, stackTrace) {
        logError(
          'Failed to read icon pack manifest from ${manifestFile.path}: $error',
          tag: _logTag,
          stackTrace: stackTrace,
        );
      }
    }

    packs.sort((left, right) => right.importedAt.compareTo(left.importedAt));
    return packs;
  }

  Future<IconPackSummary> importPack({
    required String archivePath,
    required String displayName,
    IconPackImportProgress? onProgress,
  }) async {
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw IconPackCatalogException(
        IconPackCatalogErrorCode.invalidArchive,
        'Архив не найден: $archivePath',
      );
    }

    if (p.extension(archivePath).toLowerCase() != '.zip') {
      throw const IconPackCatalogException(
        IconPackCatalogErrorCode.invalidArchive,
        'Поддерживаются только ZIP-архивы.',
      );
    }

    final inputStream = InputFileStream(archivePath);
    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      final visiblePaths = archive
          .where((entry) => entry.isFile)
          .map((entry) => _normalizeArchivePath(entry.name))
          .whereType<String>()
          .where((path) => !_shouldIgnoreArchivePath(path))
          .toList();

      final sharedRoot = _detectSharedRoot(visiblePaths);
      final candidates = <_SvgImportCandidate>[];
      for (final entry in archive) {
        if (!entry.isFile) {
          continue;
        }

        final normalizedArchivePath = _normalizeArchivePath(entry.name);
        if (normalizedArchivePath == null ||
            _shouldIgnoreArchivePath(normalizedArchivePath)) {
          continue;
        }

        final relativePath = _stripSharedRoot(
          normalizedArchivePath,
          sharedRoot,
        );
        if (!_isSvgPath(relativePath)) {
          continue;
        }

        candidates.add(
          _SvgImportCandidate(
            relativePath: relativePath,
            writeTo: (outputPath) => _writeArchiveFile(entry, outputPath),
          ),
        );
      }

      return await _importCandidates(
        displayName: displayName,
        sourceLabel: p.basename(archivePath),
        sourceDebugPath: archivePath,
        candidates: candidates,
        onProgress: onProgress,
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
        'Не удалось импортировать пак иконок: $error',
      );
    } finally {
      await inputStream.close();
    }
  }

  Future<IconPackSummary> importDirectory({
    required String directoryPath,
    required String displayName,
    IconPackImportProgress? onProgress,
  }) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw IconPackCatalogException(
        IconPackCatalogErrorCode.invalidDirectory,
        'Папка не найдена: $directoryPath',
      );
    }

    final rawPaths = <String>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final relativePath = p.relative(entity.path, from: directoryPath);
      final normalizedPath = _normalizeArchivePath(relativePath);
      if (normalizedPath == null || _shouldIgnoreArchivePath(normalizedPath)) {
        continue;
      }

      rawPaths.add(normalizedPath);
    }

    final sharedRoot = _detectSharedRoot(rawPaths);
    final candidates = <_SvgImportCandidate>[];
    for (final normalizedPath in rawPaths) {
      final relativePath = _stripSharedRoot(normalizedPath, sharedRoot);
      if (!_isSvgPath(relativePath)) {
        continue;
      }

      final sourceFile = File(
        p.joinAll([directoryPath, ...normalizedPath.split('/')]),
      );
      candidates.add(
        _SvgImportCandidate(
          relativePath: relativePath,
          writeTo: (outputPath) async {
            await sourceFile.copy(outputPath);
          },
        ),
      );
    }

    try {
      return await _importCandidates(
        displayName: displayName,
        sourceLabel: p.basename(directoryPath),
        sourceDebugPath: directoryPath,
        candidates: candidates,
        onProgress: onProgress,
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
        'Не удалось импортировать пак иконок из папки: $error',
      );
    }
  }

  Future<IconPackSummary> _importCandidates({
    required String displayName,
    required String sourceLabel,
    required String sourceDebugPath,
    required List<_SvgImportCandidate> candidates,
    IconPackImportProgress? onProgress,
  }) async {
    final sanitizedDisplayName = displayName.trim();
    if (sanitizedDisplayName.isEmpty) {
      throw const IconPackCatalogException(
        IconPackCatalogErrorCode.invalidPackName,
        'Название пака не может быть пустым.',
      );
    }

    final packKey = normalizePackKey(sanitizedDisplayName);
    if (packKey.isEmpty) {
      throw const IconPackCatalogException(
        IconPackCatalogErrorCode.invalidPackName,
        'Название пака содержит только недопустимые символы.',
      );
    }

    final rootDirectory = Directory(await _resolveRootPath());
    await rootDirectory.create(recursive: true);

    final targetDirectory = Directory(p.join(rootDirectory.path, packKey));
    if (await targetDirectory.exists()) {
      throw IconPackCatalogException(
        IconPackCatalogErrorCode.duplicatePack,
        'Пак с ключом "$packKey" уже существует. Выберите другое имя.',
      );
    }

    final stagingDirectory = Directory(
      p.join(
        rootDirectory.path,
        _stagingFolderName,
        '${packKey}_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final stagingPackDirectory = Directory(
      p.join(stagingDirectory.path, packKey),
    );

    try {
      await stagingPackDirectory.create(recursive: true);
      if (candidates.isEmpty) {
        throw const IconPackCatalogException(
          IconPackCatalogErrorCode.noSvgFiles,
          'В источнике не найдено ни одной SVG-иконки.',
        );
      }

      final importedAt = DateTime.now().toUtc();
      final usedKeys = <String, int>{};
      final entries = <IconPackEntry>[];

      for (var index = 0; index < candidates.length; index++) {
        final candidate = candidates[index];
        final baseIconKey = normalizeIconPathWithoutExtension(
          p.posix.withoutExtension(candidate.relativePath),
        );
        final iconKey = _ensureUniqueIconKey(baseIconKey, usedKeys);
        final canonicalKey = '$packKey/$iconKey';
        final svgRelativePath = p.posix.join(iconsFolderName, '$iconKey.svg');
        final outputFile = File(
          p.joinAll([stagingPackDirectory.path, ...svgRelativePath.split('/')]),
        );
        await outputFile.parent.create(recursive: true);
        await candidate.writeTo(outputFile.path);

        entries.add(
          IconPackEntry(
            key: canonicalKey,
            packKey: packKey,
            packName: sanitizedDisplayName,
            iconKey: iconKey,
            name: p.posix.basenameWithoutExtension(candidate.relativePath),
            relativePath: candidate.relativePath,
            svgPath: svgRelativePath,
            importedAt: importedAt,
          ),
        );

        onProgress?.call(index + 1, candidates.length, candidate.relativePath);
      }

      final manifest = IconPackManifest(
        packKey: packKey,
        displayName: sanitizedDisplayName,
        sourceArchiveName: sourceLabel,
        importedAt: importedAt,
        iconCount: entries.length,
      );

      final manifestFile = File(
        p.join(stagingPackDirectory.path, manifestFileName),
      );
      await manifestFile.writeAsString(manifest.toJsonString());

      final indexFile = File(p.join(stagingPackDirectory.path, indexFileName));
      await indexFile.writeAsString(
        entries.map((entry) => entry.toJsonLine()).join('\n'),
      );

      await stagingPackDirectory.rename(targetDirectory.path);
      await _deleteDirectoryIfExists(stagingDirectory.path);

      logInfo(
        'Imported icon pack $packKey from $sourceDebugPath',
        tag: _logTag,
      );
      return (await _readManifest(targetDirectory.path)).toSummary();
    } on IconPackCatalogException {
      rethrow;
    } catch (error, stackTrace) {
      logError(
        'Failed to import icon pack from $sourceDebugPath: $error',
        tag: _logTag,
        stackTrace: stackTrace,
      );
      throw IconPackCatalogException(
        IconPackCatalogErrorCode.importFailed,
        'Не удалось импортировать пак иконок: $error',
      );
    } finally {
      await _deleteDirectoryIfExists(stagingDirectory.path);
    }
  }

  Future<List<IconPackEntry>> listIcons({
    String? packKey,
    String query = '',
    int offset = 0,
    int limit = 50,
  }) async {
    final keys = packKey == null
        ? (await listPacks()).map((pack) => pack.packKey).toList()
        : [packKey];

    final normalizedQuery = query.trim().toLowerCase();
    final entries = <IconPackEntry>[];
    final rootDirectory = await _resolveRootPath();

    for (final key in keys) {
      final indexFile = File(p.join(rootDirectory, key, indexFileName));
      if (!await indexFile.exists()) {
        continue;
      }

      final lines = LineSplitter.split(await indexFile.readAsString());
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          continue;
        }

        final entry = IconPackEntry.fromJsonLine(trimmed);
        if (normalizedQuery.isNotEmpty &&
            !_matchesQuery(entry, normalizedQuery)) {
          continue;
        }
        entries.add(entry);
      }
    }

    entries.sort((left, right) => left.key.compareTo(right.key));
    if (entries.isEmpty || offset >= entries.length) {
      return const [];
    }

    final safeOffset = max(offset, 0);
    final safeLimit = limit <= 0 ? entries.length : limit;
    final end = min(entries.length, safeOffset + safeLimit);
    return entries.sublist(safeOffset, end);
  }

  Future<String?> readSvgByKey(String iconKey) async {
    final keyParts = iconKey.split('/');
    if (keyParts.length < 2) {
      return null;
    }

    final packKey = keyParts.first;
    final entry = await _findEntryByKey(packKey: packKey, key: iconKey);
    if (entry == null) {
      return null;
    }

    final svgFile = File(
      p.joinAll([
        await _resolveRootPath(),
        packKey,
        ...entry.svgPath.split('/'),
      ]),
    );
    if (!await svgFile.exists()) {
      return null;
    }

    return svgFile.readAsString();
  }

  Future<String> _resolveRootPath() async {
    return rootPath ?? await AppPaths.iconPacksPath;
  }

  Future<IconPackManifest> _readManifest(String packDirectoryPath) async {
    final manifestFile = File(p.join(packDirectoryPath, manifestFileName));
    return IconPackManifest.fromJsonString(await manifestFile.readAsString());
  }

  Future<IconPackEntry?> _findEntryByKey({
    required String packKey,
    required String key,
  }) async {
    final indexFile = File(
      p.join(await _resolveRootPath(), packKey, indexFileName),
    );
    if (!await indexFile.exists()) {
      return null;
    }

    final lines = LineSplitter.split(await indexFile.readAsString());
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final entry = IconPackEntry.fromJsonLine(trimmed);
      if (entry.key == key) {
        return entry;
      }
    }

    return null;
  }

  static bool _matchesQuery(IconPackEntry entry, String query) {
    return entry.name.toLowerCase().contains(query) ||
        entry.key.toLowerCase().contains(query) ||
        entry.relativePath.toLowerCase().contains(query);
  }

  static Future<void> _writeArchiveFile(
    ArchiveFile file,
    String outputPath,
  ) async {
    final outputStream = OutputFileStream(outputPath);
    try {
      file.writeContent(outputStream, freeMemory: true);
    } finally {
      await outputStream.close();
    }
  }

  static Future<void> _deleteDirectoryIfExists(String path) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  static String _ensureUniqueIconKey(
    String baseKey,
    Map<String, int> usedKeys,
  ) {
    final currentIndex = usedKeys.update(
      baseKey,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    return currentIndex == 1 ? baseKey : '${baseKey}_$currentIndex';
  }

  static bool _isSvgPath(String path) {
    return p.posix.extension(path).toLowerCase() == '.svg';
  }

  static bool _shouldIgnoreArchivePath(String path) {
    final segments = path.split('/');
    return segments.any((segment) {
      final trimmed = segment.trim();
      return trimmed.isEmpty ||
          trimmed == '__MACOSX' ||
          trimmed == '.DS_Store' ||
          trimmed.startsWith('.');
    });
  }

  static String? _normalizeArchivePath(String path) {
    final raw = path.replaceAll('\\', '/').trim();
    if (raw.isEmpty || raw.startsWith('/')) {
      return null;
    }

    final normalized = p.posix.normalize(raw);
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        normalized.contains('/../')) {
      return null;
    }

    return normalized.replaceFirst(RegExp(r'^\./'), '');
  }

  static String? _detectSharedRoot(List<String> paths) {
    if (paths.isEmpty) {
      return null;
    }

    final splitPaths = paths.map((path) => path.split('/')).toList();
    final root = splitPaths.first.first;
    final hasSharedRoot = splitPaths.every(
      (segments) => segments.length > 1 && segments.first == root,
    );
    return hasSharedRoot ? root : null;
  }

  static String _stripSharedRoot(String path, String? sharedRoot) {
    if (sharedRoot == null) {
      return path;
    }

    final prefix = '$sharedRoot/';
    if (path.startsWith(prefix)) {
      return path.substring(prefix.length);
    }

    return path;
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
  duplicatePack,
  importFailed,
  invalidArchive,
  invalidDirectory,
  invalidPackName,
  noSvgFiles,
}

class _SvgImportCandidate {
  const _SvgImportCandidate({
    required this.relativePath,
    required this.writeTo,
  });

  final String relativePath;
  final Future<void> Function(String outputPath) writeTo;
}
