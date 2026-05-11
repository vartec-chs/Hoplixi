import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../vault_items/vault_items.dart';

enum ItemLinkType {
  related,
  note,
  attachment,
  otpForPassword,
  supportContact,
  purchaseDocument,
  identityScan,
  identityPhoto,
  sshPublicKeyFile,
  sshPrivateKeyFile,
  certificateFile,
  certificatePrivateKeyFile,
  other,
}

@DataClassName('ItemLinksData')
class ItemLinks extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  TextColumn get sourceItemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get targetItemId =>
      text().references(VaultItems, #id, onDelete: KeyAction.cascade)();

  TextColumn get relationType => textEnum<ItemLinkType>()();

  TextColumn get relationTypeOther =>
      text().withLength(min: 1, max: 255).nullable()();

  TextColumn get label => text().withLength(min: 1, max: 255).nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'item_links';

  @override
  List<String> get customConstraints => [
    '''
    CONSTRAINT ${ItemLinkConstraint.noSelfLink.constraintName}
    CHECK (
      source_item_id != target_item_id
    )
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.relationTypeOtherRequired.constraintName}
    CHECK (
      relation_type != 'other'
      OR (
        relation_type_other IS NOT NULL
        AND length(trim(relation_type_other)) > 0
      )
    )
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.relationTypeOtherMustBeNull.constraintName}
    CHECK (
      relation_type = 'other'
      OR relation_type_other IS NULL
    )
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.labelNotBlank.constraintName}
    CHECK (
      label IS NULL
      OR length(trim(label)) > 0
    )
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.sortOrderNonNegative.constraintName}
    CHECK (
      sort_order >= 0
    )
    ''',
  ];
}

enum ItemLinkConstraint {
  noSelfLink('chk_item_links_no_self_link'),

  relationTypeOtherRequired('chk_item_links_relation_type_other_required'),

  relationTypeOtherMustBeNull('chk_item_links_relation_type_other_must_be_null'),

  labelNotBlank('chk_item_links_label_not_blank'),

  sortOrderNonNegative('chk_item_links_sort_order_non_negative');

  const ItemLinkConstraint(this.constraintName);

  final String constraintName;
}

enum ItemLinkIndex {
  sourceItemId('idx_item_links_source_item_id'),
  targetItemId('idx_item_links_target_item_id'),
  relationType('idx_item_links_relation_type'),
  sourceRelationType('idx_item_links_source_relation_type'),
  targetRelationType('idx_item_links_target_relation_type'),
  sourceSortOrder('idx_item_links_source_sort_order'),
  uniqueLink('uq_item_links_source_target_relation_type');

  const ItemLinkIndex(this.indexName);

  final String indexName;
}

