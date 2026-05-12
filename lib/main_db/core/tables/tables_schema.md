# Database Schema

Данный документ отражает текущую схему таблиц Drift в директории
`lib/main_db/core/tables`.

## Core Vault Tables

Основные таблицы для хранения элементов и их истории.

### vault_items

Базовая таблица для всех элементов хранилища. Columns: `id`, `type`, `name`,
`description`, `categoryId`, `iconRefId`, `usedCount`, `isFavorite`,
`isArchived`, `isPinned`, `isDeleted`, `createdAt`, `modifiedAt`, `recentScore`,
`lastUsedAt`. Notes: `id` — UUID v4 (PK). `type` — `VaultItemType`. Связи с
`categories` и `icon_refs`. Имеются ограничения на неотрицательность счетчиков и
непустое имя. enum VaultItemType { password, otp, note, bankCard, document,
file, contact, apiKey, sshKey, certificate, cryptoWallet, wifi, identity,
licenseKey, recoveryCodes, loyaltyCard, }

### vault_item_history

Таблица истории изменений базовых полей элементов. Columns: `id`, `itemId`,
`kind`, `action`, `type`, `name`, `description`, `categoryId`, `categoryName`,
`categoryType`, `categoryColor`, `categoryIconRefId`, `tagsSnapshotJson`,
`iconRefId`, `usedCount`, `isFavorite`, `isArchived`, `isPinned`, `isDeleted`,
`createdAt`, `modifiedAt`, `recentScore`, `lastUsedAt`, `snapshotId`,
`historyCreatedAt`.
Notes: Снимок состояния `vault_items` на момент действия `action`. Содержит
снимки данных категории и тегов. enum VaultItemHistoryKind { snapshot, event, }
enum VaultItemHistoryAction { created, updated, archived, restored, deleted,
recovered, favorited, unfavorited, pinned, unpinned, }

### vault_item_custom_fields

Кастомные поля элементов. Columns: `id`, `itemId`, `label`, `value`,
`fieldType`, `fieldTypeOther`, `sortOrder`. Notes: Связь с `vault_items`
(Cascade). `fieldType` — `CustomFieldType`. enum CustomFieldType { text,
concealed, url, email, phone, date, number, multiline, boolean, json, other, }

### vault_item_custom_fields_history

История кастомных полей. Columns: `id`, `historyId`, `originalFieldId`, `label`,
`value`, `fieldType`, `fieldTypeOther`, `sortOrder`. Notes: Связь с
`vault_item_history`. Хранит снимки кастомных полей.

## Classification and Link Tables

Таблицы для организации, группировки и ресурсов.

### categories

Древовидные категории. Columns: `id`, `name`, `description`, `iconRefId`,
`color`, `type`, `parentId`, `createdAt`, `modifiedAt`. Notes: `color` в формате
`AARRGGBB`. `type` — `CategoryType`. Рекурсивная связь через `parentId`. enum
CategoryType { note, password, totp, bankCard, file, document, contact, apiKey,
sshKey, certificate, cryptoWallet, wifi, identity, licenseKey, recoveryCodes,
loyaltyCard, mixed, }

### tags

Теги для классификации. Columns: `id`, `name`, `color`, `type`, `createdAt`,
`modifiedAt`. Notes: Уникальность по `(name, type)`. enum TagType { note,
password, totp, bankCard, file, document, contact, apiKey, sshKey, certificate,
cryptoWallet, wifi, identity, licenseKey, recoveryCodes, loyaltyCard, mixed, }

### item_tags

Таблица связей элементов и тегов (многие-ко-многим). Columns: `itemId`, `tagId`,
`createdAt`. Notes: Составной PK `(itemId, tagId)`.

### item_links

Универсальная таблица связей между элементами хранилища (направленный граф).
Columns: `id`, `sourceItemId`, `targetItemId`, `relationType`,
`relationTypeOther`, `label`, `sortOrder`, `createdAt`, `modifiedAt`. Notes:
`id` — UUID v4 (PK). `sourceItemId` и `targetItemId` — FK к `vault_items`.
`relationType` — `ItemLinkType`. Поддерживаемые типы связей:

