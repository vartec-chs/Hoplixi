# Database Schema

This document describes the schema of all tables in the Hoplixi database.

## Table: passwords

| Column      | Type     | Constraints                             | Description            |
| ----------- | -------- | --------------------------------------- | ---------------------- |
| id          | Text     | Primary Key, UUID v4                    | Unique identifier      |
| name        | Text     | min: 1, max: 255                        | Password name          |
| description | Text     | nullable                                | Description            |
| password    | Text     | -                                       | Encrypted password     |
| url         | Text     | nullable                                | Associated URL         |
| notes       | Text     | nullable                                | Additional notes       |
| login       | Text     | nullable                                | Username               |
| email       | Text     | nullable                                | Email                  |
| categoryId  | Text     | nullable, FK to categories.id (setNull) | Category reference     |
| usedCount   | Int      | default: 0                              | Usage count            |
| isDeleted   | Bool     | default: false                          | Soft delete flag       |
| isArchived  | Bool     | default: false                          | Archived flag          |
| isPinned    | Bool     | default: false                          | Pinned flag            |
| isFavorite  | Bool     | default: false                          | Favorite flag          |
| createdAt   | DateTime | default: now                            | Creation timestamp     |
| modifiedAt  | DateTime | default: now                            | Modification timestamp |
| recentScore | Real     | nullable                                | EWMA for sorting       |
| lastUsedAt  | DateTime | nullable                                | Last used timestamp    |

**Constraints:** CHECK (login IS NOT NULL OR email IS NOT NULL)

## Table: passwords_history

| Column             | Type     | Constraints           | Description                               |
| ------------------ | -------- | --------------------- | ----------------------------------------- |
| id                 | Text     | Primary Key, UUID v4  | Unique identifier                         |
| originalPasswordId | Text     | -                     | ID of original password                   |
| action             | Text     | enum: ActionInHistory | Action performed (deleted, modified)      |
| name               | Text     | min: 1, max: 255      | Name snapshot                             |
| description        | Text     | nullable              | Description snapshot                      |
| password           | Text     | nullable              | Encrypted password (nullable for privacy) |
| url                | Text     | nullable              | URL snapshot                              |
| notes              | Text     | nullable              | Notes snapshot                            |
| login              | Text     | nullable              | Login snapshot                            |
| email              | Text     | nullable              | Email snapshot                            |
| categoryId         | Text     | nullable              | Category ID snapshot                      |
| categoryName       | Text     | nullable              | Category name at action time              |
| tags               | Text     | nullable              | JSON array of tag names                   |
| usedCount          | Int      | default: 0            | Usage count snapshot                      |
| isArchived         | Bool     | default: false        | Archived flag snapshot                    |
| isPinned           | Bool     | default: false        | Pinned flag snapshot                      |
| isFavorite         | Bool     | default: false        | Favorite flag snapshot                    |
| recentScore        | Real     | nullable              | EWMA snapshot                             |
| lastUsedAt         | DateTime | nullable              | Last used snapshot                        |
| isDeleted          | Bool     | default: false        | Deleted flag snapshot                     |
| originalCreatedAt  | DateTime | nullable              | Original creation time                    |
| originalModifiedAt | DateTime | nullable              | Original modification time                |
| originalLastUsedAt | DateTime | nullable              | Original last used time                   |
| actionAt           | DateTime | default: now          | Action timestamp                          |

## Table: passwords_tags

| Column     | Type     | Constraints                  | Description        |
| ---------- | -------- | ---------------------------- | ------------------ |
| passwordId | Text     | FK to passwords.id (cascade) | Password reference |
| tagId      | Text     | FK to tags.id (cascade)      | Tag reference      |
| createdAt  | DateTime | default: now                 | Creation timestamp |

**Primary Key:** {passwordId, tagId}

## Table: bank_cards