final List<String> itemLinksTableIndexes = [
  'CREATE INDEX IF NOT EXISTS ${ItemLinkIndex.sourceItemId.indexName} ON item_links(source_item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkIndex.targetItemId.indexName} ON item_links(target_item_id);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkIndex.relationType.indexName} ON item_links(relation_type);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkIndex.sourceRelationType.indexName} ON item_links(source_item_id, relation_type);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkIndex.targetRelationType.indexName} ON item_links(target_item_id, relation_type);',
  'CREATE INDEX IF NOT EXISTS ${ItemLinkIndex.sourceSortOrder.indexName} ON item_links(source_item_id, sort_order);',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS ${ItemLinkIndex.uniqueLink.indexName}
  ON item_links(
    source_item_id,
    target_item_id,
    relation_type,
    COALESCE(relation_type_other, '')
  );
  ''',
];

enum ItemLinkTrigger {
  otpForPasswordInsert('trg_item_links_otp_for_password_insert'),
  otpForPasswordUpdate('trg_item_links_otp_for_password_update'),

  supportContactInsert('trg_item_links_support_contact_insert'),
  supportContactUpdate('trg_item_links_support_contact_update'),

  purchaseDocumentInsert('trg_item_links_purchase_document_insert'),
  purchaseDocumentUpdate('trg_item_links_purchase_document_update'),

  identityScanInsert('trg_item_links_identity_scan_insert'),
  identityScanUpdate('trg_item_links_identity_scan_update'),

  identityPhotoInsert('trg_item_links_identity_photo_insert'),
  identityPhotoUpdate('trg_item_links_identity_photo_update'),

  sshPublicKeyFileInsert('trg_item_links_ssh_public_key_file_insert'),
  sshPublicKeyFileUpdate('trg_item_links_ssh_public_key_file_update'),

  sshPrivateKeyFileInsert('trg_item_links_ssh_private_key_file_insert'),
  sshPrivateKeyFileUpdate('trg_item_links_ssh_private_key_file_update'),

  certificateFileInsert('trg_item_links_certificate_file_insert'),
  certificateFileUpdate('trg_item_links_certificate_file_update'),

  certificatePrivateKeyFileInsert(
    'trg_item_links_certificate_private_key_file_insert',
  ),
  certificatePrivateKeyFileUpdate(
    'trg_item_links_certificate_private_key_file_update',
  ),

  noteInsert('trg_item_links_note_insert'),
  noteUpdate('trg_item_links_note_update'),

  attachmentInsert('trg_item_links_attachment_insert'),
  attachmentUpdate('trg_item_links_attachment_update');

  const ItemLinkTrigger(this.triggerName);

  final String triggerName;
}

final List<String> itemLinksTableTriggers = [
  // password -> otp
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.otpForPasswordInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'otpForPassword'
  BEGIN
    SELECT RAISE(
      ABORT,
      'otpForPassword link must be password -> otp'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'password'
        AND target.type = 'otp'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.otpForPasswordUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'otpForPassword'
  BEGIN
    SELECT RAISE(
      ABORT,
      'otpForPassword link must be password -> otp'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'password'
        AND target.type = 'otp'
    );
  END;
  ''',

  // any -> contact
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.supportContactInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'supportContact'
  BEGIN
    SELECT RAISE(
      ABORT,
      'supportContact target must be contact'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = 'contact'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.supportContactUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'supportContact'
  BEGIN
    SELECT RAISE(
      ABORT,
      'supportContact target must be contact'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = 'contact'
    );
  END;
  ''',

  // licenseKey -> file/document
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.purchaseDocumentInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'purchaseDocument'
  BEGIN
    SELECT RAISE(
      ABORT,
      'purchaseDocument link must be licenseKey -> file/document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'licenseKey'
        AND target.type IN ('file', 'document')
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.purchaseDocumentUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'purchaseDocument'
  BEGIN
    SELECT RAISE(
      ABORT,
      'purchaseDocument link must be licenseKey -> file/document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'licenseKey'
        AND target.type IN ('file', 'document')
    );
  END;
  ''',

  // identity -> document
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.identityScanInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'identityScan'
  BEGIN
    SELECT RAISE(
      ABORT,
      'identityScan link must be identity -> document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'identity'
        AND target.type = 'document'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.identityScanUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'identityScan'
  BEGIN
    SELECT RAISE(
      ABORT,
      'identityScan link must be identity -> document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'identity'
        AND target.type = 'document'
    );
  END;
  ''',

  // identity -> file
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.identityPhotoInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'identityPhoto'
  BEGIN
    SELECT RAISE(
      ABORT,
      'identityPhoto link must be identity -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'identity'
        AND target.type = 'file'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.identityPhotoUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'identityPhoto'
  BEGIN
    SELECT RAISE(
      ABORT,
      'identityPhoto link must be identity -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'identity'
        AND target.type = 'file'
    );
  END;
  ''',

  // sshKey -> file
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.sshPublicKeyFileInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'sshPublicKeyFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'sshPublicKeyFile link must be sshKey -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'sshKey'
        AND target.type = 'file'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.sshPublicKeyFileUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'sshPublicKeyFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'sshPublicKeyFile link must be sshKey -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'sshKey'
        AND target.type = 'file'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.sshPrivateKeyFileInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'sshPrivateKeyFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'sshPrivateKeyFile link must be sshKey -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'sshKey'
        AND target.type = 'file'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.sshPrivateKeyFileUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'sshPrivateKeyFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'sshPrivateKeyFile link must be sshKey -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'sshKey'
        AND target.type = 'file'
    );
  END;
  ''',

  // certificate -> file/document
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.certificateFileInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'certificateFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'certificateFile link must be certificate -> file/document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'certificate'
        AND target.type IN ('file', 'document')
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.certificateFileUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'certificateFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'certificateFile link must be certificate -> file/document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'certificate'
        AND target.type IN ('file', 'document')
    );
  END;
  ''',

  // certificate -> file
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.certificatePrivateKeyFileInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'certificatePrivateKeyFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'certificatePrivateKeyFile link must be certificate -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'certificate'
        AND target.type = 'file'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.certificatePrivateKeyFileUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'certificatePrivateKeyFile'
  BEGIN
    SELECT RAISE(
      ABORT,
      'certificatePrivateKeyFile link must be certificate -> file'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = 'certificate'
        AND target.type = 'file'
    );
  END;
  ''',

  // any -> note
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.noteInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'note'
  BEGIN
    SELECT RAISE(
      ABORT,
      'note link target must be note'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = 'note'
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.noteUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'note'
  BEGIN
    SELECT RAISE(
      ABORT,
      'note link target must be note'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = 'note'
    );
  END;
  ''',

  // any -> file/document
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.attachmentInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'attachment'
  BEGIN
    SELECT RAISE(
      ABORT,
      'attachment link target must be file/document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type IN ('file', 'document')
    );
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.attachmentUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id, relation_type ON item_links
  WHEN NEW.relation_type = 'attachment'
  BEGIN
    SELECT RAISE(
      ABORT,
      'attachment link target must be file/document'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type IN ('file', 'document')
    );
  END;
  ''',
];