- `related`: свободная связь между любыми элементами.
- `other`: связь с обязательным указанием `relationTypeOther`.
- `note`: связь с заметкой (target должен быть note).
- `attachment`: вложение (target должен быть file или document).
- `otpForPassword`: связь пароля и OTP (password → otp).
- `supportContact`: контакт поддержки (target должен быть contact).
- `purchaseDocument`: документ покупки (licenseKey → file/document).
- `identityScan`: скан документа (identity → document).
- `identityPhoto`: фото для удостоверения (identity → file).
- `sshPublicKeyFile`: файл публичного ключа (sshKey → file).
- `sshPrivateKeyFile`: файл приватного ключа (sshKey → file).
- `certificateFile`: файл сертификата (certificate → file/document).
- `certificatePrivateKeyFile`: файл ключа сертификата (certificate → file).

Имеет строгие SQL-триггеры для валидации типов связей на уровне БД. Запрещены
дубликаты и ссылки на самого себя.

### item_link_history

Таблица истории связей. Columns: `id`, `historyId`, `sourceLinkId`,
`sourceItemId`, `targetItemId`, `relationType`, `relationTypeOther`, `label`,
`sortOrder`, `createdAt`, `modifiedAt`, `snapshotId`, `snapshotCreatedAt`. Notes: Хранит
снимок `item_links` на момент создания записи `vault_item_history`.

### item_category_history

Snapshot категории vault item. Columns: `id`, `historyId`, `snapshotId`,
`itemId`, `categoryId`, `name`, `description`, `iconRefId`, `color`, `type`,
`parentId`, `categoryCreatedAt`, `categoryModifiedAt`, `snapshotCreatedAt`.

### vault_item_tag_history

Snapshot тегов vault item. Columns: `id`, `historyId`, `snapshotId`, `itemId`,
`tagId`, `name`, `color`, `type`, `tagCreatedAt`, `tagModifiedAt`,
`snapshotCreatedAt`.

### icon_refs

Ссылки на иконки (встроенные, из паков или пользовательские). Columns: `id`,
`iconSourceType`, `iconPackId`, `iconValue`, `customIconId`, `color`,
`backgroundColor`, `createdAt`, `modifiedAt`. Notes: Сложная валидация источника
иконки через CHECK. Уникальные индексы для разных типов источников. enum
IconSourceType { builtin, pack, custom }

### custom_icons

Пользовательские иконки (бинарные данные). Columns: `id`, `name`, `format`,
`data`, `createdAt`, `modifiedAt`. Notes: `data` — Blob. `format` —
`CustomIconFormat`. enum CustomIconFormat { png, jpg, jpeg, svg, webp, gif }

## Entity-specific Items

Таблицы со специфическими полями для каждого типа элемента.

### password_items

Поля паролей. Columns: `itemId`, `login`, `email`, `password`, `url`,
`expiresAt`. Notes: PK — `itemId` (FK к `vault_items`).

### otp_items

Поля одноразовых паролей (OTP). Columns: `itemId`, `type`, `issuer`,
`accountName`, `secret`, `algorithm`, `digits`, `period`, `counter`. Notes:
`secret` хранится как Blob. Все связи с паролями вынесены в `item_links`
(`otpForPassword`). enum OtpType { totp, hotp } enum OtpHashAlgorithm { SHA1,
SHA256, SHA512 }

### note_items

Содержимое заметок. Columns: `itemId`, `deltaJson`, `content`. Notes:
`deltaJson` хранит Quill Delta формат. `content` — чистый текст для превью.

### bank_card_items

Банковские карты. Columns: `itemId`, `cardholderName`, `cardNumber`, `cardType`,
`cardTypeOther`, `cardNetwork`, `cardNetworkOther`, `expiryMonth`, `expiryYear`,
`cvv`, `bankName`, `accountNumber`, `routingNumber`. Notes: Месяц и год хранятся
как строки `MM` и `YYYY`. enum CardType { debit, credit, prepaid, virtual, other
} enum CardNetwork { visa, mastercard, amex, discover, dinersclub, jcb,
unionpay, mir, maestro, other, }

