import 'package:hoplixi/vault_db/core/models/dto/system/store_meta_dto.dart';
import 'package:hoplixi/vault_db/core/api/vault_core_api.dart';

typedef Session = ({
  VaultCoreApi api,
  StoreInfoDto info,
  String storeDirectoryPath,
});