| Column         | Type     | Constraints                             | Description            |
| -------------- | -------- | --------------------------------------- | ---------------------- |
| id             | Text     | Primary Key, UUID v4                    | Unique identifier      |
| name           | Text     | min: 1, max: 255                        | Card name              |
| cardholderName | Text     | min: 1, max: 255                        | Cardholder name        |
| cardNumber     | Text     | -                                       | Encrypted card number  |
| cardType       | Text     | enum: CardType, default: debit          | Card type              |
| cardNetwork    | Text     | enum: CardNetwork, default: other       | Card network           |
| expiryMonth    | Text     | min: 2, max: 2                          | Expiry month (MM)      |
| expiryYear     | Text     | min: 4, max: 4                          | Expiry year (YYYY)     |
| cvv            | Text     | nullable                                | Encrypted CVV          |
| bankName       | Text     | nullable                                | Bank name              |
| accountNumber  | Text     | nullable                                | Account number         |
| routingNumber  | Text     | nullable                                | Routing number         |
| description    | Text     | nullable                                | Description            |
| notes          | Text     | nullable                                | Notes                  |
| categoryId     | Text     | nullable, FK to categories.id (setNull) | Category reference     |
| usedCount      | Int      | default: 0                              | Usage count            |
| isFavorite     | Bool     | default: false                          | Favorite flag          |
| isArchived     | Bool     | default: false                          | Archived flag          |
| isPinned       | Bool     | default: false                          | Pinned flag            |
| isDeleted      | Bool     | default: false                          | Soft delete flag       |
| createdAt      | DateTime | default: now                            | Creation timestamp     |
| modifiedAt     | DateTime | default: now                            | Modification timestamp |
| recentScore    | Real     | nullable                                | EWMA for sorting       |
| lastUsedAt     | DateTime | nullable                                | Last used timestamp    |

## Table: bank_cards_history

| Column             | Type     | Constraints                 | Description                                  |
| ------------------ | -------- | --------------------------- | -------------------------------------------- |
| id                 | Text     | Primary Key, UUID v4        | Unique identifier                            |
| originalCardId     | Text     | -                           | ID of original card                          |
| action             | Text     | enum: ActionInHistory       | Action performed                             |
| name               | Text     | min: 1, max: 255            | Name snapshot                                |
| cardholderName     | Text     | min: 1, max: 255            | Cardholder name snapshot                     |
| cardNumber         | Text     | nullable                    | Encrypted card number (nullable for privacy) |
| cardType           | Text     | enum: CardType, nullable    | Card type snapshot                           |
| cardNetwork        | Text     | enum: CardNetwork, nullable | Card network snapshot                        |
| expiryMonth        | Text     | nullable                    | Expiry month snapshot                        |
| expiryYear         | Text     | nullable                    | Expiry year snapshot                         |
| cvv                | Text     | nullable                    | Encrypted CVV (nullable for privacy)         |
| bankName           | Text     | nullable                    | Bank name snapshot                           |
| accountNumber      | Text     | nullable                    | Account number snapshot                      |
| routingNumber      | Text     | nullable                    | Routing number snapshot                      |
| description        | Text     | nullable                    | Description snapshot                         |
| notes              | Text     | nullable                    | Notes snapshot                               |
| categoryId         | Text     | nullable                    | Category ID snapshot                         |
| categoryName       | Text     | nullable                    | Category name at action time                 |
| usedCount          | Int      | default: 0                  | Usage count snapshot                         |
| isFavorite         | Bool     | default: false              | Favorite flag snapshot                       |
| isArchived         | Bool     | default: false              | Archived flag snapshot                       |
| isPinned           | Bool     | default: false              | Pinned flag snapshot                         |
| recentScore        | Real     | nullable                    | EWMA snapshot                                |
| lastUsedAt         | DateTime | nullable                    | Last used snapshot                           |
| isDeleted          | Bool     | default: false              | Deleted flag snapshot                        |
| originalCreatedAt  | DateTime | nullable                    | Original creation time                       |
| originalModifiedAt | DateTime | nullable                    | Original modification time                   |
| originalLastUsedAt | DateTime | nullable                    | Original last used time                      |
| actionAt           | DateTime | default: now                | Action timestamp                             |

## Table: bank_cards_tags

| Column    | Type     | Constraints                   | Description        |
| --------- | -------- | ----------------------------- | ------------------ |
| cardId    | Text     | FK to bank_cards.id (cascade) | Card reference     |
| tagId     | Text     | FK to tags.id (cascade)       | Tag reference      |
| createdAt | DateTime | default: now                  | Creation timestamp |

**Primary Key:** {cardId, tagId}

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

## Table: files