### document_items

Метаданные документов. Columns: `itemId`, `currentVersionId`. Notes:
`document_items` хранит только ссылку на текущую версию; все данные для
восстановления документа находятся в `document_versions`. enum DocumentType {
passport, idCard, driverLicense, contract, invoice, receipt, certificate,
insurance, tax, medical, legal, financial, other, }

### document_pages

Live-указатели страниц документа. Columns: `id`, `documentId`,
`currentVersionPageId`. Notes: все восстанавливаемые данные страницы хранятся в
`document_version_pages`; `document_pages` хранит только стабильный id страницы
и ссылку на текущую страницу версии.

### document_versions

Версии документа. Columns: `id`, `documentId`, `itemHistoryId`, `versionNumber`,
`documentType`, `documentTypeOther`, `aggregateSha256Hash`, `pageCount`,
`isCurrent`, `snapshotId`, `createdAt`, `modifiedAt`. Notes: Главный источник
восстановления документа. Ссылка на историю изменений `itemHistoryId`.
Snapshot-метаданные файлов хранятся на уровне страниц версии через
`document_version_pages.metadataHistoryId`. Уникальность
`(documentId, versionNumber)`, частичный unique-index ограничивает одну
активную версию на документ.

### document_version_pages

Страницы версии документа. Columns: `id`, `versionId`, `metadataHistoryId`,
`pageNumber`, `extractedText`, `pageSha256Hash`, `isPrimary`, `createdAt`. Notes:
связь с `document_versions` и snapshot-метаданными страницы в
`file_metadata_history`. Уникальность `(versionId, pageNumber)`, частичный
unique-index ограничивает одну primary-страницу на версию.

### file_items

Элементы типа "Файл". Columns: `itemId`, `metadataId`. Notes: Связь с
`FileMetadata`.

### file_metadata

Технические данные файлов. Columns: `id`, `fileName`, `fileExtension`,
`filePath`, `mimeType`, `fileSize`, `sha256`. Notes: Реальный путь и хеш
файла. sha256 — SHA-256 хэш для проверки целостности.

### file_metadata_history

Snapshot технических данных файлов. Columns: `id`, `historyId`, `metadataId`,
`fileName`, `fileExtension`, `filePath`, `mimeType`, `fileSize`, `sha256`,
`snapshotId`, `snapshotCreatedAt`. Notes: `metadataId` не является FK, чтобы snapshot
сохранялся после замены или удаления текущих `file_metadata`; `historyId`
опционально связывает snapshot с `vault_item_history`.

### contact_items

Контактные данные. Columns: `itemId`, `phone`, `email`, `company`, `jobTitle`,
`address`, `website`, `birthday`, `isEmergencyContact`. Notes: Простое хранение
адреса строкой.

### api_key_items

API ключи. Columns: `itemId`, `service`, `key`, `tokenType`, `tokenTypeOther`,
`environment`, `environmentOther`, `expiresAt`, `revoked`, `rotationPeriodDays`,
`lastRotatedAt`, `scopes`, `owner`, `baseUrl`. Notes: Поддержка ротации и
различных окружений. enum ApiKeyEnvironment { development, staging, production,
testing, local, other, }

### ssh_key_items

SSH ключи. Columns: `itemId`, `publicKey`, `privateKey`, `keyType`,
`keyTypeOther`, `keySize`, `fingerprint`, `createdBy`, `addedToAgent`, `usage`.
Notes: Хранение ключа и его отпечатка. Файлы ключей привязываются через
`item_links`. enum SshKeyType { rsa, ed25519, ecdsa, dsa, other }

### certificate_items

