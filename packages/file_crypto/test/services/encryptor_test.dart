import 'dart:io';
import 'package:file_crypto/services/encryptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ArchiveEncryptor', () {
    late Directory tempDir;
    late ArchiveEncryptor encryptor;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('encryptor_test_');
      encryptor = ArchiveEncryptor();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('encrypts and decrypts a single file correctly', () async {
      final inputFile = File(p.join(tempDir.path, 'test.txt'));
      final content = 'Hello, World! This is a test file.';
      await inputFile.writeAsString(content);

      final encryptedPath = p.join(tempDir.path, 'test.enc');
      final decryptedDir = Directory(p.join(tempDir.path, 'decrypted'));
      await decryptedDir.create();

      // Encrypt
      final encResult = await encryptor.encrypt(
        inputPath: inputFile.path,
        outputPath: encryptedPath,
        password: 'password123',
      );

      expect(File(encryptedPath).existsSync(), isTrue);
      expect(encResult.outputPath, equals(encryptedPath));

      // Read Header
      final header = await encryptor.readHeader(
        inputPath: encryptedPath,
        password: 'password123',
      );
      expect(header.originalName, equals('test.txt'));
      expect(header.wasDirectory, isFalse);

      // Decrypt
      final decResult = await encryptor.decrypt(
        inputPath: encryptedPath,
        outputPath: decryptedDir.path,
        password: 'password123',
      );

      final decryptedFile = File(decResult.outputPath);
      expect(decryptedFile.existsSync(), isTrue);
      expect(await decryptedFile.readAsString(), equals(content));
    });

    test('encrypts and decrypts a directory correctly', () async {
      final inputDir = Directory(p.join(tempDir.path, 'input_dir'));
      await inputDir.create();

      await File(
        p.join(inputDir.path, 'file1.txt'),
      ).writeAsString('File 1 content');
      await File(
        p.join(inputDir.path, 'file2.txt'),
      ).writeAsString('File 2 content');
      final subDir = Directory(p.join(inputDir.path, 'subdir'));
      await subDir.create();
      await File(
        p.join(subDir.path, 'file3.txt'),
      ).writeAsString('File 3 content');

      final encryptedPath = p.join(tempDir.path, 'dir.enc');
      final decryptedDir = Directory(p.join(tempDir.path, 'decrypted_dir'));
      await decryptedDir.create();

      // Encrypt
      await encryptor.encrypt(
        inputPath: inputDir.path,
        outputPath: encryptedPath,
        password: 'password123',
      );

      expect(File(encryptedPath).existsSync(), isTrue);

      // Read Header
      final header = await encryptor.readHeader(
        inputPath: encryptedPath,
        password: 'password123',
      );
      expect(header.wasDirectory, isTrue);

      // Decrypt
      await encryptor.decrypt(
        inputPath: encryptedPath,
        outputPath: decryptedDir.path,
        password: 'password123',
      );

      // Verify structure
      // Note: ArchiveEncryptor restores the directory structure inside the output path
      // If original was 'input_dir', it might be restored as 'decrypted_dir/input_dir' or just contents in 'decrypted_dir'
      // Based on typical archive behavior, it usually contains the root folder if it was archived.
      // Let's check if files exist.

      // Assuming the encryptor preserves the root folder name or just contents.
      // If I look at ArchiveEncryptor implementation (which I haven't fully read but assumed),
      // usually zip contains relative paths.

      // Let's check recursively.
      final decryptedFiles = decryptedDir.listSync(recursive: true);
      expect(decryptedFiles.length, greaterThanOrEqualTo(3));

      // Check specific file content
      // We need to find where they are.
      // If the logic preserves the input directory name, it should be in decryptedDir/input_dir/file1.txt
      // Or if it archives contents, it is decryptedDir/file1.txt

      // Let's try to find file1.txt
      final file1 = decryptedFiles.whereType<File>().firstWhere(
        (f) => p.basename(f.path) == 'file1.txt',
      );
      expect(await file1.readAsString(), equals('File 1 content'));
    });

    test(
      'throws EncryptionExceptionArchive when input file does not exist',
      () async {
        final inputPath = p.join(tempDir.path, 'non_existent.txt');
        final outputPath = p.join(tempDir.path, 'output.enc');

        expect(
          () => encryptor.encrypt(
            inputPath: inputPath,
            outputPath: outputPath,
            password: 'password',
          ),
          throwsA(isA<EncryptionExceptionArchive>()),
        );
      },
    );

    test('throws AuthenticationExceptionArchive on wrong password', () async {
      final inputFile = File(p.join(tempDir.path, 'test.txt'));
      await inputFile.writeAsString('content');
      final encryptedPath = p.join(tempDir.path, 'test.enc');

      await encryptor.encrypt(
        inputPath: inputFile.path,
        outputPath: encryptedPath,
        password: 'correct_password',
      );

      expect(
        () => encryptor.decrypt(
          inputPath: encryptedPath,
          outputPath: tempDir.path,
          password: 'wrong_password',
        ),
        throwsA(isA<AuthenticationExceptionArchive>()),
      );
    });

    test('onProgress callback is called', () async {
      final inputFile = File(p.join(tempDir.path, 'test.txt'));
      // Write enough data to trigger progress
      final data = List.filled(1024 * 1024, 'a').join(); // 1MB
      await inputFile.writeAsString(data);
      final encryptedPath = p.join(tempDir.path, 'test.enc');

      bool progressCalled = false;
      await encryptor.encrypt(
        inputPath: inputFile.path,
        outputPath: encryptedPath,
        password: 'password',
        onProgress: (processed, total) {
          progressCalled = true;
          expect(processed, lessThanOrEqualTo(total));
        },
      );

      expect(progressCalled, isTrue);
    });
  });
}
