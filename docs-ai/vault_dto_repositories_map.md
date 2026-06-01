# Карта DTO и Репозиториев VaultDB (Hoplixi)

В данном документе собрана исчерпывающая информация о структурах данных (Data DTO) и сигнатурах методов всех репозиториев, используемых в модуле базы данных хранилища (`vault_db`).

---

## 1. Карта полей для Data DTO
*(DTO паролей и OTP исключены согласно запросу)*

### 1.1 `ApiKeyDataDto` (в `api_key_dto.dart`)
Служит для хранения данных API-ключей.
* **`service`** (`String`, `required`) — Название сервиса.
* **`key`** (`String`, `required`) — Сам API-ключ.
* **`tokenType`** (`ApiKeyTokenType?`) — Тип токена (enum).
* **`tokenTypeOther`** (`String?`) — Другой тип токена, если выбран вариант "Other".
* **`environment`** (`ApiKeyEnvironment?`) — Среда использования (enum).
* **`environmentOther`** (`String?`) — Другая среда использования, если выбран вариант "Other".
* **`expiresAt`** (`DateTime?`) — Дата и время истечения срока действия.
* **`revokedAt`** (`DateTime?`) — Дата и время отзыва ключа.
* **`rotationPeriodDays`** (`int?`) — Период ротации ключа в днях.
* **`lastRotatedAt`** (`DateTime?`) — Дата и время последней ротации ключа.
* **`owner`** (`String?`) — Владелец ключа.
* **`baseUrl`** (`String?`) — Базовый URL сервиса.
* **`scopesText`** (`String?`) — Список разрешений (scopes) в текстовом виде.

### 1.2 `BankCardDataDto` (в `bank_card_dto.dart`)
Используется для хранения данных банковских карт.
* **`cardholderName`** (`String?`) — Имя держателя карты.
* **`cardNumber`** (`String`, `required`) — Номер банковской карты.
* **`cardType`** (`CardType?`) — Тип карты (enum: дебетовая, кредитная и т.д.).
* **`cardTypeOther`** (`String?`) — Свой тип карты, если выбран вариант "Other".
* **`cardNetwork`** (`CardNetwork?`) — Платежная система (enum: Visa, Mastercard и т.д.).
* **`cardNetworkOther`** (`String?`) — Своя платежная система, если выбран вариант "Other".
* **`expiryMonth`** (`String?`) — Месяц истечения срока действия (MM).
* **`expiryYear`** (`String?`) — Год истечения срока действия (YYYY).
* **`cvv`** (`String?`) — Код CVV/CVC.
* **`bankName`** (`String?`) — Название банка-эмитента.
* **`accountNumber`** (`String?`) — Номер счета.
* **`routingNumber`** (`String?`) — Маршрутный номер (БИК).

### 1.3 `CertificateDataDto` (в `certificate_dto.dart`)
Используется для хранения SSL/TLS сертификатов и ключей.
* **`certificateFormat`** (`CertificateFormat?`) — Формат сертификата (enum).
* **`certificateFormatOther`** (`String?`) — Другой формат сертификата.
* **`certificatePem`** (`String?`) — Содержимое сертификата в формате PEM.
* **`certificateBlob`** (`Uint8List?`, с конвертером `@NullableUint8ListBase64Converter()`) — Бинарное содержимое сертификата.
* **`privateKey`** (`String?`) — Закрытый ключ.
* **`privateKeyPassword`** (`String?`) — Пароль от закрытого ключа.
* **`passwordForPfx`** (`String?`) — Пароль для PFX/P12 контейнера.
* **`keyAlgorithm`** (`CertificateKeyAlgorithm?`) — Алгоритм ключа (enum).
* **`keyAlgorithmOther`** (`String?`) — Другой алгоритм ключа.
* **`keySize`** (`int?`) — Размер ключа (в битах).
* **`serialNumber`** (`String?`) — Серийный номер сертификата.
* **`issuer`** (`String?`) — Кем выдан (Issuer).
* **`subject`** (`String?`) — Субъект сертификата (Subject).
* **`validFrom`** (`DateTime?`) — Действителен с.
* **`validTo`** (`DateTime?`) — Действителен по.

### 1.4 `ContactDataDto` (в `contact_dto.dart`)
Хранение контактных данных физических лиц.
* **`firstName`** (`String`, `required`) — Имя.
* **`middleName`** (`String?`) — Отчество.
* **`lastName`** (`String?`) — Фамилия.
* **`phone`** (`String?`) — Телефон.
* **`email`** (`String?`) — Адрес электронной почты.
* **`company`** (`String?`) — Компания.
* **`jobTitle`** (`String?`) — Должность.
* **`address`** (`String?`) — Адрес проживания/работы.
* **`website`** (`String?`) — Веб-сайт.
* **`birthday`** (`DateTime?`) — Дата рождения.
* **`isEmergencyContact`** (`bool`, `@Default(false)`) — Является ли экстренным контактом.

