import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/db_core/services/archive_service.dart';
import 'package:hoplixi/db_core/models/db_errors.dart';
import 'package:path/path.dart' as p;

void main() {
  late ArchiveService archiveService;
  late Directory tempDir;
  late Directory storeDir;
  late File dbFile;
  late Directory attachmentsDir;
  late File attachmentFile;

  setUp(() async {
    archiveService = ArchiveService();

    // Создаем временную директорию для тестов
    tempDir = await Directory.systemTemp.createTemp('archive_test_');
    storeDir = Directory(p.join(tempDir.path, 'test_store'));
    await storeDir.create();

    // Создаем имитацию файлов хранилища
    dbFile = File(p.join(storeDir.path, 'database.db'));
    await dbFile.writeAsString('fake database content');

    attachmentsDir = Directory(p.join(storeDir.path, 'attachments'));
    await attachmentsDir.create();

    attachmentFile = File(p.join(attachmentsDir.path, 'file1.txt'));
    await attachmentFile.writeAsString('attachment content');
  });

  tearDown(() async {
    // Очищаем временные файлы
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ArchiveService', () {
    group('archiveStore', () {
      test('should archive store without password successfully', () async {
        final archivePath = p.join(tempDir.path, 'store.zip');

        final result = await archiveService.archiveStore(
          storeDir.path,
          archivePath,
        );

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), archivePath);

        // Проверяем, что архив создан
        final archiveFile = File(archivePath);
        expect(await archiveFile.exists(), true);
        expect(await archiveFile.length(), greaterThan(0));
      });

      test('should archive store with password successfully', () async {
        final archivePath = p.join(tempDir.path, 'store_protected.zip');

        final result = await archiveService.archiveStore(
          storeDir.path,
          archivePath,
          password: 'test_password',
        );

        expect(result.isSuccess(), true);
        expect(result.getOrNull(), archivePath);

        // Проверяем, что архив создан
        final archiveFile = File(archivePath);
        expect(await archiveFile.exists(), true);
        expect(await archiveFile.length(), greaterThan(0));
      });

      test('should fail when store directory does not exist', () async {
        final nonExistentPath = p.join(tempDir.path, 'non_existent_store');
        final archivePath = p.join(tempDir.path, 'failed.zip');

        final result = await archiveService.archiveStore(
          nonExistentPath,
          archivePath,
        );

        expect(result.isError(), true);
        final error = result.exceptionOrNull();
        expect(error, isA<DatabaseError>());
        expect(error!.code, 'DB_ARCHIVE_FAILED');
      });
    });

    group('unarchiveStore', () {
      late String archivePath;
      late String protectedArchivePath;

      setUp(() async {
        // Создаем архивы для тестов разархивации
        archivePath = p.join(tempDir.path, 'store.zip');
        await archiveService.archiveStore(storeDir.path, archivePath);

        protectedArchivePath = p.join(tempDir.path, 'store_protected.zip');
        await archiveService.archiveStore(
          storeDir.path,
          protectedArchivePath,
          password: 'test_password',
        );
      });

      test('should unarchive store without password successfully', () async {
        final result = await archiveService.unarchiveStore(
          archivePath,
          basePath: tempDir.path,
        );

        expect(result.isSuccess(), true);
        final extractedPath = result.getOrNull()!;
        expect(extractedPath, isNotNull);

        // Проверяем, что файлы восстановлены
        final extractedStoreDir = Directory(extractedPath);
        expect(await extractedStoreDir.exists(), true);

        final extractedDbFile = File(p.join(extractedPath, 'database.db'));
        expect(await extractedDbFile.exists(), true);
        expect(await extractedDbFile.readAsString(), 'fake database content');

        final extractedAttachmentsDir = Directory(
          p.join(extractedPath, 'attachments'),
        );
        expect(await extractedAttachmentsDir.exists(), true);

        final extractedAttachmentFile = File(
          p.join(extractedAttachmentsDir.path, 'file1.txt'),
        );
        expect(await extractedAttachmentFile.exists(), true);
        expect(
          await extractedAttachmentFile.readAsString(),
          'attachment content',
        );
      });

      test('should unarchive store with password successfully', () async {
        final result = await archiveService.unarchiveStore(
          protectedArchivePath,
          password: 'test_password',
          basePath: tempDir.path,
        );

        expect(result.isSuccess(), true);
        final extractedPath = result.getOrNull()!;
        expect(extractedPath, isNotNull);

        // Проверяем, что файлы восстановлены
        final extractedStoreDir = Directory(extractedPath);
        expect(await extractedStoreDir.exists(), true);

        final extractedDbFile = File(p.join(extractedPath, 'database.db'));
        expect(await extractedDbFile.exists(), true);
        expect(await extractedDbFile.readAsString(), 'fake database content');
      });

      test('should fail when archive file does not exist', () async {
        final nonExistentArchive = p.join(tempDir.path, 'non_existent.zip');

        final result = await archiveService.unarchiveStore(
          nonExistentArchive,
          basePath: tempDir.path,
        );

        expect(result.isError(), true);
        final error = result.exceptionOrNull();
        expect(error, isA<DatabaseError>());
        expect(error!.code, 'DB_UNARCHIVE_FAILED');
      });

      test('should fail when wrong password provided', () async {
        final result = await archiveService.unarchiveStore(
          protectedArchivePath,
          password: 'wrong_password',
          basePath: tempDir.path,
        );

        expect(result.isError(), true);
        final error = result.exceptionOrNull();
        expect(error, isA<DatabaseError>());
        expect(error!.code, 'DB_UNARCHIVE_FAILED');
      });
    });
  });
}
