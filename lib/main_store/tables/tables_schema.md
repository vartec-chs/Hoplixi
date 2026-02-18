# Database Schema

This document describes the schema of all tables in the Hoplixi database.

The database uses a **normalized EAV-like architecture**: all vault entities
share a common base table (`vault_items`) and a common history table
(`vault_item_history`). Type-specific fields are stored in separate child tables
that reference the base table via `item_id → vault_items.id ON DELETE CASCADE`.

---

## Table: vault_items

Base table for all vault entities (passwords, notes, OTPs, bank cards, files,
documents). Contains only the common fields shared by every entity type.

| Column      | Type     | Constraints                             | Description            |
| ----------- | -------- | --------------------------------------- | ---------------------- |
| id          | Text     | Primary Key, UUID v4                    | Unique identifier      |
| type        | Text     | enum: VaultItemType                     | Entity type            |
| name        | Text     | min: 1, max: 255                        | Display name           |
| description | Text     | nullable                                | Description            |
| categoryId  | Text     | nullable, FK to categories.id (setNull) | Category reference     |
| noteId      | Text     | nullable                                | Linked note reference  |
| usedCount   | Int      | default: 0                              | Usage count            |
| isFavorite  | Bool     | default: false                          | Favorite flag          |
| isArchived  | Bool     | default: false                          | Archived flag          |
| isPinned    | Bool     | default: false                          | Pinned flag            |
| isDeleted   | Bool     | default: false                          | Soft delete flag       |
| createdAt   | DateTime | default: now                            | Creation timestamp     |
| modifiedAt  | DateTime | default: now                            | Modification timestamp |
| recentScore | Real     | nullable                                | EWMA for sorting       |
| lastUsedAt  | DateTime | nullable                                | Last used timestamp    |

**VaultItemType enum values:** `password`, `note`, `otp`, `bankCard`, `file`,
`document`

---

## Table: vault_item_history

Base history table. Stores a snapshot of `vault_items` common fields at the
moment of each action. Type-specific history tables reference this table via
`history_id → vault_item_history.id ON DELETE CASCADE`.

| Column             | Type     | Constraints           | Description                  |
| ------------------ | -------- | --------------------- | ---------------------------- |
| id                 | Text     | Primary Key, UUID v4  | Unique identifier            |
| itemId             | Text     | -                     | ID of original vault item    |
| type               | Text     | enum: VaultItemType   | Entity type snapshot         |
| name               | Text     | min: 1, max: 255      | Name snapshot                |
| description        | Text     | nullable              | Description snapshot         |
| categoryId         | Text     | nullable              | Category ID snapshot         |
| categoryName       | Text     | nullable              | Category name at action time |
| action             | Text     | enum: ActionInHistory | Action performed             |
| usedCount          | Int      | default: 0            | Usage count snapshot         |
| isFavorite         | Bool     | default: false        | Favorite flag snapshot       |
| isArchived         | Bool     | default: false        | Archived flag snapshot       |
| isPinned           | Bool     | default: false        | Pinned flag snapshot         |
| isDeleted          | Bool     | default: false        | Deleted flag snapshot        |
| recentScore        | Real     | nullable              | EWMA snapshot                |
| lastUsedAt         | DateTime | nullable              | Last used snapshot           |
| originalCreatedAt  | DateTime | nullable              | Original creation time       |
| originalModifiedAt | DateTime | nullable              | Original modification time   |
| actionAt           | DateTime | default: now          | Action timestamp             |

**ActionInHistory enum values:** `created`, `modified`, `deleted`

---

## Table: password_items

Type-specific table for passwords. Contains only password-specific fields.
Common fields (name, categoryId, isFavorite, etc.) are stored in `vault_items`.

| Column   | Type | Constraints                                 | Description        |
| -------- | ---- | ------------------------------------------- | ------------------ |
| itemId   | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref     |
| login    | Text | nullable                                    | Username           |
| email    | Text | nullable                                    | Email              |
| password | Text | -                                           | Encrypted password |
| url      | Text | nullable                                    | Associated URL     |

**Constraints:** CHECK (login IS NOT NULL OR email IS NOT NULL)

---

## Table: password_history

History table for password-specific fields. Each record is linked to
`vault_item_history` via `history_id → vault_item_history.id ON DELETE CASCADE`.

| Column    | Type | Constraints                                        | Description                               |
| --------- | ---- | -------------------------------------------------- | ----------------------------------------- |
| historyId | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref                        |
| login     | Text | nullable                                           | Login snapshot                            |
| email     | Text | nullable                                           | Email snapshot                            |
| password  | Text | nullable                                           | Encrypted password (nullable for privacy) |
| url       | Text | nullable                                           | URL snapshot                              |

