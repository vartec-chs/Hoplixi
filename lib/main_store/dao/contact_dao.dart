import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/contact_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/contact_items.dart';
import 'package:hoplixi/main_store/tables/vault_items.dart';
import 'package:uuid/uuid.dart';

part 'contact_dao.g.dart';

@DriftAccessor(tables: [VaultItems, ContactItems])
class ContactDao extends DatabaseAccessor<MainStore>
    with _$ContactDaoMixin
    implements BaseMainEntityDao {
  ContactDao(super.db);

  Future<List<(VaultItemsData, ContactItemsData)>> getAllContacts() async {
    final query = select(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
    ]);
    final rows = await query.get();
    return rows
        .map((row) => (row.readTable(vaultItems), row.readTable(contactItems)))
        .toList();
  }

  Future<(VaultItemsData, ContactItemsData)?> getById(String id) async {
    final query = select(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
    ])..where(vaultItems.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(vaultItems), row.readTable(contactItems));
  }

  Stream<List<(VaultItemsData, ContactItemsData)>> watchAllContacts() {
    final query = select(vaultItems).join([
      innerJoin(contactItems, contactItems.itemId.equalsExp(vaultItems.id)),
    ])..orderBy([OrderingTerm.desc(vaultItems.modifiedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (row.readTable(vaultItems), row.readTable(contactItems)),
          )
          .toList(),
    );
  }

  Future<String> createContact(CreateContactDto dto) {
    final id = const Uuid().v4();

    return db.transaction(() async {
      await into(vaultItems).insert(
        VaultItemsCompanion.insert(
          id: Value(id),
          type: VaultItemType.contact,
          name: dto.name,
          description: Value(dto.description),
          noteId: Value(dto.noteId),
          categoryId: Value(dto.categoryId),
        ),
      );

      await into(contactItems).insert(
        ContactItemsCompanion.insert(
          itemId: id,
          phone: Value(dto.phone),
          email: Value(dto.email),
          company: Value(dto.company),
          jobTitle: Value(dto.jobTitle),
          address: Value(dto.address),
          website: Value(dto.website),
          birthday: Value(dto.birthday),
          isEmergencyContact: Value(dto.isEmergencyContact ?? false),
          notes: Value(dto.notes),
        ),
      );

      await db.vaultItemDao.insertTags(id, dto.tagsIds);
      return id;
    });
  }

  Future<bool> updateContact(String id, UpdateContactDto dto) {
    return db.transaction(() async {
      final vaultCompanion = VaultItemsCompanion(
        name: dto.name != null ? Value(dto.name!) : const Value.absent(),
        description: Value(dto.description),
        noteId: Value(dto.noteId),
        categoryId: Value(dto.categoryId),
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

      final itemCompanion = ContactItemsCompanion(
        phone: Value(dto.phone),
        email: Value(dto.email),
        company: Value(dto.company),
        jobTitle: Value(dto.jobTitle),
        address: Value(dto.address),
        website: Value(dto.website),
        birthday: Value(dto.birthday),
        isEmergencyContact: dto.isEmergencyContact != null
            ? Value(dto.isEmergencyContact!)
            : const Value.absent(),
        notes: Value(dto.notes),
      );

      await (update(
        contactItems,
      )..where((i) => i.itemId.equals(id))).write(itemCompanion);

      if (dto.tagsIds != null) {
        await db.vaultItemDao.syncTags(id, dto.tagsIds!);
      }

      return true;
    });
  }

  @override
  Future<bool> incrementUsage(String id) => db.vaultItemDao.incrementUsage(id);

  @override
  Future<bool> permanentDelete(String id) =>
      db.vaultItemDao.permanentDelete(id);

  @override
  Future<bool> restoreFromDeleted(String id) =>
      db.vaultItemDao.restoreFromDeleted(id);

  @override
  Future<bool> softDelete(String id) => db.vaultItemDao.softDelete(id);

  @override
  Future<bool> toggleArchive(String id, bool isArchived) =>
      db.vaultItemDao.toggleArchive(id, isArchived);

  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) =>
      db.vaultItemDao.toggleFavorite(id, isFavorite);

  @override
  Future<bool> togglePin(String id, bool isPinned) =>
      db.vaultItemDao.togglePin(id, isPinned);
}