### 1.5 `CryptoWalletDataDto` (в `crypto_wallet_dto.dart`)
Хранение данных криптовалютных кошельков.
* **`walletType`** (`CryptoWalletType?`) — Тип кошелька (enum: десктопный, аппаратный и т.д.).
* **`walletTypeOther`** (`String?`) — Другой тип кошелька.
* **`network`** (`CryptoNetwork?`) — Криптовалютная сеть (enum).
* **`networkOther`** (`String?`) — Другая сеть.
* **`mnemonic`** (`String?`) — Мнемоническая фраза (seed-фраза).
* **`privateKey`** (`String?`) — Закрытый ключ кошелька.
* **`derivationPath`** (`String?`) — Путь деривации (например, `m/44'/60'/0'/0/0`).
* **`derivationScheme`** (`CryptoDerivationScheme?`) — Схема деривации (enum).
* **`derivationSchemeOther`** (`String?`) — Другая схема деривации.
* **`addresses`** (`String?`) — Адреса кошелька.
* **`xpub`** (`String?`) — Публичный расширенный ключ (xpub/ypub/zpub).
* **`xprv`** (`String?`) — Приватный расширенный ключ (xprv).
* **`hardwareDevice`** (`String?`) — Название аппаратного устройства (если применимо).
* **`watchOnly`** (`bool`, `@Default(false)`) — Является ли кошелек только для наблюдения (без приватных ключей).

### 1.6 `DocumentDataDto` (в `document_dto.dart`)
Хранение информации о зашифрованном документе.
* **`currentVersionId`** (`String?`) — Идентификатор текущей версии документа.

### 1.7 `DocumentPageDataDto` (в `document_dto.dart`)
Метаданные страницы документа.
* **`documentId`** (`String`, `required`) — ID родительского документа.
* **`currentVersionPageId`** (`String?`) — ID страницы текущей версии.

### 1.8 `CreateDocumentVersionPageDto` (в `document_version_dto.dart`)
*(Обычный Dart класс, не Freezed)*
* **`id`** (`String?`) — Идентификатор страницы версии (если null, генерируется UUID).
* **`pageId`** (`String?`) — Стабильный `document_pages.id` (если null, создается новая запись).
* **`metadataHistoryId`** (`String?`) — ID истории метаданных.
* **`pageNumber`** (`int`, `required`) — Порядковый номер страницы.
* **`pageSha256Hash`** (`String?`) — Хэш SHA-256 содержимого страницы.
* **`isPrimary`** (`bool`, `default false`) — Является ли страница основной/первой.

### 1.9 `CreateDocumentVersionDto` (в `document_version_dto.dart`)
*(Обычный Dart класс, не Freezed)*
* **`documentId`** (`String`, `required`) — Идентификатор документа.
* **`historyId`** (`String?`) — Идентификатор истории изменений.
* **`documentType`** (`DocumentType?`) — Тип документа (enum).
* **`documentTypeOther`** (`String?`) — Другой тип документа.
* **`aggregateSha256Hash`** (`String?`) — Агрегированный хэш всех страниц версии.
* **`pages`** (`List<CreateDocumentVersionPageDto>`, `required`) — Список создаваемых страниц.
* **`activate`** (`bool`, `default true`) — Сделать ли эту версию активной (текущей).

### 1.10 `FileDataDto` (в `file_dto.dart`)
Хранение информации о файле в хранилище.
* **`metadataId`** (`String?`) — ID метаданных файла.

### 1.11 `FileMetadataDataDto` (в `file_dto.dart`)
Метаданные загруженного файла.
* **`fileName`** (`String`, `required`) — Имя файла.
* **`fileExtension`** (`String?`) — Расширение файла.
* **`filePath`** (`String?`) — Путь к файлу (если применимо).
* **`mimeType`** (`String`, `required`) — MIME-тип файла.
* **`fileSize`** (`int`, `required`) — Размер файла в байтах.
* **`sha256`** (`String?`) — SHA-256 хэш файла.
* **`availabilityStatus`** (`FileAvailabilityStatus`, `@Default(FileAvailabilityStatus.available)`) — Статус доступности файла (доступен, отсутствует и др.).
* **`integrityStatus`** (`FileIntegrityStatus`, `@Default(FileIntegrityStatus.unknown)`) — Статус целостности файла.
* **`missingDetectedAt`** (`DateTime?`) — Дата обнаружения отсутствия файла.
* **`deletedAt`** (`DateTime?`) — Дата удаления файла.
* **`lastIntegrityCheckAt`** (`DateTime?`) — Дата последней проверки целостности.