| Column        | Type     | Constraints                             | Description                        |
| ------------- | -------- | --------------------------------------- | ---------------------------------- |
| id            | Text     | Primary Key, UUID v4                    | Unique identifier                  |
| name          | Text     | min: 1, max: 255                        | File name                          |
| description   | Text     | nullable                                | Description                        |
| fileName      | Text     | -                                       | Original file name                 |
| fileExtension | Text     | -                                       | File extension                     |
| filePath      | Text     | nullable                                | Relative path from files directory |
| mimeType      | Text     | -                                       | MIME type                          |
| fileSize      | Int      | -                                       | File size in bytes                 |
| fileHash      | Text     | nullable                                | SHA256 hash for integrity          |
| categoryId    | Text     | nullable, FK to categories.id (setNull) | Category reference                 |
| usedCount     | Int      | default: 0                              | Usage count                        |
| isFavorite    | Bool     | default: false                          | Favorite flag                      |
| isArchived    | Bool     | default: false                          | Archived flag                      |
| isPinned      | Bool     | default: false                          | Pinned flag                        |
| isDeleted     | Bool     | default: false                          | Soft delete flag                   |
| createdAt     | DateTime | default: now                            | Creation timestamp                 |
| modifiedAt    | DateTime | default: now                            | Modification timestamp             |
| recentScore   | Real     | nullable                                | EWMA for sorting                   |
| lastUsedAt    | DateTime | nullable                                | Last used timestamp                |

## Table: files_history

| Column             | Type     | Constraints           | Description                  |
| ------------------ | -------- | --------------------- | ---------------------------- |
| id                 | Text     | Primary Key, UUID v4  | Unique identifier            |
| originalFileId     | Text     | -                     | ID of original file          |
| action             | Text     | enum: ActionInHistory | Action performed             |
| name               | Text     | min: 1, max: 255      | Name snapshot                |
| description        | Text     | nullable              | Description snapshot         |
| fileName           | Text     | -                     | Original file name snapshot  |
| fileExtension      | Text     | -                     | File extension snapshot      |
| filePath           | Text     | -                     | Relative path snapshot       |
| mimeType           | Text     | -                     | MIME type snapshot           |
| fileSize           | Int      | -                     | File size snapshot           |
| fileHash           | Text     | nullable              | SHA256 hash snapshot         |
| categoryId         | Text     | nullable              | Category ID snapshot         |
| categoryName       | Text     | nullable              | Category name at action time |
| usedCount          | Int      | default: 0            | Usage count snapshot         |
| isFavorite         | Bool     | default: false        | Favorite flag snapshot       |
| isArchived         | Bool     | default: false        | Archived flag snapshot       |
| isPinned           | Bool     | default: false        | Pinned flag snapshot         |
| recentScore        | Real     | nullable              | EWMA snapshot                |
| lastUsedAt         | DateTime | nullable              | Last used snapshot           |
| isDeleted          | Bool     | default: false        | Deleted flag snapshot        |
| originalCreatedAt  | DateTime | nullable              | Original creation time       |
| originalModifiedAt | DateTime | nullable              | Original modification time   |
| originalLastUsedAt | DateTime | nullable              | Original last used time      |
| actionAt           | DateTime | default: now          | Action timestamp             |

## Table: files_tags

| Column    | Type     | Constraints              | Description        |
| --------- | -------- | ------------------------ | ------------------ |
| fileId    | Text     | FK to files.id (cascade) | File reference     |
| tagId     | Text     | FK to tags.id (cascade)  | Tag reference      |
| createdAt | DateTime | default: now             | Creation timestamp |

**Primary Key:** {fileId, tagId}

## Table: icons

| Column     | Type     | Constraints          | Description                     |
| ---------- | -------- | -------------------- | ------------------------------- |
| id         | Text     | Primary Key, UUID v4 | Unique identifier               |
| name       | Text     | min: 1, max: 255     | Icon name                       |
| type       | Text     | enum: IconType       | MIME type (png, jpg, svg, etc.) |
| data       | Blob     | -                    | Binary image data               |
| createdAt  | DateTime | default: now         | Creation timestamp              |
| modifiedAt | DateTime | default: now         | Modification timestamp          |

## Table: note_links

