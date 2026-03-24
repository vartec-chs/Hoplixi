import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_crypto/services/key_derivation_service.dart';
import 'package:hoplixi/features/local_send/models/cloud_sync_tokens_transfer_payload.dart';
import 'package:hoplixi/features/local_send/models/encrypted_transfer_envelope.dart';

class LocalSendSecurePayloadException implements Exception {
  const LocalSendSecurePayloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalSendSecurePayloadCryptoService {
  const LocalSendSecurePayloadCryptoService();

  static const int _payloadVersion = 1;
  static const String _algorithmName = 'aes_gcm_256+argon2id';
  static final Cipher _cipher = AesGcm.with256bits();

  Future<EncryptedTransferEnvelope> encryptCloudSyncTokens({
    required CloudSyncTokensTransferPayload payload,
    required String password,
  }) async {
    _validatePassword(password);

    final salt = KeyDerivationService.generateSecureRandomBytes(
      KeyDerivationService.defaultSaltLength,
    );
    final derivedKeys = await KeyDerivationService.deriveKeyPair(
      password: password,
      salt: salt,
    );
    final nonce = _cipher.newNonce();
    final clearBytes = utf8.encode(jsonEncode(payload.toJson()));
    final secretBox = await _cipher.encrypt(
      clearBytes,
      secretKey: derivedKeys.encryptionKey,
      nonce: nonce,
      aad: _buildAdditionalData(
        SecurePayloadKind.cloudSyncAuthTokens,
        version: _payloadVersion,
      ),
    );

    return EncryptedTransferEnvelope(
      version: _payloadVersion,
      kind: SecurePayloadKind.cloudSyncAuthTokens,
      algorithm: _algorithmName,
      salt: base64Encode(salt),
      nonce: base64Encode(secretBox.nonce),
      cipherText: base64Encode(secretBox.cipherText),
      mac: base64Encode(secretBox.mac.bytes),
    );
  }

  Future<CloudSyncTokensTransferPayload> decryptCloudSyncTokens({
    required EncryptedTransferEnvelope envelope,
    required String password,
  }) async {
    _validatePassword(password);

    if (envelope.kind != SecurePayloadKind.cloudSyncAuthTokens) {
      throw const LocalSendSecurePayloadException(
        'Этот защищённый пакет не содержит OAuth-токены.',
      );
    }

    if (envelope.algorithm != _algorithmName) {
      throw const LocalSendSecurePayloadException(
        'Неподдерживаемый алгоритм защищённого пакета.',
      );
    }

    final salt = _decodeBase64(envelope.salt, fieldName: 'salt');
    final nonce = _decodeBase64(envelope.nonce, fieldName: 'nonce');
    final cipherText = _decodeBase64(
      envelope.cipherText,
      fieldName: 'cipherText',
    );
    final macBytes = _decodeBase64(envelope.mac, fieldName: 'mac');
    final derivedKeys = await KeyDerivationService.deriveKeyPair(
      password: password,
      salt: salt,
    );

    try {
      final clearBytes = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: derivedKeys.encryptionKey,
        aad: _buildAdditionalData(envelope.kind, version: envelope.version),
      );
      final json = jsonDecode(utf8.decode(clearBytes));
      if (json is! Map<String, dynamic>) {
        throw const LocalSendSecurePayloadException(
          'Защищённый пакет имеет неверный формат.',
        );
      }
      return CloudSyncTokensTransferPayload.fromJson(json);
    } on SecretBoxAuthenticationError {
      throw const LocalSendSecurePayloadException(
        'Неверный пароль или повреждённый защищённый пакет.',
      );
    } on FormatException {
      throw const LocalSendSecurePayloadException(
        'Защищённый пакет имеет неверный формат.',
      );
    }
  }

  Uint8List _buildAdditionalData(
    SecurePayloadKind kind, {
    required int version,
  }) {
    return Uint8List.fromList(
      utf8.encode('hoplixi.local_send.secure_payload.${kind.name}.v$version'),
    );
  }

  Uint8List _decodeBase64(String value, {required String fieldName}) {
    try {
      return Uint8List.fromList(base64Decode(value));
    } on FormatException {
      throw LocalSendSecurePayloadException(
        'Поле $fieldName в защищённом пакете повреждено.',
      );
    }
  }

  void _validatePassword(String password) {
    if (password.trim().length < 8) {
      throw const LocalSendSecurePayloadException(
        'Пароль для защищённого пакета должен быть не короче 8 символов.',
      );
    }
  }
}
