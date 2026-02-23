// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Certificate PEM *`
  String get certificatePemLabel {
    return Intl.message(
      'Certificate PEM *',
      name: 'certificatePemLabel',
      desc: '',
      args: [],
    );
  }

  /// `Job title`
  String get jobTitleLabel {
    return Intl.message('Job title', name: 'jobTitleLabel', desc: '', args: []);
  }

  /// `Generated at (ISO8601)`
  String get generatedAtIsoLabel {
    return Intl.message(
      'Generated at (ISO8601)',
      name: 'generatedAtIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Key is empty`
  String get apiKeyEmpty {
    return Intl.message(
      'Key is empty',
      name: 'apiKeyEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Brief description`
  String get briefDescriptionHint {
    return Intl.message(
      'Brief description',
      name: 'briefDescriptionHint',
      desc: '',
      args: [],
    );
  }

  /// `Hidden network`
  String get wifiHiddenNetworkLabel {
    return Intl.message(
      'Hidden network',
      name: 'wifiHiddenNetworkLabel',
      desc: '',
      args: [],
    );
  }

  /// `Recovery codes created`
  String get recoveryCodesCreated {
    return Intl.message(
      'Recovery codes created',
      name: 'recoveryCodesCreated',
      desc: '',
      args: [],
    );
  }

  /// `Birth date (ISO8601)`
  String get birthDateIsoLabel {
    return Intl.message(
      'Birth date (ISO8601)',
      name: 'birthDateIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Hardware device`
  String get hardwareDeviceLabel {
    return Intl.message(
      'Hardware device',
      name: 'hardwareDeviceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Service *`
  String get apiKeyServiceLabel {
    return Intl.message(
      'Service *',
      name: 'apiKeyServiceLabel',
      desc: '',
      args: [],
    );
  }

  /// `New crypto wallet`
  String get newCryptoWallet {
    return Intl.message(
      'New crypto wallet',
      name: 'newCryptoWallet',
      desc: '',
      args: [],
    );
  }

  /// `Key type`
  String get keyTypeLabel {
    return Intl.message('Key type', name: 'keyTypeLabel', desc: '', args: []);
  }

  /// `Expiry date (ISO8601)`
  String get expiryDateIsoLabel {
    return Intl.message(
      'Expiry date (ISO8601)',
      name: 'expiryDateIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Per-code status JSON`
  String get perCodeStatusJsonLabel {
    return Intl.message(
      'Per-code status JSON',
      name: 'perCodeStatusJsonLabel',
      desc: '',
      args: [],
    );
  }

  /// `Wallet type *`
  String get walletTypeLabel {
    return Intl.message(
      'Wallet type *',
      name: 'walletTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter email`
  String get enterEmailHint {
    return Intl.message(
      'Enter email',
      name: 'enterEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `License updated`
  String get licenseUpdated {
    return Intl.message(
      'License updated',
      name: 'licenseUpdated',
      desc: '',
      args: [],
    );
  }

  /// `SSH key updated`
  String get sshKeyUpdated {
    return Intl.message(
      'SSH key updated',
      name: 'sshKeyUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Recovery codes updated`
  String get recoveryCodesUpdated {
    return Intl.message(
      'Recovery codes updated',
      name: 'recoveryCodesUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Changes saved successfully`
  String get changesSavedSuccessfully {
    return Intl.message(
      'Changes saved successfully',
      name: 'changesSavedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Enter login`
  String get enterLoginHint {
    return Intl.message(
      'Enter login',
      name: 'enterLoginHint',
      desc: '',
      args: [],
    );
  }

  /// `Pick date`
  String get pickDate {
    return Intl.message('Pick date', name: 'pickDate', desc: '', args: []);
  }

  /// `Token type`
  String get apiKeyTokenTypeLabel {
    return Intl.message(
      'Token type',
      name: 'apiKeyTokenTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `CRL URL`
  String get crlUrlLabel {
    return Intl.message('CRL URL', name: 'crlUrlLabel', desc: '', args: []);
  }

  /// `Email`
  String get emailFieldLabel {
    return Intl.message('Email', name: 'emailFieldLabel', desc: '', args: []);
  }

  /// `Select category`
  String get selectCategoryHint {
    return Intl.message(
      'Select category',
      name: 'selectCategoryHint',
      desc: '',
      args: [],
    );
  }

  /// `Scan ID`
  String get scanIdLabel {
    return Intl.message('Scan ID', name: 'scanIdLabel', desc: '', args: []);
  }

  /// `Order ID`
  String get orderIdLabel {
    return Intl.message('Order ID', name: 'orderIdLabel', desc: '', args: []);
  }

  /// `Check the form fields and try again`
  String get checkFormFieldsAndTryAgain {
    return Intl.message(
      'Check the form fields and try again',
      name: 'checkFormFieldsAndTryAgain',
      desc: '',
      args: [],
    );
  }

  /// `API key updated`
  String get apiKeyUpdated {
    return Intl.message(
      'API key updated',
      name: 'apiKeyUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Load error`
  String get apiKeyLoadError {
    return Intl.message(
      'Load error',
      name: 'apiKeyLoadError',
      desc: '',
      args: [],
    );
  }

  /// `Place of birth`
  String get placeOfBirthLabel {
    return Intl.message(
      'Place of birth',
      name: 'placeOfBirthLabel',
      desc: '',
      args: [],
    );
  }

  /// `Save error`
  String get saveError {
    return Intl.message('Save error', name: 'saveError', desc: '', args: []);
  }

  /// `Derivation path`
  String get derivationPathLabel {
    return Intl.message(
      'Derivation path',
      name: 'derivationPathLabel',
      desc: '',
      args: [],
    );
  }

  /// `License type`
  String get licenseTypeLabel {
    return Intl.message(
      'License type',
      name: 'licenseTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Purchase date (ISO8601)`
  String get purchaseDateIsoLabel {
    return Intl.message(
      'Purchase date (ISO8601)',
      name: 'purchaseDateIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Environment`
  String get environmentLabel {
    return Intl.message(
      'Environment',
      name: 'environmentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Key copied`
  String get apiKeyCopied {
    return Intl.message('Key copied', name: 'apiKeyCopied', desc: '', args: []);
  }

  /// `Identity updated`
  String get identityUpdated {
    return Intl.message(
      'Identity updated',
      name: 'identityUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Tags`
  String get tagsLabel {
    return Intl.message('Tags', name: 'tagsLabel', desc: '', args: []);
  }

  /// `https://example.com`
  String get urlHint {
    return Intl.message(
      'https://example.com',
      name: 'urlHint',
      desc: '',
      args: [],
    );
  }

  /// `Photo ID`
  String get photoIdLabel {
    return Intl.message('Photo ID', name: 'photoIdLabel', desc: '', args: []);
  }

  /// `Login`
  String get loginLabel {
    return Intl.message('Login', name: 'loginLabel', desc: '', args: []);
  }

  /// `Mnemonic`
  String get mnemonicLabel {
    return Intl.message('Mnemonic', name: 'mnemonicLabel', desc: '', args: []);
  }

  /// `Select note`
  String get selectNoteHint {
    return Intl.message(
      'Select note',
      name: 'selectNoteHint',
      desc: '',
      args: [],
    );
  }

  /// `Edit certificate`
  String get editCertificate {
    return Intl.message(
      'Edit certificate',
      name: 'editCertificate',
      desc: '',
      args: [],
    );
  }

  /// `New recovery codes`
  String get newRecoveryCodes {
    return Intl.message(
      'New recovery codes',
      name: 'newRecoveryCodes',
      desc: '',
      args: [],
    );
  }

  /// `Select date and time`
  String get selectDateTimeHint {
    return Intl.message(
      'Select date and time',
      name: 'selectDateTimeHint',
      desc: '',
      args: [],
    );
  }

  /// `Codes blob *`
  String get codesBlobRequiredLabel {
    return Intl.message(
      'Codes blob *',
      name: 'codesBlobRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Check the form fields and try again`
  String get apiKeyCheckFieldsMessage {
    return Intl.message(
      'Check the form fields and try again',
      name: 'apiKeyCheckFieldsMessage',
      desc: '',
      args: [],
    );
  }

  /// `Website`
  String get websiteLabel {
    return Intl.message('Website', name: 'websiteLabel', desc: '', args: []);
  }

  /// `Total codes`
  String get totalCodesLabel {
    return Intl.message(
      'Total codes',
      name: 'totalCodesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Revoked`
  String get apiKeyRevokedStatus {
    return Intl.message(
      'Revoked',
      name: 'apiKeyRevokedStatus',
      desc: '',
      args: [],
    );
  }

  /// `License created`
  String get licenseCreated {
    return Intl.message(
      'License created',
      name: 'licenseCreated',
      desc: '',
      args: [],
    );
  }

  /// `Certificate updated`
  String get certificateUpdated {
    return Intl.message(
      'Certificate updated',
      name: 'certificateUpdated',
      desc: '',
      args: [],
    );
  }

  /// `One-time codes`
  String get oneTimeCodesLabel {
    return Intl.message(
      'One-time codes',
      name: 'oneTimeCodesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select tags`
  String get selectTagsHint {
    return Intl.message(
      'Select tags',
      name: 'selectTagsHint',
      desc: '',
      args: [],
    );
  }

  /// `Password updated`
  String get passwordUpdated {
    return Intl.message(
      'Password updated',
      name: 'passwordUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Wi-Fi created`
  String get wifiCreated {
    return Intl.message(
      'Wi-Fi created',
      name: 'wifiCreated',
      desc: '',
      args: [],
    );
  }

  /// `Product *`
  String get productLabel {
    return Intl.message('Product *', name: 'productLabel', desc: '', args: []);
  }

  /// `Contact created`
  String get contactCreated {
    return Intl.message(
      'Contact created',
      name: 'contactCreated',
      desc: '',
      args: [],
    );
  }

  /// `Fingerprint`
  String get fingerprintLabel {
    return Intl.message(
      'Fingerprint',
      name: 'fingerprintLabel',
      desc: '',
      args: [],
    );
  }

  /// `Name *`
  String get apiKeyNameLabel {
    return Intl.message('Name *', name: 'apiKeyNameLabel', desc: '', args: []);
  }

  /// `Edit password`
  String get editPassword {
    return Intl.message(
      'Edit password',
      name: 'editPassword',
      desc: '',
      args: [],
    );
  }

  /// `Emergency contact`
  String get emergencyContactLabel {
    return Intl.message(
      'Emergency contact',
      name: 'emergencyContactLabel',
      desc: '',
      args: [],
    );
  }

  /// `Priority`
  String get wifiPriorityLabel {
    return Intl.message(
      'Priority',
      name: 'wifiPriorityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get emailLabel {
    return Intl.message('Email', name: 'emailLabel', desc: '', args: []);
  }

  /// `New Wi-Fi network`
  String get newWifiNetwork {
    return Intl.message(
      'New Wi-Fi network',
      name: 'newWifiNetwork',
      desc: '',
      args: [],
    );
  }

  /// `Company`
  String get companyLabel {
    return Intl.message('Company', name: 'companyLabel', desc: '', args: []);
  }

  /// `Form error`
  String get formError {
    return Intl.message('Form error', name: 'formError', desc: '', args: []);
  }

  /// `Crypto wallet created`
  String get cryptoWalletCreated {
    return Intl.message(
      'Crypto wallet created',
      name: 'cryptoWalletCreated',
      desc: '',
      args: [],
    );
  }

  /// `XPRV`
  String get xprvLabel {
    return Intl.message('XPRV', name: 'xprvLabel', desc: '', args: []);
  }

  /// `Failed to save password`
  String get failedToSavePassword {
    return Intl.message(
      'Failed to save password',
      name: 'failedToSavePassword',
      desc: '',
      args: [],
    );
  }

  /// `URL`
  String get urlLabel {
    return Intl.message('URL', name: 'urlLabel', desc: '', args: []);
  }

  /// `Private key *`
  String get privateKeyRequiredLabel {
    return Intl.message(
      'Private key *',
      name: 'privateKeyRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Document type *`
  String get documentTypeRequiredLabel {
    return Intl.message(
      'Document type *',
      name: 'documentTypeRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Key *`
  String get apiKeyKeyLabel {
    return Intl.message('Key *', name: 'apiKeyKeyLabel', desc: '', args: []);
  }

  /// `Category`
  String get categoryLabel {
    return Intl.message('Category', name: 'categoryLabel', desc: '', args: []);
  }

  /// `QR payload`
  String get wifiQrPayloadLabel {
    return Intl.message(
      'QR payload',
      name: 'wifiQrPayloadLabel',
      desc: '',
      args: [],
    );
  }

  /// `Crypto wallet updated`
  String get cryptoWalletUpdated {
    return Intl.message(
      'Crypto wallet updated',
      name: 'cryptoWalletUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Derivation scheme`
  String get derivationSchemeLabel {
    return Intl.message(
      'Derivation scheme',
      name: 'derivationSchemeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Issuer`
  String get issuerLabel {
    return Intl.message('Issuer', name: 'issuerLabel', desc: '', args: []);
  }

  /// `Verified`
  String get verifiedLabel {
    return Intl.message('Verified', name: 'verifiedLabel', desc: '', args: []);
  }

  /// `Domain`
  String get wifiDomainLabel {
    return Intl.message('Domain', name: 'wifiDomainLabel', desc: '', args: []);
  }

  /// `Public key *`
  String get publicKeyRequiredLabel {
    return Intl.message(
      'Public key *',
      name: 'publicKeyRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Password migration`
  String get passwordMigration {
    return Intl.message(
      'Password migration',
      name: 'passwordMigration',
      desc: '',
      args: [],
    );
  }

  /// `Document number *`
  String get documentNumberRequiredLabel {
    return Intl.message(
      'Document number *',
      name: 'documentNumberRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Key`
  String get apiKeyLabel {
    return Intl.message('Key', name: 'apiKeyLabel', desc: '', args: []);
  }

  /// `Enter password`
  String get enterPasswordHint {
    return Intl.message(
      'Enter password',
      name: 'enterPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `Expires at (ISO8601)`
  String get expiresAtIsoLabel {
    return Intl.message(
      'Expires at (ISO8601)',
      name: 'expiresAtIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get apiKeyDescriptionLabel {
    return Intl.message(
      'Description',
      name: 'apiKeyDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Identity`
  String get wifiIdentityLabel {
    return Intl.message(
      'Identity',
      name: 'wifiIdentityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit recovery codes`
  String get editRecoveryCodes {
    return Intl.message(
      'Edit recovery codes',
      name: 'editRecoveryCodes',
      desc: '',
      args: [],
    );
  }

  /// `Environment`
  String get apiKeyEnvironmentLabel {
    return Intl.message(
      'Environment',
      name: 'apiKeyEnvironmentLabel',
      desc: '',
      args: [],
    );
  }

  /// `New API key`
  String get newApiKey {
    return Intl.message('New API key', name: 'newApiKey', desc: '', args: []);
  }

  /// `Edit API key`
  String get editApiKey {
    return Intl.message('Edit API key', name: 'editApiKey', desc: '', args: []);
  }

  /// `Key revoked`
  String get apiKeyRevokedLabel {
    return Intl.message(
      'Key revoked',
      name: 'apiKeyRevokedLabel',
      desc: '',
      args: [],
    );
  }

  /// `Auto-renew`
  String get autoRenewLabel {
    return Intl.message(
      'Auto-renew',
      name: 'autoRenewLabel',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get apiKeyActiveStatus {
    return Intl.message(
      'Active',
      name: 'apiKeyActiveStatus',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get subjectLabel {
    return Intl.message('Subject', name: 'subjectLabel', desc: '', args: []);
  }

  /// `API key not found`
  String get apiKeyNotFound {
    return Intl.message(
      'API key not found',
      name: 'apiKeyNotFound',
      desc: '',
      args: [],
    );
  }

  /// `License key *`
  String get licenseKeyLabel {
    return Intl.message(
      'License key *',
      name: 'licenseKeyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Save error`
  String get apiKeySaveError {
    return Intl.message(
      'Save error',
      name: 'apiKeySaveError',
      desc: '',
      args: [],
    );
  }

  /// `Support contact`
  String get supportContactLabel {
    return Intl.message(
      'Support contact',
      name: 'supportContactLabel',
      desc: '',
      args: [],
    );
  }

  /// `Expiration date`
  String get expirationDateLabel {
    return Intl.message(
      'Expiration date',
      name: 'expirationDateLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit license`
  String get editLicense {
    return Intl.message(
      'Edit license',
      name: 'editLicense',
      desc: '',
      args: [],
    );
  }

  /// `Seats count`
  String get seatsCountLabel {
    return Intl.message(
      'Seats count',
      name: 'seatsCountLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit crypto wallet`
  String get editCryptoWallet {
    return Intl.message(
      'Edit crypto wallet',
      name: 'editCryptoWallet',
      desc: '',
      args: [],
    );
  }

  /// `New license`
  String get newLicense {
    return Intl.message('New license', name: 'newLicense', desc: '', args: []);
  }

  /// `Nationality`
  String get nationalityLabel {
    return Intl.message(
      'Nationality',
      name: 'nationalityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Activated at (ISO8601)`
  String get activatedAtIsoLabel {
    return Intl.message(
      'Activated at (ISO8601)',
      name: 'activatedAtIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Used`
  String get usedCodesLabel {
    return Intl.message('Used', name: 'usedCodesLabel', desc: '', args: []);
  }

  /// `Not specified`
  String get notSpecified {
    return Intl.message(
      'Not specified',
      name: 'notSpecified',
      desc: '',
      args: [],
    );
  }

  /// `Issuing authority`
  String get issuingAuthorityLabel {
    return Intl.message(
      'Issuing authority',
      name: 'issuingAuthorityLabel',
      desc: '',
      args: [],
    );
  }

  /// `EAP method`
  String get wifiEapMethodLabel {
    return Intl.message(
      'EAP method',
      name: 'wifiEapMethodLabel',
      desc: '',
      args: [],
    );
  }

  /// `Password created`
  String get passwordCreated {
    return Intl.message(
      'Password created',
      name: 'passwordCreated',
      desc: '',
      args: [],
    );
  }

  /// `Password *`
  String get passwordLabel {
    return Intl.message(
      'Password *',
      name: 'passwordLabel',
      desc: '',
      args: [],
    );
  }

  /// `New SSH key`
  String get newSshKey {
    return Intl.message('New SSH key', name: 'newSshKey', desc: '', args: []);
  }

  /// `Wi-Fi updated`
  String get wifiUpdated {
    return Intl.message(
      'Wi-Fi updated',
      name: 'wifiUpdated',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get newPassword {
    return Intl.message(
      'New password',
      name: 'newPassword',
      desc: '',
      args: [],
    );
  }

  /// `Edit identity`
  String get editIdentity {
    return Intl.message(
      'Edit identity',
      name: 'editIdentity',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get wifiUsernameLabel {
    return Intl.message(
      'Username',
      name: 'wifiUsernameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Serial number`
  String get serialNumberLabel {
    return Intl.message(
      'Serial number',
      name: 'serialNumberLabel',
      desc: '',
      args: [],
    );
  }

  /// `License file ID`
  String get licenseFileIdLabel {
    return Intl.message(
      'License file ID',
      name: 'licenseFileIdLabel',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get apiKeyStatusLabel {
    return Intl.message(
      'Status',
      name: 'apiKeyStatusLabel',
      desc: '',
      args: [],
    );
  }

  /// `Security`
  String get wifiSecurityLabel {
    return Intl.message(
      'Security',
      name: 'wifiSecurityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Contact updated`
  String get contactUpdated {
    return Intl.message(
      'Contact updated',
      name: 'contactUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Addresses (JSON)`
  String get addressesJsonLabel {
    return Intl.message(
      'Addresses (JSON)',
      name: 'addressesJsonLabel',
      desc: '',
      args: [],
    );
  }

  /// `Edit Wi-Fi`
  String get editWifi {
    return Intl.message('Edit Wi-Fi', name: 'editWifi', desc: '', args: []);
  }

  /// `View API key`
  String get viewApiKey {
    return Intl.message('View API key', name: 'viewApiKey', desc: '', args: []);
  }

  /// `Edit SSH key`
  String get editSshKey {
    return Intl.message('Edit SSH key', name: 'editSshKey', desc: '', args: []);
  }

  /// `Token type`
  String get tokenTypeLabel {
    return Intl.message(
      'Token type',
      name: 'tokenTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Full name`
  String get fullNameLabel {
    return Intl.message('Full name', name: 'fullNameLabel', desc: '', args: []);
  }

  /// `MRZ`
  String get mrzLabel {
    return Intl.message('MRZ', name: 'mrzLabel', desc: '', args: []);
  }

  /// `Purchased from`
  String get purchasedFromLabel {
    return Intl.message(
      'Purchased from',
      name: 'purchasedFromLabel',
      desc: '',
      args: [],
    );
  }

  /// `New identity`
  String get newIdentity {
    return Intl.message(
      'New identity',
      name: 'newIdentity',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get addressLabel {
    return Intl.message('Address', name: 'addressLabel', desc: '', args: []);
  }

  /// `* Fill at least one field: Login or Email`
  String get fillAtLeastOneField {
    return Intl.message(
      '* Fill at least one field: Login or Email',
      name: 'fillAtLeastOneField',
      desc: '',
      args: [],
    );
  }

  /// `New certificate`
  String get newCertificate {
    return Intl.message(
      'New certificate',
      name: 'newCertificate',
      desc: '',
      args: [],
    );
  }

  /// `Identity created`
  String get identityCreated {
    return Intl.message(
      'Identity created',
      name: 'identityCreated',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `Name *`
  String get nameLabel {
    return Intl.message('Name *', name: 'nameLabel', desc: '', args: []);
  }

  /// `OCSP URL`
  String get ocspUrlLabel {
    return Intl.message('OCSP URL', name: 'ocspUrlLabel', desc: '', args: []);
  }

  /// `Display hint`
  String get displayHintLabel {
    return Intl.message(
      'Display hint',
      name: 'displayHintLabel',
      desc: '',
      args: [],
    );
  }

  /// `New contact`
  String get newContact {
    return Intl.message('New contact', name: 'newContact', desc: '', args: []);
  }

  /// `Edit contact`
  String get editContact {
    return Intl.message(
      'Edit contact',
      name: 'editContact',
      desc: '',
      args: [],
    );
  }

  /// `Added to ssh-agent`
  String get addedToSshAgentLabel {
    return Intl.message(
      'Added to ssh-agent',
      name: 'addedToSshAgentLabel',
      desc: '',
      args: [],
    );
  }

  /// `Watch-only`
  String get watchOnlyLabel {
    return Intl.message(
      'Watch-only',
      name: 'watchOnlyLabel',
      desc: '',
      args: [],
    );
  }

  /// `XPUB`
  String get xpubLabel {
    return Intl.message('XPUB', name: 'xpubLabel', desc: '', args: []);
  }

  /// `Form error`
  String get apiKeyFormError {
    return Intl.message(
      'Form error',
      name: 'apiKeyFormError',
      desc: '',
      args: [],
    );
  }

  /// `Failed to get key`
  String get apiKeyRevealError {
    return Intl.message(
      'Failed to get key',
      name: 'apiKeyRevealError',
      desc: '',
      args: [],
    );
  }

  /// `Private key`
  String get privateKeyLabel {
    return Intl.message(
      'Private key',
      name: 'privateKeyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Usage`
  String get usageLabel {
    return Intl.message('Usage', name: 'usageLabel', desc: '', args: []);
  }

  /// `Max activations`
  String get maxActivationsLabel {
    return Intl.message(
      'Max activations',
      name: 'maxActivationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Birthday`
  String get birthdayLabel {
    return Intl.message('Birthday', name: 'birthdayLabel', desc: '', args: []);
  }

  /// `SSID *`
  String get wifiSsidLabel {
    return Intl.message('SSID *', name: 'wifiSsidLabel', desc: '', args: []);
  }

  /// `Enter name`
  String get enterNameHint {
    return Intl.message(
      'Enter name',
      name: 'enterNameHint',
      desc: '',
      args: [],
    );
  }

  /// `Contact name *`
  String get contactNameLabel {
    return Intl.message(
      'Contact name *',
      name: 'contactNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `API key created`
  String get apiKeyCreated {
    return Intl.message(
      'API key created',
      name: 'apiKeyCreated',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Description`
  String get descriptionLabel {
    return Intl.message(
      'Description',
      name: 'descriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Issue date (ISO8601)`
  String get issueDateIsoLabel {
    return Intl.message(
      'Issue date (ISO8601)',
      name: 'issueDateIsoLabel',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get phoneLabel {
    return Intl.message('Phone', name: 'phoneLabel', desc: '', args: []);
  }

  /// `SSH key created`
  String get sshKeyCreated {
    return Intl.message(
      'SSH key created',
      name: 'sshKeyCreated',
      desc: '',
      args: [],
    );
  }

  /// `Error getting key`
  String get apiKeyGetKeyError {
    return Intl.message(
      'Error getting key',
      name: 'apiKeyGetKeyError',
      desc: '',
      args: [],
    );
  }

  /// `Network`
  String get networkLabel {
    return Intl.message('Network', name: 'networkLabel', desc: '', args: []);
  }

  /// `Password`
  String get wifiPasswordLabel {
    return Intl.message(
      'Password',
      name: 'wifiPasswordLabel',
      desc: '',
      args: [],
    );
  }

  /// `Last connected BSSID`
  String get wifiLastConnectedBssidLabel {
    return Intl.message(
      'Last connected BSSID',
      name: 'wifiLastConnectedBssidLabel',
      desc: '',
      args: [],
    );
  }

  /// `Certificate created`
  String get certificateCreated {
    return Intl.message(
      'Certificate created',
      name: 'certificateCreated',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
