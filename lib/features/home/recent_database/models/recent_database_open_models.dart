import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

class RecentDatabaseOpenRequest {
  const RecentDatabaseOpenRequest({
    required this.dto,
    required this.password,
    required this.shouldSavePassword,
    required this.usedManualPassword,
  });

  final OpenStoreDto dto;
  final String password;
  final bool shouldSavePassword;
  final bool usedManualPassword;
}

class RecentDatabasePasswordPromptResult {
  const RecentDatabasePasswordPromptResult({
    required this.password,
    required this.shouldSavePassword,
    required this.usedManualPassword,
  });

  final String password;
  final bool shouldSavePassword;
  final bool usedManualPassword;
}
