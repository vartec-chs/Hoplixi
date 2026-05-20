import 'dart:isolate';

class UnarchiveParams {
  final String archivePath;
  final String? password;
  final String targetPath;
  final SendPort sendPort;

  UnarchiveParams({
    required this.archivePath,
    this.password,
    required this.targetPath,
    required this.sendPort,
  });
}
