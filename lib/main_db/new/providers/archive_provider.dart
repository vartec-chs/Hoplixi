import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/main_db/old/services/other/archive_service.dart';

/// Провайдер для сервиса архивации хранилищ
final archiveServiceProvider = Provider<ArchiveService>((ref) {
  return ArchiveService();
});