---

## Table: note_items

Type-specific table for notes. The note title is stored in `vault_items.name`.

| Column    | Type | Constraints                                 | Description                     |
| --------- | ---- | ------------------------------------------- | ------------------------------- |
| itemId    | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref                  |
| deltaJson | Text | -                                           | Quill Delta JSON representation |
| content   | Text | -                                           | Plain text content              |

---

## Table: note_history

History table for note-specific fields.

| Column    | Type | Constraints                                        | Description               |
| --------- | ---- | -------------------------------------------------- | ------------------------- |
| historyId | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref        |
| deltaJson | Text | -                                                  | Quill Delta JSON snapshot |
| content   | Text | -                                                  | Content snapshot          |

---

## Table: otp_items

Type-specific table for OTP codes.

| Column         | Type | Constraints                                 | Description                     |
| -------------- | ---- | ------------------------------------------- | ------------------------------- |
| itemId         | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref                  |
| passwordItemId | Text | nullable, FK to vault_items.id (setNull)    | Linked password reference       |
| type           | Text | enum: OtpType, default: 'totp'              | Type: TOTP or HOTP              |
| issuer         | Text | nullable                                    | Service name                    |
| accountName    | Text | nullable                                    | Account identifier              |
| secret         | Blob | -                                           | Encrypted secret key            |
| secretEncoding | Text | enum: SecretEncoding, default: 'BASE32'     | Encoding of the secret          |
| algorithm      | Text | enum: AlgorithmOtp, default: 'SHA1'         | HMAC algorithm                  |
| digits         | Int  | default: 6                                  | Number of digits                |
| period         | Int  | default: 30                                 | Time period in seconds for TOTP |
| counter        | Int  | nullable                                    | Counter for HOTP                |

**Constraints:** CHECK ((type = 'hotp' AND counter IS NOT NULL) OR (type =
'totp' AND counter IS NULL))

---

## Table: otp_history

History table for OTP-specific fields.

| Column         | Type | Constraints                                        | Description              |
| -------------- | ---- | -------------------------------------------------- | ------------------------ |
| historyId      | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref       |
| passwordItemId | Text | nullable                                           | Linked password snapshot |
| type           | Text | enum: OtpType, default: 'totp'                     | Type snapshot            |
| issuer         | Text | nullable                                           | Issuer snapshot          |
| accountName    | Text | nullable                                           | Account name snapshot    |
| secret         | Blob | -                                                  | Secret snapshot          |
| secretEncoding | Text | enum: SecretEncoding, default: 'BASE32'            | Encoding snapshot        |
| algorithm      | Text | enum: AlgorithmOtp, default: 'SHA1'                | Algorithm snapshot       |
| digits         | Int  | default: 6                                         | Digits snapshot          |
| period         | Int  | default: 30                                        | Period snapshot          |
| counter        | Int  | nullable                                           | Counter snapshot         |

---

## Table: bank_card_items

Type-specific table for bank cards.

| Column         | Type | Constraints                                 | Description           |
| -------------- | ---- | ------------------------------------------- | --------------------- |
| itemId         | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref        |
| cardholderName | Text | min: 1, max: 255                            | Cardholder name       |
| cardNumber     | Text | -                                           | Encrypted card number |
| cardType       | Text | enum: CardType, nullable, default: debit    | Card type             |
| cardNetwork    | Text | enum: CardNetwork, nullable, default: other | Card network          |
| expiryMonth    | Text | min: 2, max: 2                              | Expiry month (MM)     |
| expiryYear     | Text | min: 4, max: 4                              | Expiry year (YYYY)    |
| cvv            | Text | nullable                                    | Encrypted CVV         |
| bankName       | Text | nullable                                    | Bank name             |
| accountNumber  | Text | nullable                                    | Account number        |
| routingNumber  | Text | nullable                                    | Routing number        |

---

## Table: bank_card_history

History table for bank card-specific fields.

| Column         | Type | Constraints                                        | Description                                  |
| -------------- | ---- | -------------------------------------------------- | -------------------------------------------- |
| historyId      | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref                           |
| cardholderName | Text | min: 1, max: 255                                   | Cardholder name snapshot                     |
| cardNumber     | Text | nullable                                           | Encrypted card number (nullable for privacy) |
| cardType       | Text | enum: CardType, nullable                           | Card type snapshot                           |
| cardNetwork    | Text | enum: CardNetwork, nullable                        | Card network snapshot                        |
| expiryMonth    | Text | nullable                                           | Expiry month snapshot                        |
| expiryYear     | Text | nullable                                           | Expiry year snapshot                         |
| cvv            | Text | nullable                                           | Encrypted CVV (nullable for privacy)         |
| bankName       | Text | nullable                                           | Bank name snapshot                           |
| accountNumber  | Text | nullable                                           | Account number snapshot                      |
| routingNumber  | Text | nullable                                           | Routing number snapshot                      |

