import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../models/dto/document_version_dto.dart';

class DocumentVersionHashService {
  const DocumentVersionHashService();

  String? aggregatePageHashes(List<CreateDocumentVersionPageDto> pages) {
    if (pages.isEmpty) {
      return null;
    }

    final sortedPages = List<CreateDocumentVersionPageDto>.from(pages)
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    final StringBuffer payloadBuffer = StringBuffer();
    for (final page in sortedPages) {
      if (page.pageSha256Hash == null) {
        return null;
      }
      payloadBuffer.write('${page.pageNumber}:${page.pageSha256Hash}\n');
    }

    final bytes = utf8.encode(payloadBuffer.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
