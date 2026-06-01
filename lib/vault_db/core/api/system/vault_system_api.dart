import 'package:hoplixi/vault_db/core/api/system/categories_api.dart';
import 'package:hoplixi/vault_db/core/api/system/icons_api.dart';
import 'package:hoplixi/vault_db/core/api/system/tags_api.dart';
import 'package:hoplixi/vault_db/core/repositories/vault_repositories.dart';

/// Public API boundary for vault system dictionaries and metadata.
class VaultSystemApi {
  VaultSystemApi({required VaultRepositories repositories})
    : categories = CategoriesApi(repository: repositories.category),
      tags = TagsApi(repository: repositories.tag),
      icons = IconsApi(repository: repositories.icon);

  final CategoriesApi categories;
  final TagsApi tags;
  final IconsApi icons;
}
