import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/system/tag_dto.dart';
import 'package:hoplixi/vault_db/core/repositories/base/system/tag_repository.dart';

/// Public API boundary for tag queries and commands.
class TagsApi {
  const TagsApi({required this._repository});

  final TagRepository _repository;

  AsyncDBResult<String> create(CreateTagDto dto) {
    return _repository.createTag(dto);
  }

  AsyncDBResult<Unit> update(PatchTagDto dto) {
    return _repository.updateTag(dto);
  }

  AsyncDBResult<Unit> delete(String tagId) {
    return _repository.deleteTag(tagId);
  }

  AsyncDBResult<Optional<TagViewDto>> get(String tagId) {
    return _repository.getTag(tagId);
  }

  AsyncDBResult<List<TagCardDto>> list() {
    return _repository.getAllTags();
  }

  AsyncDBResult<List<TagCardDto>> search(String query) {
    return _repository.searchTags(query);
  }

  AsyncDBResult<bool> exists(String tagId) {
    return _repository.existsTag(tagId);
  }
}
