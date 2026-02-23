# Database Schema

This document describes the schema of all tables in the Hoplixi database.

The database uses a **normalized EAV-like architecture**: all vault entities
share a common base table (`vault_items`) and a common history table
(`vault_item_history`). Type-specific fields are stored in separate child tables
that reference the base table via `item_id → vault_items.id ON DELETE CASCADE`.

## Important

When changing tables, check and update triggers in `main_store.dart` to ensure
history tracking and timestamp maintenance. Triggers folder
./lib/main_store/triggers.

## Table: vault_items

Base table for all vault entities (passwords, notes, OTPs, bank cards, files,
documents, API keys, SSH keys, certificates, crypto wallets, Wi‑Fi, identities,
license keys, recovery codes). Contains only the common fields shared by every
entity type.

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

**VaultItemType enum values:** `password`, `otp`, `note`, `bankCard`,
`document`, `file`, `apiKey`, `sshKey`, `certificate`, `cryptoWallet`, `wifi`,
`identity`, `licenseKey`, `recoveryCodes`

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

| Column   | Type     | Constraints                                 | Description              |
| -------- | -------- | ------------------------------------------- | ------------------------ |
| itemId   | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref           |
| login    | Text     | nullable                                    | Username                 |
| email    | Text     | nullable                                    | Email                    |
| password | Text     | -                                           | Encrypted password       |
| url      | Text     | nullable                                    | Associated URL           |
| expireAt | DateTime | nullable                                    | Password expiration date |

**Constraints:** CHECK (login IS NOT NULL OR email IS NOT NULL)

---

## Table: password_history

History table for password-specific fields. Each record is linked to
`vault_item_history` via `history_id → vault_item_history.id ON DELETE CASCADE`.

| Column    | Type     | Constraints                                        | Description                               |
| --------- | -------- | -------------------------------------------------- | ----------------------------------------- |
| historyId | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref                        |
| login     | Text     | nullable                                           | Login snapshot                            |
| email     | Text     | nullable                                           | Email snapshot                            |
| password  | Text     | nullable                                           | Encrypted password (nullable for privacy) |
| url       | Text     | nullable                                           | URL snapshot                              |
| expireAt  | DateTime | nullable                                           | Expiration date snapshot                  |

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

## Table: api_key_items

Type-specific table for API keys.

| Column             | Type     | Constraints                                 | Description                 |
| ------------------ | -------- | ------------------------------------------- | --------------------------- |
| itemId             | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref              |
| service            | Text     | min: 1, max: 255                            | Service name                |
| key                | Text     | -                                           | Encrypted API key           |
| maskedKey          | Text     | nullable                                    | Masked display value        |
| tokenType          | Text     | nullable                                    | Token type                  |
| environment        | Text     | nullable                                    | Environment (prod/dev/etc.) |
| expiresAt          | DateTime | nullable                                    | Expiration date             |
| revoked            | Bool     | default: false                              | Revoked flag                |
| rotationPeriodDays | Int      | nullable                                    | Rotation policy             |
| lastRotatedAt      | DateTime | nullable                                    | Last rotation timestamp     |
| metadata           | Text     | nullable                                    | JSON metadata               |

---

## Table: api_key_history

History table for API key-specific fields.

| Column             | Type     | Constraints                                        | Description                 |
| ------------------ | -------- | -------------------------------------------------- | --------------------------- |
| historyId          | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref          |
| service            | Text     | min: 1, max: 255                                   | Service snapshot            |
| key                | Text     | nullable                                           | Encrypted key snapshot      |
| maskedKey          | Text     | nullable                                           | Masked key snapshot         |
| tokenType          | Text     | nullable                                           | Token type snapshot         |
| environment        | Text     | nullable                                           | Environment snapshot        |
| expiresAt          | DateTime | nullable                                           | Expiration snapshot         |
| revoked            | Bool     | default: false                                     | Revoked flag snapshot       |
| rotationPeriodDays | Int      | nullable                                           | Rotation policy snapshot    |
| lastRotatedAt      | DateTime | nullable                                           | Rotation timestamp snapshot |
| metadata           | Text     | nullable                                           | JSON metadata snapshot      |

---

## Table: ssh_key_items

Type-specific table for SSH keys.

