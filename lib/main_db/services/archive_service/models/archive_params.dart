import 'dart:isolate';

class ArchiveParams {
  final String storePath;
  final String outputPath;
  final String? password;
  final SendPort sendPort;

  ArchiveParams({
    required this.storePath,
    required this.outputPath,
    this.password,
    required this.sendPort,
  });
}
