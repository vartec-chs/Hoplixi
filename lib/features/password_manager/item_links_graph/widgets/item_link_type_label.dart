import 'package:hoplixi/vault_db/core/scheme/tables/system/item_link/item_links.dart';

String itemLinkTypeLabel(ItemLinkType type) {
  return switch (type) {
    ItemLinkType.related => 'Связано',
    ItemLinkType.note => 'Заметка',
    ItemLinkType.attachment => 'Вложение',
    ItemLinkType.otpForPassword => 'OTP для пароля',
    ItemLinkType.supportContact => 'Контакт поддержки',
    ItemLinkType.purchaseDocument => 'Документ покупки',
    ItemLinkType.identityScan => 'Скан документа',
    ItemLinkType.identityPhoto => 'Фото документа',
    ItemLinkType.sshPublicKeyFile => 'SSH public key',
    ItemLinkType.sshPrivateKeyFile => 'SSH private key',
    ItemLinkType.certificateFile => 'Файл сертификата',
    ItemLinkType.certificatePrivateKeyFile => 'Ключ сертификата',
    ItemLinkType.other => 'Другое',
  };
}
