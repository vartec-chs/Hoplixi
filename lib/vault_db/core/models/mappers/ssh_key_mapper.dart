import 'package:hoplixi/vault_db/core/models/dto/ssh_key_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

extension SshKeyItemsDataMapper on SshKeyItemsData {
  SshKeyDataDto toSshKeyDataDto() {
    return SshKeyDataDto(
      publicKey: publicKey,
      privateKey: privateKey,
      keyType: keyType,
      keyTypeOther: keyTypeOther,
      keySize: keySize,
    );
  }

  SshKeyCardDataDto toSshKeyCardDataDto() {
    return SshKeyCardDataDto(
      publicKey: publicKey,
      keyType: keyType,
      keySize: keySize,
      hasPrivateKey: privateKey?.isNotEmpty ?? false,
    );
  }
}
