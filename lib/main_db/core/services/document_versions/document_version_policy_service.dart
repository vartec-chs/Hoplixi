import 'package:result_dart/result_dart.dart';

import '../../errors/db_error.dart';
import '../../errors/db_result.dart';
import '../../models/dto/document_version_dto.dart';
import '../../tables/document/document_types.dart';

class DocumentVersionPolicyService {
  const DocumentVersionPolicyService();

  DbResult<Unit> validateCreateVersion(CreateDocumentVersionDto dto) {
    if (dto.documentId.trim().isEmpty) {
      return const Failure(
        DBCoreError.validation(
          code: 'document.version.create.document_id_empty',
          message: 'documentId must not be empty',
          field: 'documentId',
        ),
      );
    }

    if (dto.pages.isEmpty) {
      return const Failure(
        DBCoreError.validation(
          code: 'document.version.create.pages_empty',
          message: 'pages must not be empty',
          field: 'pages',
        ),
      );
    }

    if (dto.documentType == DocumentType.other &&
        (dto.documentTypeOther == null || dto.documentTypeOther!.trim().isEmpty)) {
      return const Failure(
        DBCoreError.validation(
          code: 'document.version.create.type_other_empty',
          message: 'documentTypeOther must not be empty when type is other',
          field: 'documentTypeOther',
        ),
      );
    }

    if (dto.documentType != DocumentType.other && dto.documentTypeOther != null) {
      return const Failure(
        DBCoreError.validation(
          code: 'document.version.create.type_other_not_null',
          message: 'documentTypeOther must be null when type is not other',
          field: 'documentTypeOther',
        ),
      );
    }

    if (dto.aggregateSha256Hash != null && dto.aggregateSha256Hash!.trim().isEmpty) {
      return const Failure(
        DBCoreError.validation(
          code: 'document.version.create.aggregate_hash_empty',
          message: 'aggregateSha256Hash must not be empty',
          field: 'aggregateSha256Hash',
        ),
      );
    }

    final pageNumbers = <int>{};
    final pageIds = <String>{};
    int primaryCount = 0;

    for (final page in dto.pages) {
      if (page.pageNumber <= 0) {
        return const Failure(
          DBCoreError.validation(
            code: 'document.version.create.page_number_invalid',
            message: 'pageNumber must be positive',
            field: 'pageNumber',
          ),
        );
      }
      if (!pageNumbers.add(page.pageNumber)) {
        return Failure(
          DBCoreError.validation(
            code: 'document.version.create.page_number_duplicate',
            message: 'Duplicate pageNumber found: ${page.pageNumber}',
            field: 'pageNumber',
          ),
        );
      }
      if (page.pageId != null) {
        if (!pageIds.add(page.pageId!)) {
          return Failure(
            DBCoreError.validation(
              code: 'document.version.create.page_id_duplicate',
              message: 'Duplicate pageId found: ${page.pageId}',
              field: 'pageId',
            ),
          );
        }
      }
      if (page.pageSha256Hash != null && page.pageSha256Hash!.trim().isEmpty) {
        return const Failure(
          DBCoreError.validation(
            code: 'document.version.create.page_hash_empty',
            message: 'pageSha256Hash must not be empty',
            field: 'pageSha256Hash',
          ),
        );
      }
      if (page.isPrimary) {
        primaryCount++;
      }
    }

    if (primaryCount > 1) {
      return const Failure(
        DBCoreError.validation(
          code: 'document.version.create.multiple_primary',
          message: 'Only one primary page is allowed',
          field: 'isPrimary',
        ),
      );
    }

    return const Success(unit);
  }
}
