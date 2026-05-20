import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/vault_db/services/archive_service/archive_service.dart';

/// Провайдер для сервиса архивации хранилищ
final archiveServiceProvider = Provider<ArchiveService>((ref) {
  return ArchiveService();
});