### 1.12 `FileMetadataDto` (в `file_metadata_dto.dart`)
Самостоятельный DTO для метаданных файла.
* **`id`** (`String?`) — Идентификатор метаданных.
* **`fileName`** (`String`, `required`) — Имя файла.
* **`fileExtension`** (`String?`) — Расширение файла.
* **`filePath`** (`String?`) — Путь к файлу.
* **`mimeType`** (`String`, `required`) — MIME-тип.
* **`fileSize`** (`int`, `required`) — Размер в байтах.
* **`sha256`** (`String?`) — SHA-256 хэш.
* **`availabilityStatus`** (`FileAvailabilityStatus`, `@Default(FileAvailabilityStatus.available)`) — Статус доступности.
* **`integrityStatus`** (`FileIntegrityStatus`, `@Default(FileIntegrityStatus.unknown)`) — Status целостности.
* **`missingDetectedAt`** (`DateTime?`) — Время обнаружения пропажи.
* **`deletedAt`** (`DateTime?`) — Время удаления.
* **`lastIntegrityCheckAt`** (`DateTime?`) — Время последней проверки целостности.

### 1.13 `CategoryInCardDto` (в `filter_meta_dto.dart`)
Информация о категории внутри карточки элемента.
* **`id`** (`String`, `required`) — Идентификатор категории.
* **`name`** (`String`, `required`) — Название категории.
* **`color`** (`int?`) — Цвет категории.
* **`iconRefId`** (`String?`) — Ссылка на иконку.

### 1.14 `TagInCardDto` (в `filter_meta_dto.dart`)
Информация о теге внутри карточки элемента.
* **`id`** (`String`, `required`) — Идентификатор тега.
* **`name`** (`String`, `required`) — Название тега.
* **`color`** (`int?`) — Цвет тега.

### 1.15 `IdentityDataDto` (в `identity_dto.dart`)
Хранение данных удостоверений личности (профилей/паспортов).
* **`firstName`** (`String?`) — Имя.
* **`middleName`** (`String?`) — Отчество.
* **`lastName`** (`String?`) — Фамилия.
* **`displayName`** (`String?`) — Отображаемое имя контакта.
* **`username`** (`String?`) — Имя пользователя.
* **`email`** (`String?`) — Email.
* **`phone`** (`String?`) — Номер телефона.
* **`address`** (`String?`) — Адрес.
* **`birthday`** (`DateTime?`) — Дата рождения.
* **`company`** (`String?`) — Организация.
* **`jobTitle`** (`String?`) — Должность.
* **`website`** (`String?`) — Личный сайт.
* **`taxId`** (`String?`) — ИНН/Налоговый номер.
* **`nationalId`** (`String?`) — СНИЛС / Национальный ID.
* **`passportNumber`** (`String?`) — Номер паспорта.
* **`driverLicenseNumber`** (`String?`) — Номер водительского удостоверения.

### 1.16 `LicenseKeyDataDto` (в `license_key_dto.dart`)
Хранение лицензионных ключей программного обеспечения.
* **`productName`** (`String`, `required`) — Название программного продукта.
* **`vendor`** (`String?`) — Разработчик/Производитель.
* **`licenseKey`** (`String`, `required`) — Сам лицензионный ключ.
* **`licenseType`** (`LicenseType?`) — Тип лицензии (enum).
* **`licenseTypeOther`** (`String?`) — Другой тип лицензии.
* **`accountEmail`** (`String?`) — Email аккаунта лицензии.
* **`accountUsername`** (`String?`) — Имя пользователя аккаунта.
* **`purchaseEmail`** (`String?`) — Email, указанный при покупке.
* **`orderNumber`** (`String?`) — Номер заказа.
* **`purchaseDate`** (`DateTime?`) — Дата покупки.
* **`purchasePrice`** (`double?`) — Стоимость покупки.
* **`currency`** (`String?`) — Валюта покупки.
* **`validFrom`** (`DateTime?`) — Действует с.
* **`validTo`** (`DateTime?`) — Действует по (дата окончания лицензии).
* **`renewalDate`** (`DateTime?`) — Дата продления.
* **`seats`** (`int?`) — Количество рабочих мест (лицензий).
* **`activationLimit`** (`int?`) — Лимит активаций.
* **`activationsUsed`** (`int?`) — Использовано активаций.

