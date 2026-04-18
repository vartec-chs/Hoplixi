import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/custom_icon_packs/services/icon_pack_catalog_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late IconPackCatalogService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('icon_pack_catalog_test_');
    service = IconPackCatalogService(rootPath: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('normalize pack and icon keys', () {
    expect(
      IconPackCatalogService.normalizePackKey('  My Fancy Pack  '),
      'my_fancy_pack',
    );
    expect(
      IconPackCatalogService.normalizePackKey('Пак<>:"/\\\\|?*'),
      'пак',
    );
    expect(
      IconPackCatalogService.normalizeIconPathWithoutExtension(
        'Social Icons/GitHub Logo',
      ),
      'social_icons/github_logo',
    );
  });

  test('imports archive, strips shared root and ignores non-svg files', () async {
    final archiveFile = await _createZipFile(
      directory: tempDir,
      name: 'brand-pack.zip',
      entries: {
        'brand-pack/social/github.svg': '<svg>github</svg>',
        'brand-pack/social/twitter.svg': '<svg>twitter</svg>',
        'brand-pack/readme.txt': 'ignore me',
        '__MACOSX/ghost.svg': '<svg>ghost</svg>',
        'brand-pack/.DS_Store': 'ignored',
      },
    );

    final result = await service.importPack(
      archivePath: archiveFile.path,
      displayName: 'Brand Pack',
    );

    expect(result.packKey, 'brand_pack');
    expect(result.iconCount, 2);

    final icons = await service.listIcons(packKey: result.packKey, limit: 20);
    expect(icons, hasLength(2));
    expect(icons.map((entry) => entry.relativePath), containsAll(<String>[
      'social/github.svg',
      'social/twitter.svg',
    ]));
    expect(icons.map((entry) => entry.key), contains('brand_pack/social/github'));
    expect(
      await service.readSvgByKey('brand_pack/social/github'),
      contains('github'),
    );

    final importedDir = Directory(p.join(tempDir.path, result.packKey));
    expect(await importedDir.exists(), isTrue);
    expect(File(p.join(importedDir.path, 'manifest.json')).existsSync(), isTrue);
    expect(File(p.join(importedDir.path, 'index.jsonl')).existsSync(), isTrue);
    expect(
      File(p.join(importedDir.path, 'icons', 'social', 'github.svg')).existsSync(),
      isTrue,
    );
  });

  test('rejects duplicate pack key', () async {
    final archiveFile = await _createZipFile(
      directory: tempDir,
      name: 'duplicate.zip',
      entries: {'icons/github.svg': '<svg>github</svg>'},
    );

    await service.importPack(
      archivePath: archiveFile.path,
      displayName: 'Duplicate Pack',
    );

    expect(
      () => service.importPack(
        archivePath: archiveFile.path,
        displayName: 'Duplicate Pack',
      ),
      throwsA(
        isA<IconPackCatalogException>().having(
          (error) => error.code,
          'code',
          IconPackCatalogErrorCode.duplicatePack,
        ),
      ),
    );
  });

  test('rejects archive without svg files', () async {
    final archiveFile = await _createZipFile(
      directory: tempDir,
      name: 'no-svg.zip',
      entries: {'pack/readme.txt': 'hello'},
    );

    expect(
      () => service.importPack(
        archivePath: archiveFile.path,
        displayName: 'No Svg',
      ),
      throwsA(
        isA<IconPackCatalogException>().having(
          (error) => error.code,
          'code',
          IconPackCatalogErrorCode.noSvgFiles,
        ),
      ),
    );
  });

  test('imports directory and strips shared root folder', () async {
    final sourceDirectory = Directory(p.join(tempDir.path, 'folder-pack'));
    await Directory(p.join(sourceDirectory.path, 'folder-pack', 'social'))
        .create(recursive: true);
    await File(
      p.join(sourceDirectory.path, 'folder-pack', 'social', 'github.svg'),
    ).writeAsString('<svg>github-folder</svg>');
    await File(
      p.join(sourceDirectory.path, 'folder-pack', 'social', 'x.svg'),
    ).writeAsString('<svg>x-folder</svg>');
    await File(
      p.join(sourceDirectory.path, 'folder-pack', 'README.md'),
    ).writeAsString('ignore');

    final result = await service.importDirectory(
      directoryPath: sourceDirectory.path,
      displayName: 'Folder Pack',
    );

    expect(result.packKey, 'folder_pack');
    expect(result.iconCount, 2);
    expect(result.sourceArchiveName, 'folder-pack');

    final icons = await service.listIcons(packKey: result.packKey, limit: 20);
    expect(icons.map((entry) => entry.relativePath), contains('social/github.svg'));
    expect(
      await service.readSvgByKey('folder_pack/social/github'),
      contains('github-folder'),
    );
  });

  test('supports pagination, query filtering and deterministic collision suffixes', () async {
    final archiveFile = await _createZipFile(
      directory: tempDir,
      name: 'collision-pack.zip',
      entries: {
        'Foo.svg': '<svg>one</svg>',
        'foo.svg': '<svg>two</svg>',
        'bar/Baz Logo.svg': '<svg>three</svg>',
      },
    );

    final result = await service.importPack(
      archivePath: archiveFile.path,
      displayName: 'Collision Pack',
    );

    final allIcons = await service.listIcons(packKey: result.packKey, limit: 20);
    expect(allIcons.map((entry) => entry.key), contains('collision_pack/foo'));
    expect(allIcons.map((entry) => entry.key), contains('collision_pack/foo_2'));

    final filtered = await service.listIcons(
      packKey: result.packKey,
      query: 'foo',
      limit: 20,
    );
    expect(filtered, hasLength(2));

    final paged = await service.listIcons(
      packKey: result.packKey,
      offset: 1,
      limit: 1,
    );
    expect(paged, hasLength(1));
  });
}

Future<File> _createZipFile({
  required Directory directory,
  required String name,
  required Map<String, String> entries,
}) async {
  final archive = Archive();
  entries.forEach((path, content) {
    archive.add(ArchiveFile.string(path, content));
  });

  final file = File(p.join(directory.path, name));
  await file.writeAsBytes(ZipEncoder().encodeBytes(archive));
  return file;
}
