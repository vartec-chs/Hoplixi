import '../../../tables/api_key/api_key_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class ApiKeyHistoryPayload extends HistoryPayload {
  const ApiKeyHistoryPayload({
    required this.service,
    this.key,
    this.tokenType,
    this.tokenTypeOther,
    this.environment,
    this.environmentOther,
    this.expiresAt,
    this.revokedAt,
    this.rotationPeriodDays,
    this.lastRotatedAt,
    this.owner,
    this.baseUrl,
    this.scopesText,
  });

  final String service;
  final String? key;
  final ApiKeyTokenType? tokenType;
  final String? tokenTypeOther;
  final ApiKeyEnvironment? environment;
  final String? environmentOther;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final int? rotationPeriodDays;
  final DateTime? lastRotatedAt;
  final String? owner;
  final String? baseUrl;
  final String? scopesText;

  @override
  VaultItemType get type => VaultItemType.apiKey;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'apiKey.service',
        label: 'Service',
        value: service,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.key',
        label: 'API key',
        value: key,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.tokenType',
        label: 'Token type',
        value: tokenType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.tokenTypeOther',
        label: 'Token type other',
        value: tokenTypeOther,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.environment',
        label: 'Environment',
        value: environment?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.environmentOther',
        label: 'Environment other',
        value: environmentOther,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'apiKey.expiresAt',
        label: 'Expires at',
        value: expiresAt,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'apiKey.revokedAt',
        label: 'Revoked at',
        value: revokedAt,
      ),
      HistoryFieldSnapshot<int>(
        key: 'apiKey.rotationPeriodDays',
        label: 'Rotation period',
        value: rotationPeriodDays,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'apiKey.lastRotatedAt',
        label: 'Last rotated at',
        value: lastRotatedAt,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.owner',
        label: 'Owner',
        value: owner,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.baseUrl',
        label: 'Base URL',
        value: baseUrl,
      ),
      HistoryFieldSnapshot<String>(
        key: 'apiKey.scopesText',
        label: 'Scopes',
        value: scopesText,
      ),
    ];
  }
}
