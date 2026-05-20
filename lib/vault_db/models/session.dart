import 'package:hoplixi/vault_db/core/models/dto/system/store_meta_dto.dart';
import 'package:hoplixi/vault_db/core/vault_db.dart';

typedef Session = ({
  VaultDB store,
  StoreInfoDto info,
  String storeDirectoryPath,
});