---

## Table: file_items

Type-specific table for files.

| Column     | Type | Constraints                                 | Description             |
| ---------- | ---- | ------------------------------------------- | ----------------------- |
| itemId     | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref          |
| metadataId | Text | nullable, FK to file_metadata.id (setNull)  | File metadata reference |

---

## Table: file_history

History table for file-specific fields.

| Column     | Type | Constraints                                        | Description               |
| ---------- | ---- | -------------------------------------------------- | ------------------------- |
| historyId  | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref        |
| metadataId | Text | nullable                                           | File metadata ID snapshot |

---

## Table: document_items

Type-specific table for documents. The document title is stored in
`vault_items.name`.

| Column         | Type | Constraints                                 | Description                      |
| -------------- | ---- | ------------------------------------------- | -------------------------------- |
| itemId         | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref                   |
| documentType   | Text | min: 1, max: 64, nullable                   | Document type                    |
| aggregatedText | Text | nullable                                    | Aggregated OCR text of all pages |
| aggregateHash  | Text | nullable                                    | Hash of document version         |
| pageCount      | Int  | default: 0                                  | Number of pages                  |

---

## Table: document_history

History table for document-specific fields.

| Column         | Type | Constraints                                        | Description                  |
| -------------- | ---- | -------------------------------------------------- | ---------------------------- |
| historyId      | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref           |
| documentType   | Text | nullable                                           | Document type snapshot       |
| aggregatedText | Text | nullable                                           | Aggregated OCR text snapshot |
| aggregateHash  | Text | nullable                                           | Hash snapshot                |
| pageCount      | Int  | default: 0                                         | Page count snapshot          |

---

## Table: item_tags

Unified join table linking vault items to tags. Replaces the previous separate
tables (`password_tags`, `note_tags`, `otp_tags`, `bank_cards_tags`,
`files_tags`, `documents_tags`).

| Column    | Type     | Constraints                    | Description        |
| --------- | -------- | ------------------------------ | ------------------ |
| itemId    | Text     | FK to vault_items.id (cascade) | Vault item ref     |
| tagId     | Text     | FK to tags.id (cascade)        | Tag reference      |
| createdAt | DateTime | default: now                   | Creation timestamp |

**Primary Key:** {itemId, tagId}

---

## Table: categories

| Column      | Type     | Constraints                        | Description                                  |
| ----------- | -------- | ---------------------------------- | -------------------------------------------- |
| id          | Text     | Primary Key, UUID v4               | Unique identifier                            |
| name        | Text     | unique, min: 1, max: 100           | Category name                                |
| description | Text     | nullable                           | Description                                  |
| iconId      | Text     | nullable, FK to icons.id (setNull) | Icon reference                               |
| color       | Text     | default: 'FFFFFF'                  | Hex color code                               |
| type        | Text     | enum: CategoryType                 | Category type (notes, password, totp, mixed) |
| createdAt   | DateTime | default: now                       | Creation timestamp                           |
| modifiedAt  | DateTime | default: now                       | Modification timestamp                       |

---

## Table: tags

| Column     | Type     | Constraints          | Description                             |
| ---------- | -------- | -------------------- | --------------------------------------- |
| id         | Text     | Primary Key, UUID v4 | Unique identifier                       |
| name       | Text     | unique               | Tag name                                |
| color      | Text     | default: 'FFFFFF'    | Hex color code                          |
| type       | Text     | enum: TagType        | Tag type (notes, password, totp, mixed) |
| createdAt  | DateTime | default: now         | Creation timestamp                      |
| modifiedAt | DateTime | default: now         | Modification timestamp                  |

---

## Table: icons

| Column     | Type     | Constraints          | Description                     |
| ---------- | -------- | -------------------- | ------------------------------- |
| id         | Text     | Primary Key, UUID v4 | Unique identifier               |
| name       | Text     | min: 1, max: 255     | Icon name                       |
| type       | Text     | enum: IconType       | MIME type (png, jpg, svg, etc.) |
| data       | Blob     | -                    | Binary image data               |
| createdAt  | DateTime | default: now         | Creation timestamp              |
| modifiedAt | DateTime | default: now         | Modification timestamp          |

