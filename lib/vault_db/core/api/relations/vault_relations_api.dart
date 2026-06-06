import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/item_link_dto.dart';
import 'package:hoplixi/vault_db/core/scheme/tables/vault_items/vault_items.dart';
import 'package:hoplixi/vault_db/core/services/relations/vault_item_relations_service.dart';
import 'package:hoplixi/vault_db/core/services/vault_item_mutation_service.dart';

/// Public API boundary for vault item relations.
class VaultRelationsApi {
  const VaultRelationsApi({
    required this._relationsService,
    required this._mutationService,
  });

  final VaultItemRelationsService _relationsService;
  final VaultItemMutationService _mutationService;

  AsyncDBResult<Unit> replaceItemTags({
    required String itemId,
    required VaultItemType type,
    required List<String> tagIds,
  }) {
    return _mutationService.replaceItemTags(
      itemId: itemId,
      type: type,
      tagIds: tagIds,
    );
  }

  AsyncDBResult<Unit> addTags({
    required String itemId,
    required List<String> tagIds,
  }) {
    return _relationsService.addTags(itemId: itemId, tagIds: tagIds);
  }

  AsyncDBResult<Unit> removeTags({
    required String itemId,
    required List<String> tagIds,
  }) {
    return _relationsService.removeTags(itemId: itemId, tagIds: tagIds);
  }

  AsyncDBResult<Unit> clearTags(String itemId) {
    return _relationsService.clearTags(itemId);
  }

  AsyncDBResult<List<String>> getTagIds(String itemId) {
    return _relationsService.getTagIdsForItem(itemId);
  }

  AsyncDBResult<Unit> changeItemCategory({
    required String itemId,
    required VaultItemType type,
    required String? categoryId,
  }) {
    return _mutationService.changeItemCategory(
      itemId: itemId,
      type: type,
      categoryId: categoryId,
    );
  }

  AsyncDBResult<Optional<String>> getCategoryId(String itemId) {
    return _relationsService.getCategoryIdForItem(itemId);
  }

  AsyncDBResult<String> createLink(CreateItemLinkDto dto) {
    return _relationsService.createLink(dto);
  }

  AsyncDBResult<Unit> updateLink(PatchItemLinkDto dto) {
    return _relationsService.updateLink(dto);
  }

  AsyncDBResult<Unit> deleteLink(String linkId) {
    return _relationsService.deleteLink(linkId);
  }
}
