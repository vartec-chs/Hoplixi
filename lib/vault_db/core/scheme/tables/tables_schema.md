# Database Schema

Данный документ отражает текущую схему таблиц Drift в директории
`lib/vault_db/core/tables`.

## Core Vault Tables

Основные таблицы для элементов хранилища, их snapshot-истории и audit-логов.

### vault_items

Базовая таблица для всех элементов хранилища. Columns: `id`, `type`, `name`,
`description`, `categoryId`, `iconRefId`, `usedCount`, `isFavorite`,
`isArchived`, `isPinned`, `isDeleted`, `createdAt`, `modifiedAt`, `lastUsedAt`,
`archivedAt`, `deletedAt`, `recentScore`. Notes: `id` — UUID v4 (PK). `type` —
`VaultItemType { password, otp, note, bankCard, document, file, contact, apiKey, sshKey, certificate, cryptoWallet, wifi, identity, licenseKey, recoveryCodes, loyaltyCard }`.
Связи с `categories` и `icon_refs` nullable и удаляются через `SET NULL`.
`usedCount` и `recentScore` не могут быть отрицательными, `name` не пустое и без
outer whitespace. `archivedAt` и `deletedAt` отражают состояние
soft-delete/архивации и дополнительно жёстко проверяются триггерами на
insert/update, чтобы не допустить рассинхронизацию с `isArchived`/`isDeleted`.

### vault_snapshots_history

