import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

/// Результат выбора документа
class DocumentPickerResult {
  final String id;
  final String name;

  const DocumentPickerResult({required this.id, required this.name});
}

/// Результат выбора нескольких документов
class DocumentPickerMultiResult {
  final List<DocumentPickerResult> documents;

  const DocumentPickerMultiResult({this.documents = const []});

  bool get isEmpty => documents.isEmpty;
  bool get isNotEmpty => documents.isNotEmpty;
  int get length => documents.length;
}

/// Состояние данных документов в пикере
class DocumentPickerData {
  final List<FilteredCardDto<DocumentCardDto>> documents;
  final bool hasMore;
  final bool isLoadingMore;
  final String? excludeDocumentId;

  const DocumentPickerData({
    this.documents = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.excludeDocumentId,
  });

  DocumentPickerData copyWith({
    List<FilteredCardDto<DocumentCardDto>>? documents,
    bool? hasMore,
    bool? isLoadingMore,
    String? excludeDocumentId,
  }) {
    return DocumentPickerData(
      documents: documents ?? this.documents,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      excludeDocumentId: excludeDocumentId ?? this.excludeDocumentId,
    );
  }
}