| Column           | Type | Constraints                                 | Description             |
| ---------------- | ---- | ------------------------------------------- | ----------------------- |
| itemId           | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref          |
| publicKey        | Text | -                                           | Public key              |
| privateKey       | Text | -                                           | Encrypted private key   |
| keyType          | Text | nullable                                    | Key type                |
| keySize          | Int  | nullable                                    | Key size                |
| passphraseHint   | Text | nullable                                    | Passphrase hint         |
| comment          | Text | nullable                                    | Key comment             |
| fingerprint      | Text | nullable                                    | Key fingerprint         |
| createdBy        | Text | nullable                                    | Creator/source          |
| addedToAgent     | Bool | default: false                              | Added to ssh-agent flag |
| usage            | Text | nullable                                    | Usage context           |
| publicKeyFileId  | Text | nullable                                    | Linked public key file  |
| privateKeyFileId | Text | nullable                                    | Linked private key file |
| metadata         | Text | nullable                                    | JSON metadata           |

---

## Table: ssh_key_history

History table for SSH key-specific fields.

| Column           | Type | Constraints                                        | Description               |
| ---------------- | ---- | -------------------------------------------------- | ------------------------- |
| historyId        | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref        |
| publicKey        | Text | -                                                  | Public key snapshot       |
| privateKey       | Text | nullable                                           | Private key snapshot      |
| keyType          | Text | nullable                                           | Key type snapshot         |
| keySize          | Int  | nullable                                           | Key size snapshot         |
| passphraseHint   | Text | nullable                                           | Hint snapshot             |
| comment          | Text | nullable                                           | Comment snapshot          |
| fingerprint      | Text | nullable                                           | Fingerprint snapshot      |
| createdBy        | Text | nullable                                           | Creator snapshot          |
| addedToAgent     | Bool | default: false                                     | Agent flag snapshot       |
| usage            | Text | nullable                                           | Usage snapshot            |
| publicKeyFileId  | Text | nullable                                           | Public key file snapshot  |
| privateKeyFileId | Text | nullable                                           | Private key file snapshot |
| metadata         | Text | nullable                                           | Metadata snapshot         |

---

## Table: certificate_items

Type-specific table for certificates.

| Column         | Type     | Constraints                                 | Description                 |
| -------------- | -------- | ------------------------------------------- | --------------------------- |
| itemId         | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref              |
| certificatePem | Text     | -                                           | Certificate PEM             |
| privateKey     | Text     | nullable                                    | Encrypted private key       |
| serialNumber   | Text     | nullable                                    | Serial number               |
| issuer         | Text     | nullable                                    | Issuer                      |
| subject        | Text     | nullable                                    | Subject                     |
| validFrom      | DateTime | nullable                                    | Validity start              |
| validTo        | DateTime | nullable                                    | Validity end                |
| fingerprint    | Text     | nullable                                    | Certificate fingerprint     |
| keyUsage       | Text     | nullable                                    | Key usage JSON/text         |
| extensions     | Text     | nullable                                    | Extensions JSON/text        |
| pfxBlob        | Blob     | nullable                                    | Encrypted PFX/PKCS#12       |
| passwordForPfx | Text     | nullable                                    | Encrypted PFX password      |
| ocspUrl        | Text     | nullable                                    | OCSP URL                    |
| crlUrl         | Text     | nullable                                    | CRL URL                     |
| autoRenew      | Bool     | default: false                              | Auto-renew flag             |
| lastCheckedAt  | DateTime | nullable                                    | Last health-check timestamp |

---

## Table: certificate_history

History table for certificate-specific fields.

| Column         | Type     | Constraints                                        | Description              |
| -------------- | -------- | -------------------------------------------------- | ------------------------ |
| historyId      | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref       |
| certificatePem | Text     | -                                                  | PEM snapshot             |
| privateKey     | Text     | nullable                                           | Private key snapshot     |
| serialNumber   | Text     | nullable                                           | Serial snapshot          |
| issuer         | Text     | nullable                                           | Issuer snapshot          |
| subject        | Text     | nullable                                           | Subject snapshot         |
| validFrom      | DateTime | nullable                                           | Valid from snapshot      |
| validTo        | DateTime | nullable                                           | Valid to snapshot        |
| fingerprint    | Text     | nullable                                           | Fingerprint snapshot     |
| keyUsage       | Text     | nullable                                           | Key usage snapshot       |
| extensions     | Text     | nullable                                           | Extensions snapshot      |
| pfxBlob        | Blob     | nullable                                           | PFX snapshot             |
| passwordForPfx | Text     | nullable                                           | PFX password snapshot    |
| ocspUrl        | Text     | nullable                                           | OCSP URL snapshot        |
| crlUrl         | Text     | nullable                                           | CRL URL snapshot         |
| autoRenew      | Bool     | default: false                                     | Auto-renew flag snapshot |
| lastCheckedAt  | DateTime | nullable                                           | Last check snapshot      |