Snapshot базовых полей vault item. Columns: `id`, `itemId`, `action`, `type`,
`name`, `description`, `categoryId`, `categoryHistoryId`, `iconRefId`,
`usedCount`, `isFavorite`, `isArchived`, `isPinned`, `isDeleted`, `createdAt`,
`modifiedAt`, `lastUsedAt`, `archivedAt`, `deletedAt`, `recentScore`,
`historyCreatedAt`. Notes: это restorable snapshot текущего состояния item;
`categoryHistoryId` ссылается на
[item_category_history](#item_category_history). Таблица использует тот же
словарь действий, что и событийный лог, и хранит только базовые поля item без
специфичных payload-таблиц.

### vault_events_history

Audit/event лог по элементам хранилища. Columns: `id`, `itemId`, `action`,
`type`, `name`, `description`, `snapshotHistoryId`, `actorType`,
`eventCreatedAt`. Notes: immutable event stream; `actorType` — `user`, `system`,
`autoCleanup`, `import`, `sync`, `restore`, `extension`, `unknown`. Для
restorable действий `snapshotHistoryId` обязателен.

### vault_item_custom_fields

Кастомные поля элементов. Columns: `id`, `itemId`, `label`, `value`,
`fieldType`, `isSecret`, `sortOrder`, `createdAt`, `modifiedAt`. Notes:
`fieldType` —
`CustomFieldType { text, concealed, url, email, phone, date, number, multiline, boolean }`.
`isSecret` — быстрый флаг для UI, поиска и экспорта. Связь с `vault_items`
удаляется каскадно.

### vault_item_custom_fields_history

История кастомных полей. Columns: `id`, `snapshotHistoryId`, `originalFieldId`,
`label`, `value`, `fieldType`, `isSecret`, `sortOrder`, `createdAt`,
`modifiedAt`, `historyCreatedAt`. Notes: append-only snapshot строк
custom-fields; `snapshotHistoryId` указывает на `vault_snapshots_history`, а
`originalFieldId` сохраняется как необязательная ссылка на исходное поле.

## Classification and Link Tables

Таблицы для организации, группировки и ресурсов.

### categories

Древовидные категории. Columns: `id`, `name`, `description`, `iconRefId`,
`color`, `type`, `parentId`, `createdAt`, `modifiedAt`. Notes: `color` в формате
`AARRGGBB`. `type` — `CategoryType`. Рекурсивная связь через `parentId`. enum
CategoryType { note, password, otp, bankCard, file, document, contact, apiKey,
sshKey, certificate, cryptoWallet, wifi, identity, licenseKey, recoveryCodes,
loyaltyCard, mixed, }

### tags

Теги для классификации. Columns: `id`, `name`, `color`, `type`, `createdAt`,
`modifiedAt`. Notes: Уникальность по `(name, type)`. enum TagType { note,
password, otp, bankCard, file, document, contact, apiKey, sshKey, certificate,
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
`sortOrder`, `createdAt`, `modifiedAt`, `snapshotId`, `snapshotCreatedAt`.
Notes: Хранит снимок `item_links` на момент создания записи
`vault_snapshots_history`.

### item_category_history

Snapshot категории vault item. Columns: `id`, `snapshotId`, `itemId`,
`categoryId`, `name`, `description`, `iconRefId`, `color`, `type`, `parentId`,
`categoryCreatedAt`, `categoryModifiedAt`, `snapshotCreatedAt`. Notes:
`vault_snapshots_history.categoryHistoryId` указывает на эту запись.

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
(`otpForPassword`). `OtpType { otp, hotp }`,
`OtpHashAlgorithm { SHA1, SHA256, SHA512 }`. Для `otp` используется `period`,
для `hotp` — `counter`.

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
и ссылку на текущую страницу версии. Уникальность
`(documentId, currentVersionPageId)`. Триггеры в `document_pages.dart`
проверяют, что `currentVersionPageId` указывает на страницу версии того же
документа.

### document_versions

Версии документа. Columns: `id`, `documentId`, `historyId`, `versionNumber`,
`documentType`, `documentTypeOther`, `aggregateSha256Hash`, `pageCount`,
`createdAt`, `modifiedAt`. Notes: главный источник восстановления документа.
Текущая версия выбирается через `document_items.currentVersionId`. Ссылка на
snapshot базового item хранится в `historyId`. Snapshot-метаданные файлов
хранятся на уровне страниц версии через
`document_version_pages.metadataHistoryId`. Уникальность
`(documentId, versionNumber)`.

### document_version_pages

Страницы версии документа. Columns: `id`, `versionId`, `pageId`,
`metadataHistoryId`, `pageNumber`, `pageSha256Hash`, `isPrimary`, `createdAt`.
Notes: связь с `document_versions`, `document_pages` и snapshot-метаданными
страницы в `file_metadata_history`. Уникальность `(versionId, pageNumber)` и
`(versionId, pageId)`, частичный unique-index ограничивает одну primary-
страницу на версию.

### file_items

Элементы типа "Файл". Columns: `itemId`, `metadataId`. Notes: Связь с
`FileMetadata`.

### file_metadata

Технические данные файлов. Columns: `id`, `fileName`, `fileExtension`,
`filePath`, `mimeType`, `fileSize`, `sha256`, `availabilityStatus`,
`integrityStatus`, `missingDetectedAt`, `deletedAt`, `lastIntegrityCheckAt`.
Notes: Реальный относительный путь и хеш файла. `sha256` — SHA-256 хэш для
проверки целостности. `availabilityStatus`: `available`, `missing`, `deleted`.
`integrityStatus`: `unknown`, `valid`, `corrupted`. Для missing/deleted
состояний обязательны соответствующие timestamp-поля.

### file_metadata_history

Snapshot технических данных файлов. Columns: `id`, `historyId`, `ownerKind`,
`ownerId`, `metadataId`, `fileName`, `fileExtension`, `filePath`, `mimeType`,
`fileSize`, `sha256`, `availabilityStatus`, `integrityStatus`,
`missingDetectedAt`, `deletedAt`, `lastIntegrityCheckAt`, `snapshotCreatedAt`.
Notes: `metadataId` не является FK, чтобы snapshot сохранялся после замены или
удаления текущих `file_metadata`; `historyId` опционально связывает snapshot с
`vault_snapshots_history`. `ownerKind` задаёт непосредственного владельца
snapshot: `fileItemHistory` или `documentVersionPage`. `ownerId` обязателен для
всех типов. Для `fileItemHistory` `ownerId` должен совпадать с `historyId`.

### contact_items

Контактные данные. Columns: `itemId`, `firstName`, `middleName`, `lastName`,
`phone`, `email`, `company`, `jobTitle`, `address`, `website`, `birthday`,
`isEmergencyContact`. Notes: Имя обязательно, фамилия и отчество optional.

### api_key_items

API ключи. Columns: `itemId`, `service`, `key`, `tokenType`, `tokenTypeOther`,
`environment`, `environmentOther`, `expiresAt`, `revoked`, `revokedAt`,
`rotationPeriodDays`, `lastRotatedAt`, `scopesText`, `owner`, `baseUrl`. Notes:
`tokenType` — `ApiKeyTokenType { apiKey, bearer, jwt, pat, webhook, other }`,
`environment` —
`ApiKeyEnvironment { development, staging, production, testing, local, other }`.
`scopesText` хранит scopes через один пробел; `revokedAt` фиксирует время
отзыва.

### ssh_key_items

SSH ключи. Columns: `itemId`, `publicKey`, `privateKey`, `keyType`,
`keyTypeOther`, `keySize`. Notes: Файлы ключей привязываются через `item_links`.
`publicKey` и `privateKey` nullable, но хотя бы одно из полей должно быть
заполнено. `SshKeyType { rsa, ed25519, ecdsa, dsa, other }`.

### certificate_items

Сертификаты. Columns: `itemId`, `certificateFormat`, `certificateFormatOther`,
`certificatePem`, `certificateBlob`, `privateKey`, `privateKeyPassword`,
`passwordForPfx`, `keyAlgorithm`, `keyAlgorithmOther`, `keySize`,
`serialNumber`, `issuer`, `subject`, `validFrom`, `validTo`. Notes: Поддержка
PEM и бинарных форматов. Внешние файлы привязываются через `item_links`.
`CertificateFormat { pem, der, pfx, pkcs12, other }`,
`CertificateKeyAlgorithm { rsa, ecdsa, ed25519, dsa, other }`.

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

Данные Wi-Fi сетей. Columns: `itemId`, `ssid`, `password`, `securityType`,
`securityTypeOther`, `encryption`, `encryptionOther`, `hiddenSsid`. Notes:
Поддержка Enterprise-сетей через `securityType` (`wpaEnterprise`,
`wpa2Enterprise`, `wpa3Enterprise`) и отдельный `encryption` enum.
`WifiSecurityType { open, wep, wpa, wpa2, wpa3, wpaEnterprise, wpa2Enterprise, wpa3Enterprise, other }`,
`WifiEncryptionType { none, wep, tkip, aes, ccmp, gcmp, other }`.

### identity_items

Личные данные и удостоверения личности. Columns: `itemId`, `firstName`,
`middleName`, `lastName`, `displayName`, `username`, `email`, `phone`,
`address`, `birthday`, `company`, `jobTitle`, `website`, `taxId`, `nationalId`,
`passportNumber`, `driverLicenseNumber`. Notes: Универсальная таблица для
профилей и данных документов. Обязательна проверка на наличие хотя бы одного
идентифицирующего поля (имя, email, телефон или компания).

### license_key_items

Лицензионные ключи. Columns: `itemId`, `productName`, `vendor`, `licenseKey`,
`licenseType`, `licenseTypeOther`, `accountEmail`, `accountUsername`,
`purchaseEmail`, `orderNumber`, `purchaseDate`, `purchasePrice`, `currency`,
`validFrom`, `validTo`, `renewalDate`, `seats`, `activationLimit`,
`activationsUsed`. Notes: `licenseKey` — secret; ротация и история
оплаты/аккаунта хранятся прямо в таблице.
`LicenseType { perpetual, subscription, trial, volume, oem, educational, openSource, other }`.

### recovery_codes_items

Группы кодов восстановления. Columns: `itemId`, `codesCount`, `usedCount`,
`generatedAt`, `oneTime`. Notes: кэширует количество кодов из таблицы
`recovery_codes` через триггеры.

### recovery_codes

Отдельные коды восстановления. Columns: `id`, `itemId`, `code`, `used`,
`usedAt`, `position`. Notes: связь с `recovery_codes_items`. Уникальность по
`(itemId, position)`. Позиция кодов начинается с 0.

### recovery_code_values_history

Snapshot отдельных recovery codes. Columns: `id`, `historyId`, `originalCodeId`,
`code`, `used`, `usedAt`, `position`. Notes: позволяет полностью восстанавливать
набор кодов из истории. Immutability обеспечивается триггером.

### loyalty_card_items

Карты лояльности. Columns: `itemId`, `programName`, `cardNumber`,
`barcodeValue`, `password`, `barcodeType`, `barcodeTypeOther`, `issuer`,
`website`, `phone`, `email`, `validFrom`, `validTo`. Notes: поддержка различных
типов штрихкодов.
`LoyaltyBarcodeType { code128, code39, ean13, ean8, upcA, upcE, qr, pdf417, aztec, dataMatrix, other }`.

## History Tables

Таблицы для хранения истории специфических полей. Колонки соответствуют
item-таблицам (часто nullable для возможности частичного сохранения).

- **api_key_history**: `historyId`, `service`, `key`, `tokenType`,
  `tokenTypeOther`, `environment`, `environmentOther`, `expiresAt`, `revoked`,
  `revokedAt`, `rotationPeriodDays`, `lastRotatedAt`, `scopesText`, `owner`,
  `baseUrl`.
- **bank_card_history**: `historyId`, `cardholderName`, `cardNumber`,
  `cardType`, `cardTypeOther`, `cardNetwork`, `cardNetworkOther`, `expiryMonth`,
  `expiryYear`, `cvv`, `bankName`, `accountNumber`, `routingNumber`.
- **certificate_history**: `historyId`, `certificateFormat`,
  `certificateFormatOther`, `certificatePem`, `certificateBlob`, `privateKey`,
  `privateKeyPassword`, `passwordForPfx`, `keyAlgorithm`, `keyAlgorithmOther`,
  `keySize`, `serialNumber`, `issuer`, `subject`, `validFrom`, `validTo`.
- **contact_history**: `historyId`, `firstName`, `middleName`, `lastName`,
  `phone`, `email`, `company`, `jobTitle`, `address`, `website`, `birthday`,
  `isEmergencyContact`.
- **crypto_wallet_history**: `historyId`, `walletType`, `walletTypeOther`,
  `network`, `networkOther`, `mnemonic`, `privateKey`, `derivationPath`,
  `derivationScheme`, `derivationSchemeOther`, `addresses`, `xpub`, `xprv`,
  `hardwareDevice`, `watchOnly`.
- **file_history**: `historyId`, `metadataHistoryId`.
- **file_metadata_history**: `id`, `historyId`, `ownerKind`, `ownerId`,
  `metadataId`, `fileName`, `fileExtension`, `filePath`, `mimeType`, `fileSize`,
  `sha256`, `availabilityStatus`, `integrityStatus`, `missingDetectedAt`,
  `deletedAt`, `lastIntegrityCheckAt`, `snapshotCreatedAt`.
- **item_link_history**: `id`, `historyId`, `sourceLinkId`, `sourceItemId`,
  `targetItemId`, `relationType`, `relationTypeOther`, `label`, `sortOrder`,
  `createdAt`, `modifiedAt`, `snapshotId`, `snapshotCreatedAt`.
- **identity_history**: `historyId`, `firstName`, `middleName`, `lastName`,
  `displayName`, `username`, `email`, `phone`, `address`, `birthday`, `company`,
  `jobTitle`, `website`, `taxId`, `nationalId`, `passportNumber`,
  `driverLicenseNumber`.
- **license_key_history**: `historyId`, `productName`, `vendor`, `licenseKey`,
  `licenseType`, `licenseTypeOther`, `accountEmail`, `accountUsername`,
  `purchaseEmail`, `orderNumber`, `purchaseDate`, `purchasePrice`, `currency`,
  `validFrom`, `validTo`, `renewalDate`, `seats`, `activationLimit`,
  `activationsUsed`.
- **loyalty_card_history**: `historyId`, `programName`, `cardNumber`,
  `barcodeValue`, `password`, `barcodeType`, `barcodeTypeOther`, `issuer`,
  `website`, `phone`, `email`, `validFrom`, `validTo`.
- **note_history**: `historyId`, `deltaJson`, `content`.
- **otp_history**: `historyId`, `type`, `issuer`, `accountName`, `secret`,
  `algorithm`, `digits`, `period`, `counter`.
- **password_history**: `historyId`, `login`, `email`, `password`, `url`,
  `expiresAt`.
- **recovery_codes_history**: `historyId`, `codesCount`, `usedCount`,
  `generatedAt`, `oneTime`.
- **ssh_key_history**: `historyId`, `publicKey`, `privateKey`, `keyType`,
  `keyTypeOther`, `keySize`.
- **wifi_history**: `historyId`, `ssid`, `password`, `securityType`,
  `securityTypeOther`, `encryption`, `encryptionOther`, `hiddenSsid`.

## System Tables

Системные таблицы хранилища.

### store_meta

Метаданные текущего хранилища (Singleton). Columns: `singletonId`, `id`, `name`,
`description`, `passwordHash`, `attachmentKey`, `createdAt`, `modifiedAt`,
`lastOpenedAt`. Notes: содержит ровно одну строку (`singletonId = 1`). `id` —
глобальный UUID хранилища.

### store_settings

Настройки хранилища. Columns: `key`, `value`, `valueType`, `description`,
`createdAt`, `modifiedAt`. Notes: PK — `key`. `valueType` —
`StoreSettingValueType`.

### Формат цветов Цвета в таблицах `categories`, `icon_refs`, `tags` хранятся в формате `AARRGGBB` (альфа, красный, зеленый, синий) в виде строки без `#`.