Сертификаты. Columns: `itemId`, `certificateFormat`, `certificateFormatOther`,
`certificatePem`, `certificateBlob`, `privateKey`, `privateKeyPassword`,
`passwordForPfx`, `keyAlgorithm`, `keyAlgorithmOther`, `keySize`,
`serialNumber`, `issuer`, `subject`, `validFrom`, `validTo`, `ocspUrl`,
`crlUrl`. Notes: Поддержка PEM и бинарных форматов. Внешние файлы привязываются
через `item_links`. enum CertificateFormat { pem, der, pfx, pkcs12, other } enum
CertificateKeyAlgorithm { rsa, ecdsa, ed25519, dsa, other }

### crypto_wallet_items

Криптокошельки. Columns: `itemId`, `walletType`, `walletTypeOther`, `network`,
`networkOther`, `mnemonic`, `privateKey`, `derivationPath`, `derivationScheme`,
`derivationSchemeOther`, `addresses`, `xpub`, `xprv`, `hardwareDevice`,
`watchOnly`. Notes: Поддержка сид-фраз, ключей и путей деривации. enum
CryptoWalletType { software, hardware, paper, watchOnly, multisig, other } enum
CryptoNetwork { bitcoin, ethereum, solana, ton, tron, polygon, bsc, litecoin,
monero, dogecoin, other, } enum CryptoDerivationScheme { bip32, bip39, bip44,
bip49, bip84, bip86, slip10, other, }

### wifi_items

Данные Wi-Fi сетей. Columns: `itemId`, `ssid`, `password`, `security`,
`securityOther`, `hidden`, `username`. Notes: Поддержка Enterprise (WPA/WPA2)
через поле `username`. enum WifiSecurityType { open, wep, wpa, wpa2, wpa3,
wpaEnterprise, other }

### identity_items

Удостоверения личности. Columns: `itemId`, `idType`, `idTypeOther`, `idNumber`,
`fullName`, `dateOfBirth`, `placeOfBirth`, `nationality`, `issuingAuthority`,
`issueDate`, `expiryDate`, `mrz`, `verified`. Notes: Сканы и фото привязываются
через `item_links` (`identityScan`, `identityPhoto`). enum IdentityDocumentType
{ passport, idCard, driverLicense, residencePermit, birthCertificate, taxId,
socialSecurity, insurance, studentId, employeeId, other, }

### license_key_items

Лицензионные ключи. Columns: `itemId`, `product`, `licenseKey`, `licenseType`,
`licenseTypeOther`, `seats`, `maxActivations`, `activatedOn`, `purchaseDate`,
`purchaseFrom`, `orderId`, `expiresAt`. Notes: Учет активаций и сроков.
Документы покупки и контакты поддержки — через `item_links`. enum LicenseType {
perpetual, subscription, trial, volume, oem, educational, openSource, other, }

### recovery_codes_items

Группы кодов восстановления. Columns: `itemId`, `codesCount`, `usedCount`,
`generatedAt`, `oneTime`. Notes: Кэширует количество кодов из таблицы
`recovery_codes`.

### recovery_codes

Отдельные коды восстановления. Columns: `id`, `itemId`, `code`, `used`,
`usedAt`, `position`. Notes: Связь с `recovery_codes_items`.

### loyalty_card_items

Карты лояльности. Columns: `itemId`, `programName`, `cardNumber`, `holderName`,
`barcodeValue`, `barcodeType`, `barcodeTypeOther`, `password`, `tier`,
`expiryDate`, `website`, `phoneNumber`. Notes: Поддержка различных типов
штрихкодов. enum LoyaltyBarcodeType { qr, code128, code39, ean13, ean8, upcA,
upcE, aztec, pdf417, dataMatrix, other, }

## History Tables

Таблицы для хранения истории специфических полей. Колонки соответствуют
item-таблицам (часто nullable для возможности частичного сохранения).

- **api_key_history**: `historyId`, `service`, `key`, `tokenType`,
  `tokenTypeOther`, `environment`, `environmentOther`, `expiresAt`, `revoked`,
  `rotationPeriodDays`, `lastRotatedAt`, `scopes`, `owner`, `baseUrl`.
- **bank_card_history**: `historyId`, `cardholderName`, `cardNumber`,
  `cardType`, `cardTypeOther`, `cardNetwork`, `cardNetworkOther`, `expiryMonth`,
  `expiryYear`, `cvv`, `bankName`, `accountNumber`, `routingNumber`.
