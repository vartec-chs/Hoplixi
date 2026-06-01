import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';

typedef VaultEntityCreate<TCreate extends Object> =
    AsyncDBResult<String> Function(TCreate dto);
typedef VaultEntityUpdate<TPatch extends Object> =
    AsyncDBResult<Unit> Function(TPatch dto);
typedef VaultEntityStateMutation =
    AsyncDBResult<Unit> Function(String itemId);
typedef VaultEntityBoolStateMutation =
    AsyncDBResult<Unit> Function(String itemId, bool value);
typedef VaultEntityGetView<TView extends Object> =
    AsyncDBResult<Optional<TView>> Function(String itemId);
typedef VaultEntityGetCard<TCard extends Object> =
    AsyncDBResult<Optional<TCard>> Function(String itemId);
typedef VaultEntityListCards<TCard extends Object> =
    AsyncDBResult<List<TCard>> Function({int limit, int offset});

/// Public command API for one concrete vault entity type.
class VaultEntityTypeApi<
  TCreate extends Object,
  TPatch extends Object,
  TView extends Object,
  TCard extends Object
> {
  const VaultEntityTypeApi({
    required VaultEntityCreate<TCreate> create,
    required VaultEntityUpdate<TPatch> update,
    required VaultEntityGetView<TView> getView,
    required VaultEntityGetCard<TCard> getCard,
    required VaultEntityListCards<TCard> listCards,
    required VaultEntityStateMutation softDelete,
    required VaultEntityStateMutation recover,
    required VaultEntityStateMutation archive,
    required VaultEntityStateMutation restoreArchived,
    required VaultEntityBoolStateMutation setFavorite,
    required VaultEntityBoolStateMutation setPinned,
    required VaultEntityStateMutation deletePermanently,
  }) : _create = create,
       _update = update,
       _getView = getView,
       _getCard = getCard,
       _listCards = listCards,
       _softDelete = softDelete,
       _recover = recover,
       _archive = archive,
       _restoreArchived = restoreArchived,
       _setFavorite = setFavorite,
       _setPinned = setPinned,
       _deletePermanently = deletePermanently;

  final VaultEntityCreate<TCreate> _create;
  final VaultEntityUpdate<TPatch> _update;
  final VaultEntityGetView<TView> _getView;
  final VaultEntityGetCard<TCard> _getCard;
  final VaultEntityListCards<TCard> _listCards;
  final VaultEntityStateMutation _softDelete;
  final VaultEntityStateMutation _recover;
  final VaultEntityStateMutation _archive;
  final VaultEntityStateMutation _restoreArchived;
  final VaultEntityBoolStateMutation _setFavorite;
  final VaultEntityBoolStateMutation _setPinned;
  final VaultEntityStateMutation _deletePermanently;

  AsyncDBResult<String> create(TCreate dto) {
    return _create(dto);
  }

  AsyncDBResult<Unit> update(TPatch dto) {
    return _update(dto);
  }

  AsyncDBResult<Optional<TView>> getView(String itemId) {
    return _getView(itemId);
  }

  AsyncDBResult<Optional<TCard>> getCard(String itemId) {
    return _getCard(itemId);
  }

  AsyncDBResult<List<TCard>> listCards({int limit = 50, int offset = 0}) {
    return _listCards(limit: limit, offset: offset);
  }

  AsyncDBResult<Unit> softDelete(String itemId) {
    return _softDelete(itemId);
  }

  AsyncDBResult<Unit> recover(String itemId) {
    return _recover(itemId);
  }

  AsyncDBResult<Unit> archive(String itemId) {
    return _archive(itemId);
  }

  AsyncDBResult<Unit> restoreArchived(String itemId) {
    return _restoreArchived(itemId);
  }

  AsyncDBResult<Unit> setFavorite(String itemId, bool value) {
    return _setFavorite(itemId, value);
  }

  AsyncDBResult<Unit> setPinned(String itemId, bool value) {
    return _setPinned(itemId, value);
  }

  AsyncDBResult<Unit> deletePermanently(String itemId) {
    return _deletePermanently(itemId);
  }
}
