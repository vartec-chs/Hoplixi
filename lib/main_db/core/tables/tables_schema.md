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
непустое имя.

### vault_item_history

Таблица истории изменений базовых полей элементов. Columns: `id`, `itemId`,
`action`, `type`, `name`, `description`, `categoryId`, `iconRefId`, `usedCount`,
`isFavorite`, `isArchived`, `isPinned`, `isDeleted`, `createdAt`, `modifiedAt`,
`recentScore`, `lastUsedAt`, `historyCreatedAt`. Notes: Снимок состояния
`vault_items` на момент действия `action` (`VaultItemHistoryAction`).

### vault_item_custom_fields

Кастомные поля элементов. Columns: `id`, `itemId`, `label`, `value`,
`fieldType`, `fieldTypeOther`, `sortOrder`. Notes: Связь с `vault_items`
(Cascade). `fieldType` — `CustomFieldType`.

### vault_item_custom_fields_history

История кастомных полей. Columns: `id`, `historyId`, `originalFieldId`, `label`,
`value`, `fieldType`, `fieldTypeOther`, `sortOrder`. Notes: Связь с
`vault_item_history`. Хранит снимки кастомных полей.

## Classification and Link Tables

Таблицы для организации, группировки и ресурсов.

### categories

Древовидные категории. Columns: `id`, `name`, `description`, `iconRefId`,
`color`, `type`, `parentId`, `createdAt`, `modifiedAt`. Notes: `color` в формате
`AARRGGBB`. `type` — `CategoryType`. Рекурсивная связь через `parentId`.

### tags

Теги для классификации. Columns: `id`, `name`, `color`, `type`, `createdAt`,
`modifiedAt`. Notes: Уникальность по `(name, type)`.

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

### icon_refs

Ссылки на иконки (встроенные, из паков или пользовательские). Columns: `id`,
`iconSourceType`, `iconPackId`, `iconValue`, `customIconId`, `color`,
`backgroundColor`, `createdAt`, `modifiedAt`. Notes: Сложная валидация источника
иконки через CHECK. Уникальные индексы для разных типов источников.

### custom_icons

Пользовательские иконки (бинарные данные). Columns: `id`, `name`, `format`,
`data`, `createdAt`, `modifiedAt`. Notes: `data` — Blob. `format` —
`CustomIconFormat`.

## Entity-specific Items

Таблицы со специфическими полями для каждого типа элемента.

### password_items

Поля паролей. Columns: `itemId`, `login`, `email`, `password`, `url`,
`expiresAt`. Notes: PK — `itemId` (FK к `vault_items`).

### otp_items

Поля одноразовых паролей (OTP). Columns: `itemId`, `type`, `issuer`,
`accountName`, `secret`, `algorithm`, `digits`, `period`, `counter`. Notes:
`secret` хранится как Blob. Все связи с паролями вынесены в `item_links`
(`otpForPassword`).

### note_items

Содержимое заметок. Columns: `itemId`, `deltaJson`, `content`. Notes:
`deltaJson` хранит Quill Delta формат. `content` — чистый текст для превью.

### bank_card_items

Банковские карты. Columns: `itemId`, `cardholderName`, `cardNumber`, `cardType`,
`cardTypeOther`, `cardNetwork`, `cardNetworkOther`, `expiryMonth`, `expiryYear`,
`cvv`, `bankName`, `accountNumber`, `routingNumber`. Notes: Месяц и год хранятся
как строки `MM` и `YYYY`.

### document_items

Метаданные документов. Columns: `itemId`, `documentType`, `documentTypeOther`,
`aggregatedText`, `aggregateHash`, `pageCount`. Notes: `aggregatedText` — весь
OCR текст документа.

### document_pages

Страницы документа. Columns: `id`, `documentId`, `metadataId`, `pageNumber`,
`extractedText`, `pageHash`, `isPrimary`, `usedCount`, `createdAt`,
`modifiedAt`, `lastUsedAt`. Notes: Связь с `FileMetadata`. Уникальность
`(documentId, pageNumber)`.

### file_items

Элементы типа "Файл". Columns: `itemId`, `metadataId`. Notes: Связь с
`FileMetadata`.

### file_metadata

Технические данные файлов. Columns: `id`, `fileName`, `fileExtension`,
`filePath`, `mimeType`, `fileSize`, `fileHash`. Notes: Реальный путь
и хеш файла.

### contact_items

Контактные данные. Columns: `itemId`, `phone`, `email`, `company`, `jobTitle`,
`address`, `website`, `birthday`, `isEmergencyContact`. Notes: Простое хранение
адреса строкой.

### api_key_items

API ключи. Columns: `itemId`, `service`, `key`, `tokenType`, `tokenTypeOther`,
`environment`, `environmentOther`, `expiresAt`, `revoked`, `rotationPeriodDays`,
`lastRotatedAt`, `scopes`, `owner`, `baseUrl`. Notes: Поддержка ротации и
различных окружений.

### ssh_key_items

SSH ключи. Columns: `itemId`, `publicKey`, `privateKey`, `keyType`,
`keyTypeOther`, `keySize`, `fingerprint`, `createdBy`, `addedToAgent`, `usage`.
Notes: Хранение ключа и его отпечатка. Файлы ключей привязываются через
`item_links`.

### certificate_items

Сертификаты. Columns: `itemId`, `certificateFormat`, `certificateFormatOther`,
`certificatePem`, `certificateBlob`, `privateKey`, `privateKeyPassword`,
`passwordForPfx`, `keyAlgorithm`, `keyAlgorithmOther`, `keySize`,
`serialNumber`, `issuer`, `subject`, `validFrom`, `validTo`, `ocspUrl`,
`crlUrl`. Notes: Поддержка PEM и бинарных форматов. Внешние файлы привязываются
через `item_links`.

### crypto_wallet_items

Криптокошельки. Columns: `itemId`, `walletType`, `walletTypeOther`, `network`,
`networkOther`, `mnemonic`, `privateKey`, `derivationPath`, `derivationScheme`,
`derivationSchemeOther`, `addresses`, `xpub`, `xprv`, `hardwareDevice`,
`watchOnly`. Notes: Поддержка сид-фраз, ключей и путей деривации.

### wifi_items

Данные Wi-Fi сетей. Columns: `itemId`, `ssid`, `password`, `security`,
`securityOther`, `hidden`, `username`. Notes: Поддержка Enterprise (WPA/WPA2)
через поле `username`.

### identity_items

Удостоверения личности. Columns: `itemId`, `idType`, `idTypeOther`, `idNumber`,
`fullName`, `dateOfBirth`, `placeOfBirth`, `nationality`, `issuingAuthority`,
`issueDate`, `expiryDate`, `mrz`, `verified`. Notes: Сканы и фото привязываются
через `item_links` (`identityScan`, `identityPhoto`).

### license_key_items

Лицензионные ключи. Columns: `itemId`, `product`, `licenseKey`, `licenseType`,
`licenseTypeOther`, `seats`, `maxActivations`, `activatedOn`, `purchaseDate`,
`purchaseFrom`, `orderId`, `expiresAt`. Notes: Учет активаций и сроков.
Документы покупки и контакты поддержки — через `item_links`.

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
штрихкодов.

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
- **document_history**: `historyId`, `documentType`, `documentTypeOther`,
  `aggregatedText`, `aggregateHash`, `pageCount`.
- **file_history**: `historyId`, `metadataId`.
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
