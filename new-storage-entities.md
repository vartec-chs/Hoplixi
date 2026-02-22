# Новые типы сущностей для хранения в секрете

## ApiKey [ Добавлено ]

- service (Text) — обязательное, имя сервиса/API (github, stripe и т.п.).
- key (Text, encrypted) — обязательное, сам секрет/ключ (полное значение,
  зашифровать).
- maskedKey (Text) — опционально, маскированное отображение типа **\***abcd.
- scopes (Text / JSON) — опционально, список прав/скоупов.
- tokenType (Text) — опционально, например Bearer, HMAC, Basic.
- environment (Text) — опционально, prod|staging|dev.
- expiresAt (DateTime) — опционально, срок действия.
- createdBy (Text) — опционально, кто создал/откуда (email, device id).
- lastUsedIp (Text) — опционально, ip последнего использования.
- lastUsedUserAgent (Text) — опционально.
- revoked (Bool) — опционально, флаг отзыва.
- rotationPeriodDays (Int) — опционально, политика ротации.
- lastRotatedAt (DateTime) — опционально.
- metadata (Text / JSON) — опционально, произвольные данные (rate limits, owner
  id).

## SshKey [ Добавлено ]

- publicKey (Text) — обязательное/рекомендуемое, открытая часть (ssh-rsa ...).
- privateKey (Blob/Text, encrypted) — обязательное для хран. приватного ключа
  (шифрованно!).
- keyType (Text) — опционально, rsa|ed25519|ecdsa.
- keySize (Int) — опционально, длина в битах.
- passphraseHint (Text) — опционально, подсказка к фразе-паролю.
- comment (Text) — опционально, комментарий (например deploy@server).
- fingerprint (Text) — опционально, SHA256/MD5 отпечаток.
- createdBy (Text) — опционально.
- addedToAgent (Bool) — опционально, флаг.
- usage (Text) — опционально, куда используется (CI, deploy, login).
- publicKeyFileId / privateKeyFileId (Text refs) — опционально, ссылки на
  файлы/attachments.

## Certificate [ Добавлено ]

- certificatePem (Text / Blob, encrypted) — обязательное/рекомендуемое, PEM/DER
  сертификата.
- privateKey (Blob/Text, encrypted, nullable) — опционально, если импортирован с
  приватным ключом.
- serialNumber (Text) — опционально.
- issuer (Text) — опционально.
- subject (Text) — опционально.
- validFrom (DateTime) — опционально.
- validTo (DateTime) — опционально.
- fingerprint (Text) — опционально (sha1/sha256).
- keyUsage (Text / JSON) — опционально (digitalSignature, keyEncipherment ...).
- extensions (Text / JSON) — опционально.
- pfxBlob (Blob, encrypted) — опционально, если хранится PKCS#12.
- passwordForPfx (Text, encrypted) — опционально.
- ocspUrl / crlUrl (Text) — опционально.
- autoRenew (Bool) — опционально, флаг автообновления/напоминания.
- lastCheckedAt (DateTime) — опционально.

## CryptoWallet [ Добавлено ]

- walletType (Text) — обязательное/рекомендуемое, seed|private_key|hardware.
- mnemonic (Text, encrypted, nullable) — если seed-based; шифровать обязательно.
- privateKey (Text/Blob, encrypted, nullable) — для single-key wallets.
- derivationPath (Text) — опционально, e.g. m/44'/60'/0'/0/0.
- network (Text) — опционально, ethereum|bitcoin|solana|multi.
- addresses (Text / JSON) — опционально, список связанных адресов.
- xpub / xprv (Text, encrypted, nullable) — опционально.
- hardwareDevice (Text) — опционально, идентификатор HW wallet.
- lastBalanceCheckedAt (DateTime) — опционально.
- notesOnUsage (Text) — опционально.
- watchOnly (Bool) — опционально.
- derivationScheme (Text) — опционально (bip44/bip84/...).

## Wifi [ Добавлено ]

- ssid (Text) — обязательное.
- password (Text, encrypted, nullable) — опционально/для защищённых сетей.
- security (Text) — опционально, WPA2|WPA3|WEP|Open|WPA.
- hidden (Bool) — опционально.
- eapMethod (Text, nullable) — опционально для enterprise (PEAP, TLS).
- username (Text, nullable) — для EAP.
- identity (Text, nullable) — для EAP identity.
- domain (Text, nullable) — для enterprise.
- lastConnectedBssid (Text) — опционально, MAC точки доступа.
- priority (Int) — опционально, порядок соединения.
- notes (Text) — опционально.
- qrCodePayload (Text) — опционально, строка для quick connect.

## Identity (паспорт / ID / водительские и т.п.) [ Добавлено ]

- idType (Text) — обязательное, passport|id_card|drivers_license|ssn и т.п.
- idNumber (Text) — обязательное.
- fullName (Text) — опционально (если отличается от name).
- dateOfBirth (DateTime, nullable).
- placeOfBirth (Text, nullable).
- nationality (Text, nullable).
- issuingAuthority (Text, nullable).
- issueDate (DateTime, nullable).
- expiryDate (DateTime, nullable).
- mrz (Text, nullable) — machine readable zone для паспортов.
- scanAttachmentId (Text) — ссылка на скан/фото в attachments (шифровать).
- photoAttachmentId (Text) — отдельная фотография.
- notes (Text).
- verified (Bool) — опционально, флаг проверки/верификации.

## LicenseKey [ Добавлено ]

- product (Text) — обязательное, наименование продукта.
- licenseKey (Text, encrypted) — обязательное, сам ключ.
- licenseType (Text) — опционально, perpetual|subscription|trial.
- seats (Int, nullable) — опционально, число лицензий/мест.
- maxActivations (Int, nullable).
- activatedOn (DateTime, nullable) — дата первой активации.
- purchaseDate (DateTime, nullable).
- purchaseFrom (Text, nullable) — где куплено.
- orderId (Text, nullable).
- licenseFileId (Text) — файл лицензии (pdf/xml) (шифровать).
- expiresAt (DateTime, nullable).
- licenseNotes (Text).
- supportContact (Text) — контакты продавца/поддержки.

## RecoveryCodes

- codesBlob (Text / Blob, encrypted) — обязательное, список кодов (строка/JSON)
  — хранить зашифрованно.
- codesCount (Int) — опционально, общее количество.
- usedCount (Int) — опционально, сколько уже использовано.
- perCodeStatus (Text / JSON) — опционально, массив с флагами used/when
  (рекомендуется, либо хранить отдельной таблицей).
- generatedAt (DateTime) — опционально.
- notes (Text) — опционально.
- oneTime (Bool) — опционально, true если каждый код одноразовый.
- displayHint (Text) — опционально, как показывать пользователю (masking
  policy).
