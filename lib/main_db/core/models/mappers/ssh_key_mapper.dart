import 'package:hoplixi/main_db/core/models/dto/ssh_key_dto.dart';
import 'package:hoplixi/main_db/core/main_store.dart';

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