| Column       | Type     | Constraints              | Description           |
| ------------ | -------- | ------------------------ | --------------------- |
| id           | Text     | Primary Key, UUID v4     | Unique identifier     |
| sourceNoteId | Text     | FK to notes.id (cascade) | Source note reference |
| targetNoteId | Text     | FK to notes.id (cascade) | Target note reference |
| createdAt    | DateTime | default: now             | Creation timestamp    |

**Unique Keys:** {sourceNoteId, targetNoteId}

## Table: notes

| Column      | Type     | Constraints                             | Description                     |
| ----------- | -------- | --------------------------------------- | ------------------------------- |
| id          | Text     | Primary Key, UUID v4                    | Unique identifier               |
| title       | Text     | min: 1, max: 255                        | Note title                      |
| description | Text     | nullable                                | Description                     |
| deltaJson   | Text     | -                                       | Quill Delta JSON representation |
| content     | Text     | -                                       | Main content                    |
| categoryId  | Text     | nullable, FK to categories.id (setNull) | Category reference              |
| usedCount   | Int      | default: 0                              | Usage count                     |
| isFavorite  | Bool     | default: false                          | Favorite flag                   |
| isDeleted   | Bool     | default: false                          | Soft delete flag                |
| isArchived  | Bool     | default: false                          | Archived flag                   |
| isPinned    | Bool     | default: false                          | Pinned flag                     |
| createdAt   | DateTime | default: now                            | Creation timestamp              |
| modifiedAt  | DateTime | default: now                            | Modification timestamp          |
| recentScore | Real     | nullable                                | EWMA for sorting                |
| lastUsedAt  | DateTime | nullable                                | Last used timestamp             |

## Table: notes_history

| Column                 | Type     | Constraints           | Description                  |
| ---------------------- | -------- | --------------------- | ---------------------------- |
| id                     | Text     | Primary Key, UUID v4  | Unique identifier            |
| originalNoteId         | Text     | -                     | ID of original note          |
| action                 | Text     | enum: ActionInHistory | Action performed             |
| title                  | Text     | min: 1, max: 255      | Title snapshot               |
| description            | Text     | nullable              | Description snapshot         |
| deltaJson              | Text     | -                     | Quill Delta JSON snapshot    |
| content                | Text     | -                     | Content snapshot             |
| categoryId             | Text     | nullable              | Category ID snapshot         |
| categoryName           | Text     | nullable              | Category name at action time |
| usedCount              | Int      | default: 0            | Usage count snapshot         |
| isFavorite             | Bool     | default: false        | Favorite flag snapshot       |
| isDeleted              | Bool     | default: false        | Deleted flag snapshot        |
| isArchived             | Bool     | default: false        | Archived flag snapshot       |
| isPinned               | Bool     | default: false        | Pinned flag snapshot         |
| recentScore            | Real     | nullable              | EWMA snapshot                |
| lastUsedAt             | DateTime | nullable              | Last used snapshot           |
| originalCreatedAt      | DateTime | nullable              | Original creation time       |
| originalModifiedAt     | DateTime | nullable              | Original modification time   |
| originalLastAccessedAt | DateTime | nullable              | Original last access time    |
| actionAt               | DateTime | default: now          | Action timestamp             |

## Table: notes_tags

| Column    | Type     | Constraints              | Description        |
| --------- | -------- | ------------------------ | ------------------ |
| noteId    | Text     | FK to notes.id (cascade) | Note reference     |
| tagId     | Text     | FK to tags.id (cascade)  | Tag reference      |
| createdAt | DateTime | default: now             | Creation timestamp |

**Primary Key:** {noteId, tagId}

## Table: otps

