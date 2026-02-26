# Использование Hoplixi File Crypt API из Dart

## Подключение

```dart
import 'package:hoplixi/rust/api/crypt_api.dart';
```

Убедитесь, что `RustLib.init()` вызван в `main.dart` **до** первого
использования.

## 1. Шифрование одного файла или папки

```dart
import 'package:hoplixi/rust/api/crypt_api.dart';

Future<void> encryptMyFile() async {
  // Вариант 1: минимальный конструктор через factory-метод
  final opts = await FrbEncryptOptions.simple(
    inputPath: '/path/to/secret_folder',
    outputDir: '/path/to/output',
    password: 'my-secure-password',
  );

  // Вариант 2: полный конструктор (всё под контролем)
  const optsFulle = FrbEncryptOptions(
    inputPath: '/path/to/file.pdf',
    outputDir: '/path/to/output',
    password: 'my-secure-password',
    gzipCompressed: true,
    uuid: null,                       // авто-генерация
    outputExtension: '.vault',        // по умолчанию '.enc'
    tempDir: null,
    metadata: [
      FrbKeyValue(key: 'author', value: 'alice'),
    ],
    chunkSize: FrbChunkSizePreset.desktop(), // 1 MB
    // chunkSize: FrbChunkSizePreset.mobile()  // 256 KB
    // chunkSize: FrbChunkSizePreset.custom(512 * 1024)
  );

  await for (final event in encryptFile(opts: opts)) {
    switch (event) {
      case FrbEncryptEvent_Progress(:final field0):
        print('[${field0.stage.name}] ${field0.percentage.toStringAsFixed(1)}%');
      case FrbEncryptEvent_Done(:final field0):
        print('Готово: ${field0.outputPath}');
        print('UUID:   ${field0.uuid}');
        print('Исходный размер: ${field0.originalSize} байт');
    }
  }
}
```

## 2. Расшифровка одного файла

```dart
Future<void> decryptMyFile() async {
  final opts = await FrbDecryptOptions.simple(
    inputPath: '/path/to/encrypted.enc',
    outputDir: '/path/to/output',
    password: 'my-secure-password',
  );

  await for (final event in decryptFile(opts: opts)) {
    switch (event) {
      case FrbDecryptEvent_Progress(:final field0):
        print('[${field0.stage.name}] ${field0.percentage.toStringAsFixed(1)}%');
      case FrbDecryptEvent_Done(:final field0):
        final meta = field0.metadata;
        print('Расшифровано в: ${field0.outputPath}');
        print('Имя файла: ${meta.originalFilename}.${meta.originalExtension}');
        print('UUID: ${meta.uuid}');
        print('Gzip-сжатие: ${meta.gzipCompressed}');
        // Кастомные KV-метаданные
        for (final kv in meta.metadata) {
          print('  ${kv.key} = ${kv.value}');
        }
    }
  }
}
```

## 3. Батч-шифрование нескольких файлов

```dart
Future<void> encryptBatchExmaple() async {
  const opts = FrbBatchEncryptOptions(
    inputPaths: [
      '/path/to/file1.pdf',
      '/path/to/file2.docx',
      '/path/to/folder/',
    ],
    outputDir: '/path/to/output',
    password: 'my-secure-password',
    gzipCompressed: false,
    tempDir: null,
    metadata: [],
    chunkSize: FrbChunkSizePreset.desktop(),
  );

  await for (final event in encryptBatch(opts: opts)) {
    switch (event) {
      case FrbBatchEncryptEvent_FileProgress(
        :final fileIndex,
        :final totalFiles,
        :final currentFile,
        :final progress
      ):
        print('[$fileIndex/$totalFiles] $currentFile — ${progress.percentage.toStringAsFixed(1)}%');

      case FrbBatchEncryptEvent_FileDone(:final fileIndex, :final result):
        print('✓ [$fileIndex] ${result.outputPath}');

      case FrbBatchEncryptEvent_FileError(:final fileIndex, :final inputPath, :final error):
        print('✗ [$fileIndex] $inputPath: $error');

      case FrbBatchEncryptEvent_AllDone(:final field0):
        print('Итог: ${field0.succeeded.length} успешно, ${field0.failed.length} ошибок');
        for (final err in field0.failed) {
          print('  Ошибка: ${err.inputPath} — ${err.error}');
        }
    }
  }
}
```

## 4. Батч-расшифровка нескольких файлов

```dart
Future<void> decryptBatchExample() async {
  const opts = FrbBatchDecryptOptions(
    inputPaths: [
      '/path/to/file1.enc',
      '/path/to/file2.enc',
    ],
    outputDir: '/path/to/output',
    password: 'my-secure-password',
    tempDir: null,
    chunkSize: FrbChunkSizePreset.desktop(),
  );

  await for (final event in decryptBatch(opts: opts)) {
    switch (event) {
      case FrbBatchDecryptEvent_FileProgress(:final fileIndex, :final progress):
        print('[$fileIndex] ${progress.percentage.toStringAsFixed(1)}%');
      case FrbBatchDecryptEvent_FileDone(:final fileIndex, :final result):
        print('✓ [$fileIndex] → ${result.outputPath}');
      case FrbBatchDecryptEvent_FileError(:final fileIndex, :final error):
        print('✗ [$fileIndex] $error');
      case FrbBatchDecryptEvent_AllDone(:final field0):
        print('Успешно: ${field0.succeeded.length}, ошибок: ${field0.failed.length}');
    }
  }
}
```

## 5. Чтение заголовка без расшифровки данных

Используется для отображения информации о файле в UI — быстро, не затрагивает
тело файла:

```dart
Future<void> previewEncryptedFile(String filePath, String password) async {
  try {
    final meta = await readEncryptedHeader(
      inputPath: filePath,
      password: password,
    );

    print('Имя файла: ${meta.originalFilename}.${meta.originalExtension}');
    print('UUID:      ${meta.uuid}');
    print('Размер:    ${meta.originalSize} байт');
    print('Gzip:      ${meta.gzipCompressed}');
  } catch (e) {
    // Ошибка = неверный пароль или повреждённый файл
    print('Не удалось прочитать заголовок: $e');
  }
}
```

## Стадии прогресса (`FrbProgressStage`)

| Значение                 | Описание                 |
| ------------------------ | ------------------------ |
| `compressingDirectory`   | Упаковка папки в 7z      |
| `compressingGzip`        | Gzip-сжатие файла        |
| `encrypting`             | Шифрование блоков данных |
| `decrypting`             | Расшифровка блоков       |
| `decompressingGzip`      | Распаковка Gzip          |
| `decompressingDirectory` | Распаковка 7z архива     |
| `done`                   | Операция завершена       |

## Обработка ошибок

Все функции бросают исключение при неверном пароле, повреждённом файле или
ошибке I/O. Заворачивайте вызовы в `try/catch`:

```dart
try {
  await for (final event in encryptFile(opts: opts)) { ... }
} catch (e) {
  // e.toString() содержит описание ошибки из Rust
  showErrorDialog(e.toString());
}
```
