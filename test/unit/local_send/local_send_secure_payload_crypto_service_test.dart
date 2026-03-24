import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/local_send/models/cloud_sync_tokens_transfer_payload.dart';
import 'package:hoplixi/features/local_send/services/local_send_secure_payload_crypto_service.dart';

void main() {
  const cryptoService = LocalSendSecurePayloadCryptoService();

  AuthTokenEntry buildToken({
    required String id,
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic> extraData = const <String, dynamic>{},
  }) {
    return AuthTokenEntry(
      id: id,
      provider: CloudSyncProvider.google,
      accessToken: accessToken,
      refreshToken: refreshToken,
      appCredentialId: 'credential-google',
      accountEmail: '$id@example.com',
      accountName: 'Account $id',
      extraData: extraData,
    );
  }

  group('LocalSendSecurePayloadCryptoService', () {
    test('round-trips multiple OAuth tokens', () async {
      final payload = CloudSyncTokensTransferPayload.forExport(
        tokens: [
          buildToken(id: 'token-1', accessToken: 'access-1'),
          buildToken(
            id: 'token-2',
            accessToken: 'access-2',
            refreshToken: 'refresh-2',
          ),
        ],
        exportMode: CloudSyncTokenExportMode.full,
      );

      final envelope = await cryptoService.encryptCloudSyncTokens(
        payload: payload,
        password: 'super_secret_password',
      );
      final decrypted = await cryptoService.decryptCloudSyncTokens(
        envelope: envelope,
        password: 'super_secret_password',
      );

      expect(decrypted.exportMode, CloudSyncTokenExportMode.full);
      expect(decrypted.tokens, hasLength(2));
      expect(decrypted.tokens[0].accessToken, 'access-1');
      expect(decrypted.tokens[1].refreshToken, 'refresh-2');
    });

    test('removes refresh data in withoutRefresh mode', () {
      final payload = CloudSyncTokensTransferPayload.forExport(
        tokens: [
          buildToken(
            id: 'token-1',
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            extraData: const {
              'id_token': 'id-1',
              'refresh_token': 'secret-refresh',
              'nested': {'refreshToken': 'nested-secret', 'safe': 'value'},
            },
          ),
        ],
        exportMode: CloudSyncTokenExportMode.withoutRefresh,
      );

      expect(payload.tokens.single.refreshToken, isNull);
      expect(
        payload.tokens.single.extraData.containsKey('refresh_token'),
        isFalse,
      );
      expect(
        (payload.tokens.single.extraData['nested'] as Map<String, dynamic>)
            .containsKey('refreshToken'),
        isFalse,
      );
      expect(
        (payload.tokens.single.extraData['nested']
            as Map<String, dynamic>)['safe'],
        'value',
      );
    });

    test('throws controlled error for wrong password', () async {
      final payload = CloudSyncTokensTransferPayload.forExport(
        tokens: [buildToken(id: 'token-1', accessToken: 'access-1')],
        exportMode: CloudSyncTokenExportMode.full,
      );
      final envelope = await cryptoService.encryptCloudSyncTokens(
        payload: payload,
        password: 'super_secret_password',
      );

      expect(
        () => cryptoService.decryptCloudSyncTokens(
          envelope: envelope,
          password: 'wrong_password',
        ),
        throwsA(isA<LocalSendSecurePayloadException>()),
      );
    });
  });
}
