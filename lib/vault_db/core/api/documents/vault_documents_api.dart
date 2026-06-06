import 'package:result_dart/result_dart.dart';

import 'package:hoplixi/vault_db/core/errors/db_result.dart';
import 'package:hoplixi/vault_db/core/models/dto/document_version_dto.dart';
import 'package:hoplixi/vault_db/core/services/document_versions/document_version_service.dart';

/// Public API boundary for document versions.
class VaultDocumentsApi {
  const VaultDocumentsApi({required this._versionService});

  final DocumentVersionService _versionService;

  AsyncDBResult<DocumentVersionViewDto> createVersion(
    CreateDocumentVersionDto dto,
  ) {
    return _versionService.createVersion(dto);
  }

  AsyncDBResult<Unit> activateVersion({
    required String documentId,
    required String versionId,
  }) {
    return _versionService.activateVersion(
      documentId: documentId,
      versionId: versionId,
    );
  }

  AsyncDBResult<List<DocumentVersionCardDto>> getVersions({
    required String documentId,
    int? limit,
    int? offset,
  }) {
    return _versionService.getVersions(
      documentId: documentId,
      limit: limit,
      offset: offset,
    );
  }

  AsyncDBResult<DocumentVersionViewDto> getVersionDetail(String versionId) {
    return _versionService.getVersionDetail(versionId: versionId);
  }

  AsyncDBResult<DocumentVersionViewDto> getCurrentVersion(String documentId) {
    return _versionService.getCurrentVersion(documentId: documentId);
  }

  AsyncDBResult<Unit> deleteVersion({
    required String documentId,
    required String versionId,
  }) {
    return _versionService.deleteVersion(
      documentId: documentId,
      versionId: versionId,
    );
  }
}
