import 'package:freezed_annotation/freezed_annotation.dart';

part 'encrypted_transfer_envelope.freezed.dart';
part 'encrypted_transfer_envelope.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum SecurePayloadKind { cloudSyncAuthTokens }

@freezed
sealed class EncryptedTransferEnvelope with _$EncryptedTransferEnvelope {
  const factory EncryptedTransferEnvelope({
    required int version,
    required SecurePayloadKind kind,
    required String algorithm,
    required String salt,
    required String nonce,
    required String cipherText,
    required String mac,
  }) = _EncryptedTransferEnvelope;

  factory EncryptedTransferEnvelope.fromJson(Map<String, dynamic> json) =>
      _$EncryptedTransferEnvelopeFromJson(json);
}