- **certificate_history**: `historyId`, `certificateFormat`,
  `certificateFormatOther`, `certificatePem`, `certificateBlob`, `privateKey`,
  `privateKeyPassword`, `passwordForPfx`, `keyAlgorithm`, `keyAlgorithmOther`,
  `keySize`, `serialNumber`, `issuer`, `subject`, `validFrom`, `validTo`,
  `ocspUrl`, `crlUrl`.
- **contact_history**: `historyId`, `phone`, `email`, `company`, `jobTitle`,
  `address`, `website`, `birthday`, `isEmergencyContact`.
- **crypto_wallet_history**: `historyId`, `walletType`, `walletTypeOther`,
  `network`, `networkOther`, `mnemonic`, `privateKey`, `derivationPath`,
  `derivationScheme`, `derivationSchemeOther`, `addresses`, `xpub`, `xprv`,
  `hardwareDevice`, `watchOnly`.
- **file_history**: `historyId`, `metadataHistoryId`.
- **file_metadata_history**: `id`, `historyId`, `metadataId`, `fileName`,
  `fileExtension`, `filePath`, `mimeType`, `fileSize`, `sha256`,
  `snapshotId`, `snapshotCreatedAt`.
- **item_link_history**: `id`, `historyId`, `sourceLinkId`, `sourceItemId`,
  `targetItemId`, `relationType`, `relationTypeOther`, `label`, `sortOrder`,
  `createdAt`, `modifiedAt`, `snapshotId`, `snapshotCreatedAt`.
- **identity_history**: `historyId`, `idType`, `idTypeOther`, `idNumber`,
  `fullName`, `dateOfBirth`, `placeOfBirth`, `nationality`, `issuingAuthority`,
  `issueDate`, `expiryDate`, `mrz`, `verified`.
- **license_key_history**: `historyId`, `product`, `licenseKey`, `licenseType`,
  `licenseTypeOther`, `seats`, `maxActivations`, `activatedOn`, `purchaseDate`,
  `purchaseFrom`, `orderId`, `expiresAt`.
- **loyalty_card_history**: `historyId`, `programName`, `cardNumber`,
  `holderName`, `barcodeValue`, `barcodeType`, `barcodeTypeOther`, `password`,
  `tier`, `expiryDate`, `website`, `phoneNumber`.
- **note_history**: `historyId`, `deltaJson`, `content`.
- **otp_history**: `historyId`, `type`, `issuer`, `accountName`, `secret`,
  `algorithm`, `digits`, `period`, `counter`.
- **password_history**: `historyId`, `login`, `email`, `password`, `url`,
  `expiresAt`.
- **recovery_codes_history**: `historyId`, `codesCount`, `usedCount`,
  `generatedAt`, `oneTime`.
- **ssh_key_history**: `historyId`, `publicKey`, `privateKey`, `keyType`,
  `keyTypeOther`, `keySize`, `fingerprint`, `createdBy`, `addedToAgent`,
  `usage`.
- **wifi_history**: `historyId`, `ssid`, `password`, `security`,
  `securityOther`, `hidden`, `username`.

## System Tables

Системные таблицы хранилища.

### store_meta

Метаданные текущего хранилища (Singleton). Columns: `singletonId`, `id`, `name`,
`description`, `passwordHash`, `salt`, `attachmentKey`, `createdAt`,
`modifiedAt`, `lastOpenedAt`. Notes: Содержит ровно одну строку
(`singletonId = 1`). `id` — глобальный UUID хранилища.

### store_settings

Настройки хранилища. Columns: `key`, `value`, `valueType`, `description`,
`createdAt`, `modifiedAt`. Notes: PK — `key`. `valueType` —
`StoreSettingValueType`.

### Формат цветов Цвета в таблицах `categories`, `icon_refs`, `tags` хранятся в формате `AARRGGBB` (альфа, красный, зеленый, синий) в виде строки без `#`.