---

## Table: crypto_wallet_items

Type-specific table for crypto wallets.

| Column               | Type     | Constraints                                 | Description             |
| -------------------- | -------- | ------------------------------------------- | ----------------------- |
| itemId               | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref          |
| walletType           | Text     | -                                           | Wallet type             |
| mnemonic             | Text     | nullable                                    | Encrypted mnemonic      |
| privateKey           | Text     | nullable                                    | Encrypted private key   |
| derivationPath       | Text     | nullable                                    | Derivation path         |
| network              | Text     | nullable                                    | Network                 |
| addresses            | Text     | nullable                                    | Addresses JSON/text     |
| xpub                 | Text     | nullable                                    | Public extended key     |
| xprv                 | Text     | nullable                                    | Private extended key    |
| hardwareDevice       | Text     | nullable                                    | Hardware device id/name |
| lastBalanceCheckedAt | DateTime | nullable                                    | Last balance check      |
| watchOnly            | Bool     | default: false                              | Watch-only flag         |
| derivationScheme     | Text     | nullable                                    | Derivation scheme       |

---

## Table: crypto_wallet_history

History table for crypto wallet-specific fields.

| Column               | Type     | Constraints                                        | Description              |
| -------------------- | -------- | -------------------------------------------------- | ------------------------ |
| historyId            | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref       |
| walletType           | Text     | -                                                  | Wallet type snapshot     |
| mnemonic             | Text     | nullable                                           | Mnemonic snapshot        |
| privateKey           | Text     | nullable                                           | Private key snapshot     |
| derivationPath       | Text     | nullable                                           | Derivation path snapshot |
| network              | Text     | nullable                                           | Network snapshot         |
| addresses            | Text     | nullable                                           | Addresses snapshot       |
| xpub                 | Text     | nullable                                           | XPUB snapshot            |
| xprv                 | Text     | nullable                                           | XPRV snapshot            |
| hardwareDevice       | Text     | nullable                                           | Hardware device snapshot |
| lastBalanceCheckedAt | DateTime | nullable                                           | Balance check snapshot   |
| watchOnly            | Bool     | default: false                                     | Watch-only flag snapshot |
| derivationScheme     | Text     | nullable                                           | Scheme snapshot          |

---

## Table: wifi_items

Type-specific table for Wi‑Fi credentials.

| Column             | Type | Constraints                                 | Description           |
| ------------------ | ---- | ------------------------------------------- | --------------------- |
| itemId             | Text | Primary Key, FK to vault_items.id (cascade) | Vault item ref        |
| ssid               | Text | -                                           | SSID                  |
| password           | Text | nullable                                    | Encrypted password    |
| security           | Text | nullable                                    | Security mode         |
| hidden             | Bool | default: false                              | Hidden network flag   |
| eapMethod          | Text | nullable                                    | Enterprise EAP method |
| username           | Text | nullable                                    | Enterprise username   |
| identity           | Text | nullable                                    | Enterprise identity   |
| domain             | Text | nullable                                    | Enterprise domain     |
| lastConnectedBssid | Text | nullable                                    | Last connected BSSID  |
| priority           | Int  | nullable                                    | Network priority      |
| qrCodePayload      | Text | nullable                                    | QR payload            |

---

## Table: wifi_history

History table for Wi‑Fi-specific fields.

| Column             | Type | Constraints                                        | Description          |
| ------------------ | ---- | -------------------------------------------------- | -------------------- |
| historyId          | Text | Primary Key, FK to vault_item_history.id (cascade) | History record ref   |
| ssid               | Text | -                                                  | SSID snapshot        |
| password           | Text | nullable                                           | Password snapshot    |
| security           | Text | nullable                                           | Security snapshot    |
| hidden             | Bool | default: false                                     | Hidden flag snapshot |
| eapMethod          | Text | nullable                                           | EAP method snapshot  |
| username           | Text | nullable                                           | Username snapshot    |
| identity           | Text | nullable                                           | Identity snapshot    |
| domain             | Text | nullable                                           | Domain snapshot      |
| lastConnectedBssid | Text | nullable                                           | BSSID snapshot       |
| priority           | Int  | nullable                                           | Priority snapshot    |
| qrCodePayload      | Text | nullable                                           | QR payload snapshot  |

---

## Table: identity_items

Type-specific table for identity documents.

