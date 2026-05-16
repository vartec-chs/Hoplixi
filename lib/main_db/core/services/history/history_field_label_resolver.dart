import '../../tables/vault_items/vault_items.dart';

class HistoryFieldLabelResolver {
  String labelFor({
    required VaultItemType type,
    required String fieldKey,
  }) {
    // Stage 1: Fallback labels. Later can be replaced by localization-friendly codes or stable strings.
    final labels = {
      'name': 'Name',
      'description': 'Description',
      'service': 'Service',
      'key': 'API Key',
      'tokenType': 'Token Type',
      'environment': 'Environment',
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'url': 'URL',
      'expiresAt': 'Expires At',
      'revokedAt': 'Revoked At',
      'owner': 'Owner',
      'baseUrl': 'Base URL',
    };

    return labels[fieldKey] ?? fieldKey;
  }
}
