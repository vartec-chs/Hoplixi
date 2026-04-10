import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/db_core/services/archive_service.dart';

/// Провайдер для сервиса архивации хранилищ
final archiveServiceProvider = Provider<ArchiveService>((ref) {
  return ArchiveService();
});
