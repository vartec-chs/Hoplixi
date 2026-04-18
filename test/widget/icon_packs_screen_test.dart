import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/icon_packs/models/icon_packs_state.dart';
import 'package:hoplixi/features/icon_packs/providers/icon_packs_provider.dart';
import 'package:hoplixi/features/icon_packs/screens/icon_packs_screen.dart';
import 'package:hoplixi/features/icon_packs/services/icon_pack_catalog_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late IconPackCatalogService service;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('icon_packs_screen_test_');
    service = IconPackCatalogService(rootPath: tempDir.path);
    container = ProviderContainer(
      overrides: [
        iconPackCatalogServiceProvider.overrideWithValue(service),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('imports selected pack and refreshes list', (tester) async {
    final archiveFile = await _createZipFile(
      directory: tempDir,
      name: 'demo-pack.zip',
      entries: {'demo/github.svg': '<svg>github</svg>'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IconPacksScreen()),
      ),
    );
    await tester.pump();

    container.read(iconPacksNotifierProvider.notifier).setImportDraft(
      sourcePath: archiveFile.path,
      sourceType: IconPackImportSourceType.archive,
      displayName: 'Demo Pack',
    );
    await tester.pump();

    expect(find.text('Demo Pack'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Импортировать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(container.read(iconPacksNotifierProvider).errorMessage, isNull);
    expect(find.text('Источник: demo-pack.zip'), findsOneWidget);
    expect(find.text('1 SVG'), findsOneWidget);
  });

  testWidgets('shows duplicate error after import attempt', (tester) async {
    final archiveFile = await _createZipFile(
      directory: tempDir,
      name: 'duplicate-pack.zip',
      entries: {'demo/github.svg': '<svg>github</svg>'},
    );

    await service.importPack(
      archivePath: archiveFile.path,
      displayName: 'Duplicate Pack',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IconPacksScreen()),
      ),
    );
    await tester.pump();

    container.read(iconPacksNotifierProvider.notifier).setImportDraft(
      sourcePath: archiveFile.path,
      sourceType: IconPackImportSourceType.archive,
      displayName: 'Duplicate Pack',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Импортировать'));
    await tester.pump();

    expect(
      container.read(iconPacksNotifierProvider).errorMessage,
      contains('уже существует'),
    );
  });

  testWidgets('imports selected folder and refreshes list', (tester) async {
    final sourceDirectory = Directory(p.join(tempDir.path, 'folder-import'));
    await Directory(p.join(sourceDirectory.path, 'folder-import', 'icons'))
        .create(recursive: true);
    await File(
      p.join(sourceDirectory.path, 'folder-import', 'icons', 'github.svg'),
    ).writeAsString('<svg>github-folder</svg>');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IconPacksScreen()),
      ),
    );
    await tester.pump();

    container.read(iconPacksNotifierProvider.notifier).setImportDraft(
      sourcePath: sourceDirectory.path,
      sourceType: IconPackImportSourceType.directory,
      displayName: 'Folder Import',
    );
    await tester.pump();

    expect(find.text('Источник: папка'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Импортировать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(container.read(iconPacksNotifierProvider).errorMessage, isNull);
    expect(find.text('Источник: folder-import'), findsOneWidget);
    expect(find.text('1 SVG'), findsOneWidget);
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
