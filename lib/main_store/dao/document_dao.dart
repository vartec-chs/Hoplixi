import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/dto/document_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/document_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [VaultItems, DocumentItems])
class DocumentDao extends DatabaseAccessor<MainStore> with _$DocumentDaoMixin {
  DocumentDao(super.db);

  /// Получить все документы (JOIN)
  Future<List<(VaultItemsData, DocumentItemsData)>> getAllDocuments() async {
    final query = select(vaultItems).join([
      innerJoin(documentItems, documentItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(documentItems)))
        .toList();
  }

  /// Получить документ по ID
  Future<(VaultItemsData, DocumentItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(documentItems, documentItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(documentItems));
  }

  /// Создать новый документ
  Future<String> createDocument(CreateDocumentDto dto) {
    final uuid = const Uuid().v4();
    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(uuid),
          type: VaultItemType.document,
          name: dto.title ?? 'Document',
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );
      await into(documentItems).insert(
        DocumentItemsCompanion.insert(
          itemId: uuid,
          documentType: Value(dto.documentType),
          aggregatedText: Value(dto.aggregatedText),
          aggregateHash: Value(dto.aggregateHash),
          pageCount: Value(dto.pageCount),
        ),
      );
      await db.vaultItemDao.insertTags(uuid, dto.tagsIds);
      return uuid;
    });
  }

  /// Обновить документ
  Future<bool> updateDocument(String id, UpdateDocumentDto dto) {
    return db.transaction(() async {
      final vaultCompanion = VaultItemsCompanion(
        name: dto.title != null ? Value(dto.title!) : const Value.absent(),
        description: dto.description != null
            ? Value(dto.description)
            : const Value.absent(),
        noteId: dto.noteId != null ? Value(dto.noteId) : const Value.absent(),
        categoryId: dto.categoryId != null
            ? Value(dto.categoryId)
            : const Value.absent(),
        isFavorite: dto.isFavorite != null
            ? Value(dto.isFavorite!)
            : const Value.absent(),
        isArchived: dto.isArchived != null
            ? Value(dto.isArchived!)
            : const Value.absent(),
        isPinned: dto.isPinned != null
            ? Value(dto.isPinned!)
            : const Value.absent(),
        modifiedAt: Value(DateTime.now()),
      );
      await (update(
        vaultItems,
      )..where((v) => v.id.equals(id))).write(vaultCompanion);

      final docCompanion = DocumentItemsCompanion(
        documentType: dto.documentType != null
            ? Value(dto.documentType)
            : const Value.absent(),
        aggregatedText: dto.aggregatedText != null
            ? Value(dto.aggregatedText)
            : const Value.absent(),
        aggregateHash: dto.aggregateHash != null
            ? Value(dto.aggregateHash)
            : const Value.absent(),
        pageCount: dto.pageCount != null
            ? Value(dto.pageCount!)
            : const Value.absent(),
      );
      await (update(
        documentItems,
      )..where((d) => d.itemId.equals(id))).write(docCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }
      return true;
    });
  }

  /// Поиск документов
  Future<List<(VaultItemsData, DocumentItemsData)>> searchDocuments(
    String query,
  ) async {
    final q = query.toLowerCase();
    final result =
        select(vaultItems).join([
          innerJoin(
            documentItems,
            documentItems.itemId.equalsExp(vaultItems.id),
          ),
        ])..where(
          vaultItems.name.lower().like('%$q%') |
              vaultItems.description.lower().like('%$q%') |
              documentItems.aggregatedText.lower().like('%$q%'),
        );
    final rows = await result.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(documentItems)))
        .toList();
  }
}
