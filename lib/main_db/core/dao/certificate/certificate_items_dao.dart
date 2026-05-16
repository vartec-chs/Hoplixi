import 'package:drift/drift.dart';

import '../../main_store.dart';
import '../../tables/certificate/certificate_items.dart';

part 'certificate_items_dao.g.dart';

@DriftAccessor(tables: [CertificateItems])
class CertificateItemsDao extends DatabaseAccessor<MainStore>
    with _$CertificateItemsDaoMixin {
  CertificateItemsDao(super.db);

  Future<void> insertCertificate(CertificateItemsCompanion companion) {
    return into(certificateItems).insert(companion);
  }

  Future<int> updateCertificateByItemId(
    String itemId,
    CertificateItemsCompanion companion,
  ) {
    return (update(certificateItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .write(companion);
  }

  Future<CertificateItemsData?> getCertificateByItemId(String itemId) {
    return (select(certificateItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .getSingleOrNull();
  }

  Future<bool> existsCertificateByItemId(String itemId) async {
    final row = await (selectOnly(certificateItems)
          ..addColumns([certificateItems.itemId])
          ..where(certificateItems.itemId.equals(itemId)))
        .getSingleOrNull();

    return row != null;
  }

  Future<int> deleteCertificateByItemId(String itemId) {
    return (delete(certificateItems)..where((tbl) => tbl.itemId.equals(itemId)))
        .go();
  }

  Future<String?> getPrivateKeyByItemId(String itemId) async {
    final row = await (selectOnly(certificateItems)
          ..addColumns([certificateItems.privateKey])
          ..where(certificateItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(certificateItems.privateKey);
  }

  Future<String?> getPrivateKeyPasswordByItemId(String itemId) async {
    final row = await (selectOnly(certificateItems)
          ..addColumns([certificateItems.privateKeyPassword])
          ..where(certificateItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(certificateItems.privateKeyPassword);
  }

  Future<String?> getPasswordForPfxByItemId(String itemId) async {
    final row = await (selectOnly(certificateItems)
          ..addColumns([certificateItems.passwordForPfx])
          ..where(certificateItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(certificateItems.passwordForPfx);
  }

  Future<String?> getCertificatePemByItemId(String itemId) async {
    final row = await (selectOnly(certificateItems)
          ..addColumns([certificateItems.certificatePem])
          ..where(certificateItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(certificateItems.certificatePem);
  }

  Future<Uint8List?> getCertificateBlobByItemId(String itemId) async {
    final row = await (selectOnly(certificateItems)
          ..addColumns([certificateItems.certificateBlob])
          ..where(certificateItems.itemId.equals(itemId)))
        .getSingleOrNull();
    return row?.read(certificateItems.certificateBlob);
  }
}