| Column            | Type     | Constraints                                 | Description         |
| ----------------- | -------- | ------------------------------------------- | ------------------- |
| itemId            | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref      |
| idType            | Text     | -                                           | Identity type       |
| idNumber          | Text     | -                                           | Document number     |
| fullName          | Text     | nullable                                    | Full name           |
| dateOfBirth       | DateTime | nullable                                    | Date of birth       |
| placeOfBirth      | Text     | nullable                                    | Place of birth      |
| nationality       | Text     | nullable                                    | Nationality         |
| issuingAuthority  | Text     | nullable                                    | Issuing authority   |
| issueDate         | DateTime | nullable                                    | Issue date          |
| expiryDate        | DateTime | nullable                                    | Expiry date         |
| mrz               | Text     | nullable                                    | MRZ                 |
| scanAttachmentId  | Text     | nullable                                    | Scan attachment id  |
| photoAttachmentId | Text     | nullable                                    | Photo attachment id |
| verified          | Bool     | default: false                              | Verification flag   |

---

## Table: identity_history

History table for identity-specific fields.

| Column            | Type     | Constraints                                        | Description               |
| ----------------- | -------- | -------------------------------------------------- | ------------------------- |
| historyId         | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref        |
| idType            | Text     | -                                                  | Type snapshot             |
| idNumber          | Text     | -                                                  | Number snapshot           |
| fullName          | Text     | nullable                                           | Full name snapshot        |
| dateOfBirth       | DateTime | nullable                                           | DOB snapshot              |
| placeOfBirth      | Text     | nullable                                           | Place snapshot            |
| nationality       | Text     | nullable                                           | Nationality snapshot      |
| issuingAuthority  | Text     | nullable                                           | Authority snapshot        |
| issueDate         | DateTime | nullable                                           | Issue date snapshot       |
| expiryDate        | DateTime | nullable                                           | Expiry snapshot           |
| mrz               | Text     | nullable                                           | MRZ snapshot              |
| scanAttachmentId  | Text     | nullable                                           | Scan attachment snapshot  |
| photoAttachmentId | Text     | nullable                                           | Photo attachment snapshot |
| verified          | Bool     | default: false                                     | Verification snapshot     |

---

## Table: license_key_items

Type-specific table for license keys.

| Column         | Type     | Constraints                                 | Description           |
| -------------- | -------- | ------------------------------------------- | --------------------- |
| itemId         | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref        |
| product        | Text     | -                                           | Product               |
| licenseKey     | Text     | -                                           | Encrypted license key |
| licenseType    | Text     | nullable                                    | License type          |
| seats          | Int      | nullable                                    | Seats                 |
| maxActivations | Int      | nullable                                    | Max activations       |
| activatedOn    | DateTime | nullable                                    | First activation      |
| purchaseDate   | DateTime | nullable                                    | Purchase date         |
| purchaseFrom   | Text     | nullable                                    | Purchase source       |
| orderId        | Text     | nullable                                    | Order id              |
| licenseFileId  | Text     | nullable                                    | License file id       |
| expiresAt      | DateTime | nullable                                    | Expiration date       |
| supportContact | Text     | nullable                                    | Support contact       |

---

## Table: license_key_history

History table for license key-specific fields.

| Column         | Type     | Constraints                                        | Description              |
| -------------- | -------- | -------------------------------------------------- | ------------------------ |
| historyId      | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref       |
| product        | Text     | -                                                  | Product snapshot         |
| licenseKey     | Text     | -                                                  | License key snapshot     |
| licenseType    | Text     | nullable                                           | Type snapshot            |
| seats          | Int      | nullable                                           | Seats snapshot           |
| maxActivations | Int      | nullable                                           | Max activations snapshot |
| activatedOn    | DateTime | nullable                                           | Activation snapshot      |
| purchaseDate   | DateTime | nullable                                           | Purchase date snapshot   |
| purchaseFrom   | Text     | nullable                                           | Source snapshot          |
| orderId        | Text     | nullable                                           | Order snapshot           |
| licenseFileId  | Text     | nullable                                           | File id snapshot         |
| expiresAt      | DateTime | nullable                                           | Expiry snapshot          |
| supportContact | Text     | nullable                                           | Contact snapshot         |

---

## Table: recovery_codes_items

Type-specific table for recovery codes.

| Column        | Type     | Constraints                                 | Description               |
| ------------- | -------- | ------------------------------------------- | ------------------------- |
| itemId        | Text     | Primary Key, FK to vault_items.id (cascade) | Vault item ref            |
| codesBlob     | Text     | -                                           | Encrypted codes blob      |
| codesCount    | Int      | nullable                                    | Total codes count         |
| usedCount     | Int      | nullable                                    | Used codes count          |
| perCodeStatus | Text     | nullable                                    | Per-code status JSON/text |
| generatedAt   | DateTime | nullable                                    | Generated timestamp       |
| oneTime       | Bool     | default: false                              | One-time codes flag       |
| displayHint   | Text     | nullable                                    | Display masking policy    |