| Column         | Type     | Constraints                             | Description                     |
| -------------- | -------- | --------------------------------------- | ------------------------------- |
| id             | Text     | Primary Key, UUID v4                    | Unique identifier               |
| passwordId     | Text     | nullable, FK to passwords.id (setNull)  | Password reference              |
| categoryId     | Text     | nullable, FK to categories.id (setNull) | Category reference              |
| type           | Text     | enum: OtpType, default: 'totp'          | Type: TOTP or HOTP              |
| issuer         | Text     | nullable                                | Service name                    |
| accountName    | Text     | nullable                                | Account identifier              |
| secret         | Blob     | -                                       | Secret key                      |
| secretEncoding | Text     | enum: SecretEncoding, default: 'BASE32' | Encoding of the secret          |
| notes          | Text     | nullable                                | Notes                           |
| algorithm      | Text     | enum: AlgorithmOtp, default: 'SHA1'     | HMAC algorithm                  |
| digits         | Int      | default: 6                              | Number of digits                |
| period         | Int      | default: 30                             | Time period in seconds for TOTP |
| counter        | Int      | nullable                                | Counter for HOTP                |
| usedCount      | Int      | default: 0                              | Usage count                     |
| isDeleted      | Bool     | default: false                          | Soft delete flag                |
| isFavorite     | Bool     | default: false                          | Favorite flag                   |
| isPinned       | Bool     | default: false                          | Pinned flag                     |
| isArchived     | Bool     | default: false                          | Archived flag                   |
| createdAt      | DateTime | default: now                            | Creation timestamp              |
| modifiedAt     | DateTime | default: now                            | Modification timestamp          |
| recentScore    | Real     | nullable                                | EWMA for sorting                |
| lastUsedAt     | DateTime | nullable                                | Last used timestamp             |

**Constraints:** CHECK ((type = 'hotp' AND counter IS NOT NULL) OR (type =
'totp' AND counter IS NULL))

## Table: otps_history

| Column             | Type     | Constraints                             | Description                  |
| ------------------ | -------- | --------------------------------------- | ---------------------------- |
| id                 | Text     | Primary Key, UUID v4                    | Unique identifier            |
| originalOtpId      | Text     | -                                       | ID of original OTP           |
| action             | Text     | enum: ActionInHistory                   | Action performed             |
| type               | Text     | enum: OtpType, default: 'totp'          | Type snapshot                |
| issuer             | Text     | nullable                                | Issuer snapshot              |
| accountName        | Text     | nullable                                | Account name snapshot        |
| secret             | Blob     | -                                       | Secret snapshot              |
| secretEncoding     | Text     | enum: SecretEncoding, default: 'BASE32' | Encoding snapshot            |
| notes              | Text     | nullable                                | Notes snapshot               |
| algorithm          | Text     | enum: AlgorithmOtp, default: 'SHA1'     | Algorithm snapshot           |
| digits             | Int      | default: 6                              | Digits snapshot              |
| period             | Int      | default: 30                             | Period snapshot              |
| counter            | Int      | nullable                                | Counter snapshot             |
| passwordId         | Text     | nullable                                | Password ID snapshot         |
| categoryId         | Text     | nullable                                | Category ID snapshot         |
| categoryName       | Text     | nullable                                | Category name at action time |
| usedCount          | Int      | default: 0                              | Usage count snapshot         |
| isFavorite         | Bool     | default: false                          | Favorite flag snapshot       |
| isPinned           | Bool     | default: false                          | Pinned flag snapshot         |
| recentScore        | Real     | nullable                                | EWMA snapshot                |
| lastUsedAt         | DateTime | nullable                                | Last used snapshot           |
| originalCreatedAt  | DateTime | nullable                                | Original creation time       |
| originalModifiedAt | DateTime | nullable                                | Original modification time   |
| originalLastUsedAt | DateTime | nullable                                | Original last used time      |
| actionAt           | DateTime | default: now                            | Action timestamp             |

## Table: otp_tags

| Column    | Type     | Constraints             | Description        |
| --------- | -------- | ----------------------- | ------------------ |
| otpId     | Text     | FK to otps.id (cascade) | OTP reference      |
| tagId     | Text     | FK to tags.id (cascade) | Tag reference      |
| createdAt | DateTime | default: now            | Creation timestamp |

**Primary Key:** {otpId, tagId}

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

## Table: tags

| Column     | Type     | Constraints          | Description                             |
| ---------- | -------- | -------------------- | --------------------------------------- |
| id         | Text     | Primary Key, UUID v4 | Unique identifier                       |
| name       | Text     | unique               | Tag name                                |
| color      | Text     | default: 'FFFFFF'    | Hex color code                          |
| type       | Text     | enum: TagType        | Tag type (notes, password, totp, mixed) |
| createdAt  | DateTime | default: now         | Creation timestamp                      |
| modifiedAt | DateTime | default: now         | Modification timestamp                  |
