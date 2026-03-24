import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';

class AuthTokensImportResult {
  const AuthTokensImportResult({
    required this.created,
    required this.updated,
    required this.tokens,
  });

  final int created;
  final int updated;
  final List<AuthTokenEntry> tokens;

  int get total => created + updated;
}
