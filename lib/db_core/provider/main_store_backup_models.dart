class BackupResult {
  const BackupResult({
    required this.backupPath,
    required this.scope,
    required this.createdAt,
    required this.periodic,
  });

  final String backupPath;
  final BackupScope scope;
  final DateTime createdAt;
  final bool periodic;
}

enum BackupScope { databaseOnly, encryptedFilesOnly, full }
