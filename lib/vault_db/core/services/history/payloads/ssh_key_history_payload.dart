import '../../../tables/ssh_key/ssh_key_items.dart';
import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class SshKeyHistoryPayload extends HistoryPayload {
  const SshKeyHistoryPayload({
    this.publicKey,
    this.privateKey,
    this.keyType,
    this.keyTypeOther,
    this.keySize,
  });

  final String? publicKey;
  final String? privateKey;
  final SshKeyType? keyType;
  final String? keyTypeOther;
  final int? keySize;

  @override
  VaultItemType get type => VaultItemType.sshKey;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'sshKey.publicKey',
        label: 'Public key',
        value: publicKey,
      ),
      HistoryFieldSnapshot<String>(
        key: 'sshKey.privateKey',
        label: 'Private key',
        value: privateKey,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'sshKey.keyType',
        label: 'Key type',
        value: keyType?.name,
      ),
      HistoryFieldSnapshot<String>(
        key: 'sshKey.keyTypeOther',
        label: 'Key type other',
        value: keyTypeOther,
      ),
      HistoryFieldSnapshot<int>(
        key: 'sshKey.keySize',
        label: 'Key size',
        value: keySize,
      ),
    ];
  }
}