### 1.17 `LoyaltyCardDataDto` (в `loyalty_card_dto.dart`)
Хранение данных карт лояльности и скидочных карт.
* **`programName`** (`String`, `required`) — Название программы лояльности.
* **`cardNumber`** (`String?`) — Номер карты.
* **`barcodeValue`** (`String?`) — Значение штрих-кода.
* **`password`** (`String?`) — Пароль/ПИН-код от личного кабинета карты.
* **`barcodeType`** (`LoyaltyBarcodeType?`) — Тип штрих-кода (enum: QR, EAN и др.).
* **`barcodeTypeOther`** (`String?`) — Другой тип штрих-кода.
* **`issuer`** (`String?`) — Эмитент карты.
* **`website`** (`String?`) — Сайт программы лояльности.
* **`phone`** (`String?`) — Телефон поддержки.
* **`email`** (`String?`) — Электронная почта.
* **`validFrom`** (`DateTime?`) — Действует с.
* **`validTo`** (`DateTime?`) — Действует по.

### 1.18 `NoteDataDto` (в `note_dto.dart`)
Хранение безопасных текстовых заметок.
* **`deltaJson`** (`String`, `required`) — Форматированный текст заметки в JSON-формате Quill Delta.
* **`content`** (`String`, `required`) — Чистый текстовый контент заметки для быстрого поиска и отображения.

### 1.19 `RecoveryCodesDataDto` (в `recovery_codes_dto.dart`)
Хранение метаданных кодов восстановления (2FA/MFA).
* **`generatedAt`** (`DateTime?`) — Дата генерации кодов.
* **`oneTime`** (`bool`, `@Default(false)`) — Являются ли коды одноразовыми.

### 1.20 `RecoveryCodeValueDto` (в `recovery_codes_dto.dart`)
Модель конкретного значения кода восстановления.
* **`id`** (`int?`) — Уникальный ID записи.
* **`code`** (`String`, `required`) — Сам секретный код восстановления.
* **`used`** (`bool`, `@Default(false)`) — Флаг использования кода.
* **`usedAt`** (`DateTime?`) — Дата и время использования.
* **`position`** (`int?`) — Порядковый номер/позиция кода в списке.

### 1.21 `SshKeyDataDto` (в `ssh_key_dto.dart`)
Хранение приватных и публичных SSH-ключей.
* **`publicKey`** (`String?`) — Публичный SSH-ключ.
* **`privateKey`** (`String?`) — Приватный SSH-ключ.
* **`keyType`** (`SshKeyType?`) — Тип ключа (enum: RSA, ED25519 и др.).
* **`keyTypeOther`** (`String?`) — Другой тип ключа.
* **`keySize`** (`int?`) — Длина/размер ключа в битах.

### 1.22 `VaultItemCreateDto` (в `vault_item_base_dto.dart`)
Базовый DTO для создания любого элемента в сейфе.
* **`name`** (`String`, `required`) — Название элемента.
* **`description`** (`String?`) — Описание.
* **`categoryId`** (`String?`) — ID категории.
* **`iconRefId`** (`String?`) — ID ссылки на иконку.
* **`isFavorite`** (`bool`, `@Default(false)`) — Добавить в избранное.
* **`isPinned`** (`bool`, `@Default(false)`) — Закрепить сверху.

### 1.23 `WifiDataDto` (в `wifi_dto.dart`)
Хранение учетных данных беспроводных сетей Wi-Fi.
* **`ssid`** (`String`, `required`) — Имя сети (SSID).
* **`password`** (`String?`) — Пароль от Wi-Fi сети.
* **`securityType`** (`WifiSecurityType?`) — Тип безопасности (enum: WPA2, WPA3 и др.).
* **`securityTypeOther`** (`String?`) — Другой тип безопасности.
* **`encryption`** (`WifiEncryptionType?`) — Тип шифрования (enum: AES, TKIP).
* **`encryptionOther`** (`String?`) — Другой тип шифрования.
* **`hiddenSsid`** (`bool`, `@Default(false)`) — Является ли сеть скрытой.

---

## 2. Карта методов репозиториев

Все репозитории возвращают результат операций обернутым в `AsyncDBResult<T>`, который является алиасом для `Future<Result<T, DBCoreError>>`.

### 2.1 CRUD-репозитории сущностей сейфа
* `ApiKeyRepository`
* `BankCardRepository`
* `CertificateRepository`
* `ContactRepository`
* `CryptoWalletRepository`
* `DocumentRepository`
* `FileRepository`
* `IdentityRepository`
* `LicenseKeyRepository`
* `LoyaltyCardRepository`
* `NoteRepository`
* `SshKeyRepository`
* `WifiRepository`

**Методы:**
1. `create(Create[Entity]Dto dto)` — Создает элемент в сейфе.
2. `update(Patch[Entity]Dto dto)` — Обновляет поля базового элемента и сущности.
3. `getViewById(String itemId)` — Возвращает подробное представление (`[Entity]ViewDto`).
4. `getCardById(String itemId)` — Возвращает компактную карточку (`[Entity]CardDto`).
5. `getCards({int limit = 50, int offset = 0})` — Постранично возвращает список карточек.
6. `deletePermanently(String itemId)` — Окончательно удаляет элемент.
