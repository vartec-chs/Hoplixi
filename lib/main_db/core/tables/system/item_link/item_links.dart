import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../vault_items/vault_items.dart';

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
    CONSTRAINT ${ItemLinkConstraint.idNotBlank.constraintName}
    CHECK (length(trim(id)) > 0)
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.sourceItemIdNotBlank.constraintName}
    CHECK (length(trim(source_item_id)) > 0)
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.targetItemIdNotBlank.constraintName}
    CHECK (length(trim(target_item_id)) > 0)
    ''',
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
    CONSTRAINT ${ItemLinkConstraint.relationTypeOtherNoOuterWhitespace.constraintName}
    CHECK (
      relation_type_other IS NULL 
      OR relation_type_other = trim(relation_type_other)
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
    CONSTRAINT ${ItemLinkConstraint.labelNoOuterWhitespace.constraintName}
    CHECK (
      label IS NULL 
      OR label = trim(label)
    )
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.sortOrderNonNegative.constraintName}
    CHECK (
      sort_order >= 0
    )
    ''',
    '''
    CONSTRAINT ${ItemLinkConstraint.modifiedAtAfterCreatedAt.constraintName}
    CHECK (
      modified_at >= created_at
    )
    ''',
  ];
}

enum ItemLinkConstraint {
  idNotBlank('chk_item_links_id_not_blank'),

  sourceItemIdNotBlank('chk_item_links_source_item_id_not_blank'),

  targetItemIdNotBlank('chk_item_links_target_item_id_not_blank'),

  noSelfLink('chk_item_links_no_self_link'),

  relationTypeOtherRequired('chk_item_links_relation_type_other_required'),

  relationTypeOtherMustBeNull(
    'chk_item_links_relation_type_other_must_be_null',
  ),

  relationTypeOtherNoOuterWhitespace(
    'chk_item_links_relation_type_other_no_outer_whitespace',
  ),

  labelNotBlank('chk_item_links_label_not_blank'),

  labelNoOuterWhitespace('chk_item_links_label_no_outer_whitespace'),

  sortOrderNonNegative('chk_item_links_sort_order_non_negative'),

  modifiedAtAfterCreatedAt('chk_item_links_modified_at_after_created_at');

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
  preventCreatedAtUpdate('trg_item_links_prevent_created_at_update'),
  preventSourceTargetUpdate('trg_item_links_prevent_source_target_update'),

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

enum ItemLinkRaise {
  preventCreatedAtUpdate('created_at is immutable'),
  preventSourceTargetUpdate('source_item_id and target_item_id are immutable'),

  otpForPassword('otpForPassword link must be password -> otp'),
  supportContact('supportContact target must be contact'),
  purchaseDocument('purchaseDocument link must be licenseKey -> file/document'),
  identityScan('identityScan link must be identity -> document'),
  identityPhoto('identityPhoto link must be identity -> file'),
  sshPublicKeyFile('sshPublicKeyFile link must be sshKey -> file'),
  sshPrivateKeyFile('sshPrivateKeyFile link must be sshKey -> file'),
  certificateFile('certificateFile link must be certificate -> file/document'),
  certificatePrivateKeyFile('certificatePrivateKeyFile link must be certificate -> file'),
  note('note link target must be note'),
  attachment('attachment link target must be file/document');

  const ItemLinkRaise(this.message);

  final String message;
}

final List<String> itemLinksTableTriggers = [
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.preventCreatedAtUpdate.triggerName}
  BEFORE UPDATE OF created_at ON item_links
  BEGIN
    SELECT RAISE(ABORT, '${ItemLinkRaise.preventCreatedAtUpdate.message}');
  END;
  ''',
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.preventSourceTargetUpdate.triggerName}
  BEFORE UPDATE OF source_item_id, target_item_id ON item_links
  BEGIN
    SELECT RAISE(ABORT, '${ItemLinkRaise.preventSourceTargetUpdate.message}');
  END;
  ''',

  // password -> otp
  '''
  CREATE TRIGGER IF NOT EXISTS ${ItemLinkTrigger.otpForPasswordInsert.triggerName}
  BEFORE INSERT ON item_links
  WHEN NEW.relation_type = 'otpForPassword'
  BEGIN
    SELECT RAISE(
      ABORT,
      '${ItemLinkRaise.otpForPassword.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.password.name}'
        AND target.type = '${VaultItemType.otp.name}'
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
      '${ItemLinkRaise.otpForPassword.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.password.name}'
        AND target.type = '${VaultItemType.otp.name}'
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
      '${ItemLinkRaise.supportContact.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = '${VaultItemType.contact.name}'
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
      '${ItemLinkRaise.supportContact.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = '${VaultItemType.contact.name}'
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
      '${ItemLinkRaise.purchaseDocument.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.licenseKey.name}'
        AND target.type IN ('${VaultItemType.file.name}', '${VaultItemType.document.name}')
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
      '${ItemLinkRaise.purchaseDocument.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.licenseKey.name}'
        AND target.type IN ('${VaultItemType.file.name}', '${VaultItemType.document.name}')
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
      '${ItemLinkRaise.identityScan.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.identity.name}'
        AND target.type = '${VaultItemType.document.name}'
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
      '${ItemLinkRaise.identityScan.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.identity.name}'
        AND target.type = '${VaultItemType.document.name}'
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
      '${ItemLinkRaise.identityPhoto.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.identity.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.identityPhoto.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.identity.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.sshPublicKeyFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.sshKey.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.sshPublicKeyFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.sshKey.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.sshPrivateKeyFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.sshKey.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.sshPrivateKeyFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.sshKey.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.certificateFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.certificate.name}'
        AND target.type IN ('${VaultItemType.file.name}', '${VaultItemType.document.name}')
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
      '${ItemLinkRaise.certificateFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.certificate.name}'
        AND target.type IN ('${VaultItemType.file.name}', '${VaultItemType.document.name}')
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
      '${ItemLinkRaise.certificatePrivateKeyFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.certificate.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.certificatePrivateKeyFile.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items source
      JOIN vault_items target
        ON target.id = NEW.target_item_id
      WHERE source.id = NEW.source_item_id
        AND source.type = '${VaultItemType.certificate.name}'
        AND target.type = '${VaultItemType.file.name}'
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
      '${ItemLinkRaise.note.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = '${VaultItemType.note.name}'
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
      '${ItemLinkRaise.note.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type = '${VaultItemType.note.name}'
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
      '${ItemLinkRaise.attachment.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type IN ('${VaultItemType.file.name}', '${VaultItemType.document.name}')
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
      '${ItemLinkRaise.attachment.message}'
    )
    WHERE NOT EXISTS (
      SELECT 1
      FROM vault_items target
      WHERE target.id = NEW.target_item_id
        AND target.type IN ('${VaultItemType.file.name}', '${VaultItemType.document.name}')
    );
  END;
  ''',
];
