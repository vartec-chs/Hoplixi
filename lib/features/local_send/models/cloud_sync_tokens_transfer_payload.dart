import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';

part 'cloud_sync_tokens_transfer_payload.freezed.dart';
part 'cloud_sync_tokens_transfer_payload.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum CloudSyncTokenExportMode { withoutRefresh, full }

@freezed
sealed class CloudSyncTokensTransferPayload
    with _$CloudSyncTokensTransferPayload {
  const factory CloudSyncTokensTransferPayload({
    required CloudSyncTokenExportMode exportMode,
    @Default(<AuthTokenEntry>[]) List<AuthTokenEntry> tokens,
  }) = _CloudSyncTokensTransferPayload;

  const CloudSyncTokensTransferPayload._();

  factory CloudSyncTokensTransferPayload.fromJson(Map<String, dynamic> json) =>
      _$CloudSyncTokensTransferPayloadFromJson(json);

  static CloudSyncTokensTransferPayload forExport({
    required List<AuthTokenEntry> tokens,
    required CloudSyncTokenExportMode exportMode,
  }) {
    final preparedTokens = tokens
        .map((token) => _prepareToken(token, exportMode))
        .toList(growable: false);
    return CloudSyncTokensTransferPayload(
      exportMode: exportMode,
      tokens: preparedTokens,
    );
  }

  static AuthTokenEntry _prepareToken(
    AuthTokenEntry token,
    CloudSyncTokenExportMode exportMode,
  ) {
    if (exportMode == CloudSyncTokenExportMode.full) {
      return token;
    }

    return token.copyWith(
      refreshToken: null,
      extraData: _scrubRefreshSensitiveData(token.extraData),
    );
  }

  static Map<String, dynamic> _scrubRefreshSensitiveData(
    Map<String, dynamic> value,
  ) {
    return value.map((key, dynamic rawValue) {
      return MapEntry(key, _scrubNestedValue(rawValue));
    })..removeWhere((key, _) => _isRefreshSensitiveKey(key.toString()));
  }

  static dynamic _scrubNestedValue(dynamic value) {
    if (value is Map) {
      return value.map((key, dynamic nestedValue) {
        return MapEntry(key.toString(), _scrubNestedValue(nestedValue));
      })..removeWhere((key, _) => _isRefreshSensitiveKey(key.toString()));
    }

    if (value is List) {
      return value.map<dynamic>(_scrubNestedValue).toList(growable: false);
    }

    return value;
  }

  static bool _isRefreshSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized == 'refreshtoken' ||
        normalized == 'refreshtokenexpiresat' ||
        normalized == 'refreshtokenexpiresin' ||
        normalized == 'refreshexpiresat' ||
        normalized == 'refreshexpiresin';
  }
}