---

## Table: recovery_codes_history

History table for recovery code-specific fields.

| Column        | Type     | Constraints                                        | Description            |
| ------------- | -------- | -------------------------------------------------- | ---------------------- |
| historyId     | Text     | Primary Key, FK to vault_item_history.id (cascade) | History record ref     |
| codesBlob     | Text     | -                                                  | Codes blob snapshot    |
| codesCount    | Int      | nullable                                           | Count snapshot         |
| usedCount     | Int      | nullable                                           | Used count snapshot    |
| perCodeStatus | Text     | nullable                                           | Status snapshot        |
| generatedAt   | DateTime | nullable                                           | Generated-at snapshot  |
| oneTime       | Bool     | default: false                                     | One-time flag snapshot |
| displayHint   | Text     | nullable                                           | Display hint snapshot  |

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

| Column      | Type     | Constraints                             | Description                                 |
| ----------- | -------- | --------------------------------------- | ------------------------------------------- |
| id          | Text     | Primary Key, UUID v4                    | Unique identifier                           |
| name        | Text     | unique, min: 1, max: 100                | Category name                               |
| description | Text     | nullable                                | Description                                 |
| iconId      | Text     | nullable, FK to icons.id (setNull)      | Icon reference                              |
| color       | Text     | default: 'FFFFFF'                       | Hex color code                              |
| type        | Text     | enum: CategoryType                      | Category type (all supported entity groups) |
| parentId    | Text     | nullable, FK to categories.id (setNull) | Parent category (subcategory support)       |
| createdAt   | DateTime | default: now                            | Creation timestamp                          |
| modifiedAt  | DateTime | default: now                            | Modification timestamp                      |

---

## Table: tags

| Column     | Type     | Constraints          | Description                            |
| ---------- | -------- | -------------------- | -------------------------------------- |
| id         | Text     | Primary Key, UUID v4 | Unique identifier                      |
| name       | Text     | unique               | Tag name                               |
| color      | Text     | default: 'FFFFFF'    | Hex color code                         |
| type       | Text     | enum: TagType        | Tag type (all supported entity groups) |
| createdAt  | DateTime | default: now         | Creation timestamp                     |
| modifiedAt | DateTime | default: now         | Modification timestamp                 |

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

## Table: store_settings

Table for storing configurable settings per store instance.

| Column | Type | Constraints | Description          |
| ------ | ---- | ----------- | -------------------- |
| key    | Text | Primary Key | Key of the setting   |
| value  | Text | -           | Value of the setting |

**Default Keys:**

- `history_limit`
- `history_max_age_days`
- `history_enabled`

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
├── document_items   (itemId → vault_items.id CASCADE)
├── api_key_items    (itemId → vault_items.id CASCADE)
├── ssh_key_items    (itemId → vault_items.id CASCADE)
├── certificate_items (itemId → vault_items.id CASCADE)
├── crypto_wallet_items (itemId → vault_items.id CASCADE)
├── wifi_items       (itemId → vault_items.id CASCADE)
├── identity_items   (itemId → vault_items.id CASCADE)
├── license_key_items (itemId → vault_items.id CASCADE)
└── recovery_codes_items (itemId → vault_items.id CASCADE)

vault_item_history (base history)
├── password_history  (historyId → vault_item_history.id CASCADE)
├── note_history      (historyId → vault_item_history.id CASCADE)
├── otp_history       (historyId → vault_item_history.id CASCADE)
├── bank_card_history (historyId → vault_item_history.id CASCADE)
├── file_history      (historyId → vault_item_history.id CASCADE)
├── document_history  (historyId → vault_item_history.id CASCADE)
├── api_key_history   (historyId → vault_item_history.id CASCADE)
├── ssh_key_history   (historyId → vault_item_history.id CASCADE)
├── certificate_history (historyId → vault_item_history.id CASCADE)
├── crypto_wallet_history (historyId → vault_item_history.id CASCADE)
├── wifi_history      (historyId → vault_item_history.id CASCADE)
├── identity_history  (historyId → vault_item_history.id CASCADE)
├── license_key_history (historyId → vault_item_history.id CASCADE)
└── recovery_codes_history (historyId → vault_item_history.id CASCADE)

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