---

## Table: file_metadata

| Column        | Type | Constraints          | Description                        |
| ------------- | ---- | -------------------- | ---------------------------------- |
| id            | Text | Primary Key, UUID v4 | Unique identifier                  |
| fileName      | Text | -                    | Original file name                 |
| fileExtension | Text | -                    | File extension                     |
| filePath      | Text | nullable             | Relative path from files directory |
| mimeType      | Text | -                    | MIME type                          |
| fileSize      | Int  | -                    | File size in bytes                 |
| fileHash      | Text | nullable             | SHA256 hash for integrity          |

---

## Table: document_pages

Pages of a document (one-to-many: document → pages). `documentId` references
`vault_items.id` (the document vault item).

| Column        | Type     | Constraints                                | Description             |
| ------------- | -------- | ------------------------------------------ | ----------------------- |
| id            | Text     | Primary Key, UUID v4                       | Unique identifier       |
| documentId    | Text     | FK to vault_items.id (cascade)             | Document owner          |
| metadataId    | Text     | nullable, FK to file_metadata.id (setNull) | File metadata reference |
| pageNumber    | Int      | -                                          | Page number (1..N)      |
| extractedText | Text     | nullable                                   | OCR text of the page    |
| pageHash      | Text     | nullable                                   | Hash of the page        |
| isPrimary     | Bool     | default: false                             | Primary page (cover)    |
| usedCount     | Int      | default: 0                                 | Usage count             |
| createdAt     | DateTime | default: now                               | Creation timestamp      |
| modifiedAt    | DateTime | default: now                               | Modification timestamp  |
| lastUsedAt    | DateTime | nullable                                   | Last used timestamp     |

**Constraints:** UNIQUE {documentId, pageNumber}

---

## Table: note_links

Many-to-many links between notes. Both `sourceNoteId` and `targetNoteId`
reference `vault_items.id`.

| Column       | Type     | Constraints                    | Description           |
| ------------ | -------- | ------------------------------ | --------------------- |
| id           | Text     | Primary Key, UUID v4           | Unique identifier     |
| sourceNoteId | Text     | FK to vault_items.id (cascade) | Source note reference |
| targetNoteId | Text     | FK to vault_items.id (cascade) | Target note reference |
| createdAt    | DateTime | default: now                   | Creation timestamp    |

**Unique Keys:** {sourceNoteId, targetNoteId}

---

## Table: store_meta

| Column        | Type     | Constraints          | Description            |
| ------------- | -------- | -------------------- | ---------------------- |
| id            | Text     | Primary Key, UUID v4 | Unique identifier      |
| name          | Text     | min: 4               | Store name             |
| description   | Text     | nullable             | Description            |
| passwordHash  | Text     | -                    | Password hash          |
| salt          | Text     | -                    | Salt                   |
| attachmentKey | Text     | -                    | Attachment key         |
| createdAt     | DateTime | default: now         | Creation timestamp     |
| modifiedAt    | DateTime | default: now         | Modification timestamp |
| lastOpenedAt  | DateTime | default: now         | Last opened timestamp  |
| version       | Text     | default: '1.0.0'     | Version                |

---

## Architecture Notes

### Entity Hierarchy

```text
vault_items (base)
├── password_items   (itemId → vault_items.id CASCADE)
├── note_items       (itemId → vault_items.id CASCADE)
├── otp_items        (itemId → vault_items.id CASCADE)
├── bank_card_items  (itemId → vault_items.id CASCADE)
├── file_items       (itemId → vault_items.id CASCADE)
└── document_items   (itemId → vault_items.id CASCADE)

vault_item_history (base history)
├── password_history  (historyId → vault_item_history.id CASCADE)
├── note_history      (historyId → vault_item_history.id CASCADE)
├── otp_history       (historyId → vault_item_history.id CASCADE)
├── bank_card_history (historyId → vault_item_history.id CASCADE)
├── file_history      (historyId → vault_item_history.id CASCADE)
└── document_history  (historyId → vault_item_history.id CASCADE)

item_tags (unified tags join)
└── itemId → vault_items.id CASCADE
└── tagId  → tags.id CASCADE
```

### Triggers

History triggers fire on `vault_items` UPDATE/DELETE and insert into
`vault_item_history` + the corresponding type-specific history table.

Timestamp triggers maintain `created_at` / `modified_at` on `vault_items`,
`document_pages`, `categories`, `tags`, `icons`, and `store_meta`.

`store_meta.modified_at` is touched by meta-touch triggers on every INSERT /
UPDATE / DELETE in `vault_items` and `item_tags`.
