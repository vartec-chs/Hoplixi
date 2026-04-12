import 'dart:convert';

import 'package:hoplixi/core/utils/smart_converter_base.dart';
import 'package:hoplixi/db_core/dao/crud/category_dao.dart';
import 'package:hoplixi/db_core/dao/crud/custom_field_dao.dart';
import 'package:hoplixi/db_core/dao/crud/note_dao.dart';
import 'package:hoplixi/db_core/dao/crud/otp_dao.dart';
import 'package:hoplixi/db_core/dao/crud/password_dao.dart';
import 'package:hoplixi/db_core/dao/crud/tag_dao.dart';
import 'package:hoplixi/db_core/models/dto/category_dto.dart';
import 'package:hoplixi/db_core/models/dto/custom_field_dto.dart';
import 'package:hoplixi/db_core/models/dto/note_dto.dart';
import 'package:hoplixi/db_core/models/dto/otp_dto.dart';
import 'package:hoplixi/db_core/models/dto/password_dto.dart';
import 'package:hoplixi/db_core/models/dto/tag_dto.dart';
import 'package:hoplixi/db_core/models/enums/entity_types.dart';
import 'package:hoplixi/rust/api/keepass_api.dart';

class KeepassImportExecutionOptions {
  final bool importOtps;
  final bool importNotes;
  final bool importCustomFields;
  final bool createCategories;

  const KeepassImportExecutionOptions({
    required this.importOtps,
    required this.importNotes,
    required this.importCustomFields,
    required this.createCategories,
  });
}

class KeepassImportSummary {
  final int importedPasswords;
  final int importedOtps;
  final int importedNotes;
  final int createdCategories;
  final int createdTags;
  final int createdCustomFields;
  final int skippedEntries;

  const KeepassImportSummary({
    required this.importedPasswords,
    required this.importedOtps,
    required this.importedNotes,
    required this.createdCategories,
    required this.createdTags,
    required this.createdCustomFields,
    required this.skippedEntries,
  });

  String toMessage() {
    final parts = <String>[
      'Паролей: $importedPasswords',
      'OTP: $importedOtps',
      'Заметок: $importedNotes',
      'Категорий: $createdCategories',
      'Тегов: $createdTags',
      'Кастомных полей: $createdCustomFields',
    ];

    if (skippedEntries > 0) {
      parts.add('Пропущено: $skippedEntries');
    }

    return 'Импорт KeePass завершён. ${parts.join(', ')}.';
  }
}

class KeepassImportService {
  static const _attachmentInlineLimitBytes = 128 * 1024;
  static const _customDataInlineLimitBytes = 32 * 1024;

  final PasswordDao passwordDao;
  final OtpDao otpDao;
  final NoteDao noteDao;
  final CategoryDao categoryDao;
  final TagDao tagDao;
  final CustomFieldDao customFieldDao;

  final SmartConverter _smartConverter = SmartConverter();

  KeepassImportService({
    required this.passwordDao,
    required this.otpDao,
    required this.noteDao,
    required this.categoryDao,
    required this.tagDao,
    required this.customFieldDao,
  });

  Future<KeepassImportSummary> importDatabase(
    FrbKeepassDatabaseExport export,
    KeepassImportExecutionOptions options,
  ) async {
    final existingCategories = await categoryDao.getAllCategories();
    final existingTags = await tagDao.getAllTags();

    final categoriesByName = <String, _ExistingCategoryRef>{};
    for (final category in existingCategories) {
      categoriesByName[_normalizeKey(category.name)] = _ExistingCategoryRef(
        id: category.id,
        type: category.type,
        parentId: category.parentId,
      );
    }

    final tagsByName = <String, _ExistingTagRef>{};
    for (final tag in existingTags) {
      tagsByName[_normalizeKey(tag.name)] = _ExistingTagRef(
        id: tag.id,
        type: tag.type,
      );
    }

    final categoryIdsByPath = <String, String>{};
    var importedPasswords = 0;
    var importedOtps = 0;
    var importedNotes = 0;
    var createdCategories = 0;
    var createdTags = 0;
    var createdCustomFields = 0;
    var skippedEntries = 0;

    for (final entry in export.entries) {
      final categoryResult = await _ensureCategoryTree(
        entry.groupPath,
        categoriesByName,
        categoryIdsByPath,
        allowCreate: options.createCategories,
      );
      final categoryId = categoryResult.categoryId;
      createdCategories += categoryResult.createdCount;

      final tagResult = await _ensureTags(entry.tags, tagsByName);
      final tagIds = tagResult.tagIds;
      createdTags += tagResult.createdCount;

      final normalizedOtp = _normalizeOtp(entry.otp);
      final importedOtpForEntry =
          options.importOtps &&
          normalizedOtp != null &&
          normalizedOtp.secret.isNotEmpty;

      final consumedFieldKeys = <String>{..._defaultConsumedFieldKeys};
      final emailField = _findEmailField(entry.fields);
      final email = _resolveEmail(entry, emailField);
      if (emailField != null) {
        consumedFieldKeys.add(_normalizeKey(emailField.key));
      }

      final entryTitle = _resolveEntryTitle(entry);
      final login = _resolveLogin(
        username: entry.username,
        email: email,
        fallbackTitle: entryTitle,
      );
      final extraFields = _extractExtraFields(entry.fields, consumedFieldKeys);
      final shouldCreatePassword = _shouldCreatePasswordItem(
        entry: entry,
        extraFields: extraFields,
        importedOtpForEntry: importedOtpForEntry,
      );

      String? noteId;
      final noteContent = options.importNotes ? _buildNoteContent(entry) : null;
      if (noteContent != null && noteContent.trim().isNotEmpty) {
        noteId = await noteDao.createNote(
          CreateNoteDto(
            title: entryTitle,
            content: noteContent,
            deltaJson: jsonEncode([
              {'insert': '$noteContent\n'},
            ]),
            description: _buildSourceDescription(entry.groupPath),
            categoryId: categoryId,
            tagsIds: tagIds,
          ),
        );
        importedNotes += 1;
      }

      String? passwordId;
      if (shouldCreatePassword) {
        passwordId = await passwordDao.createPassword(
          CreatePasswordDto(
            name: entryTitle,
            password: entry.password ?? '',
            login: login,
            email: email,
            url: _clean(entry.url),
            description: options.importNotes
                ? _buildSourceDescription(entry.groupPath)
                : _fallbackDescription(entry),
            noteId: noteId,
            categoryId: categoryId,
            tagsIds: tagIds,
            expireAt: _parseExpiry(entry.times),
          ),
        );
        importedPasswords += 1;
      }

      String? otpId;
      if (importedOtpForEntry) {
        otpId = await otpDao.createOtp(
          CreateOtpDto(
            type: OtpType.totp.name,
            secret: normalizedOtp.secret.codeUnits,
            secretEncoding: SecretEncoding.BASE32.name,
            issuer: normalizedOtp.issuer,
            accountName: normalizedOtp.accountName,
            noteId: noteId,
            algorithm: normalizedOtp.algorithm,
            digits: normalizedOtp.digits,
            period: normalizedOtp.period,
            categoryId: categoryId,
            tagsIds: tagIds,
            passwordId: passwordId,
          ),
        );
        importedOtps += 1;
      }

      final customFieldTargetId = passwordId ?? otpId;
      if (options.importCustomFields && customFieldTargetId != null) {
        final customFields = _buildCustomFields(
          entry: entry,
          extraFields: extraFields,
          options: options,
          otpWasImported: importedOtpForEntry,
          includeEntryNotesField: !options.importNotes,
        );

        for (var index = 0; index < customFields.length; index++) {
          final field = customFields[index];
          await customFieldDao.create(
            customFieldTargetId,
            CreateCustomFieldDto(
              label: field.label,
              value: field.value,
              fieldType: field.fieldType,
              sortOrder: index,
            ),
          );
        }

        createdCustomFields += customFields.length;
      }

      if (passwordId == null && otpId == null && noteId == null) {
        skippedEntries += 1;
      }
    }

    return KeepassImportSummary(
      importedPasswords: importedPasswords,
      importedOtps: importedOtps,
      importedNotes: importedNotes,
      createdCategories: createdCategories,
      createdTags: createdTags,
      createdCustomFields: createdCustomFields,
      skippedEntries: skippedEntries,
    );
  }

  Future<_EnsureCategoryResult> _ensureCategoryTree(
    String rawPath,
    Map<String, _ExistingCategoryRef> categoriesByName,
    Map<String, String> categoryIdsByPath, {
    required bool allowCreate,
  }) async {
    final path = rawPath.trim();
    if (path.isEmpty) {
      return const _EnsureCategoryResult(categoryId: null, createdCount: 0);
    }

    final segments = path
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return const _EnsureCategoryResult(categoryId: null, createdCount: 0);
    }

    String? parentId;
    var createdCount = 0;
    final currentSegments = <String>[];

    for (final segment in segments) {
      currentSegments.add(segment);
      final currentPath = currentSegments.join('/');

      final cachedId = categoryIdsByPath[currentPath];
      if (cachedId != null) {
        parentId = cachedId;
        continue;
      }

      final desiredName = currentPath;
      final fallbackName = 'KeePass/$currentPath';
      _ExistingCategoryRef? category =
          categoriesByName[_normalizeKey(desiredName)];

      if (category == null || category.type != CategoryType.mixed) {
        final fallback = categoriesByName[_normalizeKey(fallbackName)];
        if (fallback != null && fallback.type == CategoryType.mixed) {
          category = fallback;
        }
      }

      if (category == null || category.type != CategoryType.mixed) {
        if (!allowCreate) {
          return _EnsureCategoryResult(
            categoryId: parentId,
            createdCount: createdCount,
          );
        }

        final selectedName = category == null ? desiredName : fallbackName;
        final newId = await categoryDao.createCategory(
          CreateCategoryDto(
            name: selectedName,
            type: CategoryType.mixed.value,
            description: 'Импортировано из KeePass',
            parentId: parentId,
          ),
        );
        category = _ExistingCategoryRef(
          id: newId,
          type: CategoryType.mixed,
          parentId: parentId,
        );
        categoriesByName[_normalizeKey(selectedName)] = category;
        createdCount += 1;
      }

      categoryIdsByPath[currentPath] = category.id;
      parentId = category.id;
    }

    return _EnsureCategoryResult(
      categoryId: parentId,
      createdCount: createdCount,
    );
  }

  Future<_EnsureTagResult> _ensureTags(
    List<String> rawTags,
    Map<String, _ExistingTagRef> tagsByName,
  ) async {
    final tagIds = <String>[];
    var createdCount = 0;

    for (final rawTag in rawTags) {
      final tagName = rawTag.trim();
      if (tagName.isEmpty) {
        continue;
      }

      final key = _normalizeKey(tagName);
      final existing = tagsByName[key];
      if (existing != null) {
        tagIds.add(existing.id);
        continue;
      }

      final tagId = await tagDao.createTag(
        CreateTagDto(name: tagName, type: TagType.mixed.value),
      );
      tagsByName[key] = _ExistingTagRef(id: tagId, type: TagType.mixed);
      tagIds.add(tagId);
      createdCount += 1;
    }

    return _EnsureTagResult(tagIds: tagIds, createdCount: createdCount);
  }

  _NormalizedOtp? _normalizeOtp(FrbKeepassOtp? otp) {
    if (otp == null) {
      return null;
    }

    final rawSecret = _clean(otp.secret);
    if (rawSecret == null) {
      return null;
    }

    final normalizedSecret =
        _smartConverter.toBase32(rawSecret)['base32'] ??
        rawSecret.toUpperCase();

    return _NormalizedOtp(
      secret: normalizedSecret,
      issuer: _clean(otp.issuer),
      accountName: _clean(otp.label),
      algorithm: _normalizeOtpAlgorithm(otp.algorithm),
      digits: otp.digits ?? 6,
      period: otp.period?.toInt() ?? 30,
    );
  }

  bool _shouldCreatePasswordItem({
    required FrbKeepassEntry entry,
    required List<FrbKeepassField> extraFields,
    required bool importedOtpForEntry,
  }) {
    if (!importedOtpForEntry) {
      return true;
    }

    return _clean(entry.password) != null ||
        _clean(entry.username) != null ||
        _clean(entry.url) != null ||
        _clean(entry.notes) != null ||
        extraFields.isNotEmpty ||
        entry.attachments.isNotEmpty ||
        entry.customData.isNotEmpty ||
        entry.autotype != null ||
        entry.history.isNotEmpty;
  }

  List<FrbKeepassField> _extractExtraFields(
    List<FrbKeepassField> fields,
    Set<String> consumedFieldKeys,
  ) {
    return fields.where((field) {
      final key = _normalizeKey(field.key);
      return !consumedFieldKeys.contains(key);
    }).toList();
  }

  FrbKeepassField? _findEmailField(List<FrbKeepassField> fields) {
    for (final field in fields) {
      final normalized = _normalizeKey(field.key);
      if (normalized == 'email' ||
          normalized == 'e-mail' ||
          normalized == 'mail') {
        return field;
      }
    }
    return null;
  }

  String? _resolveEmail(FrbKeepassEntry entry, FrbKeepassField? emailField) {
    final fromField = _clean(emailField?.value);
    if (fromField != null) {
      return fromField;
    }

    final username = _clean(entry.username);
    if (username != null && username.contains('@')) {
      return username;
    }

    return null;
  }

  String? _resolveLogin({
    required String? username,
    required String? email,
    required String fallbackTitle,
  }) {
    final cleanUsername = _clean(username);
    if (cleanUsername == null) {
      return email == null ? fallbackTitle : null;
    }

    if (email != null && cleanUsername == email) {
      return null;
    }

    return cleanUsername;
  }

  String _resolveEntryTitle(FrbKeepassEntry entry) {
    return _clean(entry.title) ??
        _clean(entry.username) ??
        _clean(entry.url) ??
        _clean(entry.otp?.label) ??
        _clean(entry.otp?.issuer) ??
        'KeePass ${entry.uuid.substring(0, 8)}';
  }

  String? _buildSourceDescription(String groupPath) {
    if (groupPath.trim().isEmpty) {
      return 'Импортировано из KeePass';
    }
    return 'Импортировано из KeePass: $groupPath';
  }

  String? _fallbackDescription(FrbKeepassEntry entry) {
    final notes = _clean(entry.notes);
    if (notes != null) {
      return notes;
    }
    return _buildSourceDescription(entry.groupPath);
  }

  DateTime? _parseExpiry(FrbKeepassTimes times) {
    if (times.expires != true) {
      return null;
    }

    final rawExpiry = _clean(times.expiry);
    if (rawExpiry == null) {
      return null;
    }

    return DateTime.tryParse(rawExpiry);
  }

  String? _buildNoteContent(FrbKeepassEntry entry) {
    final sections = <String>[];
    final notes = _clean(entry.notes);
    if (notes != null) {
      sections.add(notes);
    }

    final sourceLines = <String>[
      if (entry.groupPath.trim().isNotEmpty) 'Путь группы: ${entry.groupPath}',
      if (_clean(entry.overrideUrl) != null)
        'Override URL: ${entry.overrideUrl}',
      if (entry.qualityCheck != null) 'Quality check: ${entry.qualityCheck}',
      if (_clean(entry.foregroundColor) != null)
        'Foreground color: ${entry.foregroundColor}',
      if (_clean(entry.backgroundColor) != null)
        'Background color: ${entry.backgroundColor}',
    ];
    if (sourceLines.isNotEmpty) {
      sections.add('KeePass метаданные\n${sourceLines.join('\n')}');
    }

    final customDataSection = _buildCustomDataSection(entry.customData);
    if (customDataSection != null) {
      sections.add(customDataSection);
    }

    final attachmentSection = _buildAttachmentSection(entry.attachments);
    if (attachmentSection != null) {
      sections.add(attachmentSection);
    }

    final autoTypeSection = _buildAutotypeSection(entry.autotype);
    if (autoTypeSection != null) {
      sections.add(autoTypeSection);
    }

    final otpSection = _buildOtpSection(entry.otp);
    if (otpSection != null) {
      sections.add(otpSection);
    }

    final historySection = _buildHistorySection(entry.history);
    if (historySection != null) {
      sections.add(historySection);
    }

    final result = sections
        .where((item) => item.trim().isNotEmpty)
        .join('\n\n');
    return result.trim().isEmpty ? null : result.trim();
  }

  List<_CustomFieldSeed> _buildCustomFields({
    required FrbKeepassEntry entry,
    required List<FrbKeepassField> extraFields,
    required KeepassImportExecutionOptions options,
    required bool otpWasImported,
    required bool includeEntryNotesField,
  }) {
    final result = <_CustomFieldSeed>[];

    for (final field in extraFields) {
      result.add(
        _CustomFieldSeed(
          label: field.key,
          value: field.value,
          fieldType: _detectFieldType(field.key, field.value, field.protected),
        ),
      );
    }

    if (includeEntryNotesField && _clean(entry.notes) != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass Notes',
          value: entry.notes,
          fieldType: CustomFieldType.text,
        ),
      );
    }

    for (final item in entry.customData) {
      final value = _stringifyCustomDataItem(item);
      if (value == null) {
        continue;
      }
      result.add(
        _CustomFieldSeed(
          label: 'KeePass CustomData: ${item.key}',
          value: value,
        ),
      );
    }

    if (_clean(entry.overrideUrl) != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass Override URL',
          value: entry.overrideUrl,
          fieldType: CustomFieldType.url,
        ),
      );
    }

    if (entry.qualityCheck != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass Quality Check',
          value: entry.qualityCheck.toString(),
        ),
      );
    }

    if (_clean(entry.foregroundColor) != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass Foreground Color',
          value: entry.foregroundColor,
        ),
      );
    }

    if (_clean(entry.backgroundColor) != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass Background Color',
          value: entry.backgroundColor,
        ),
      );
    }

    if (entry.autotype != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass AutoType',
          value: _serializeAutotype(entry.autotype!),
        ),
      );
    }

    if (entry.attachments.isNotEmpty) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass Attachments',
          value: _serializeAttachments(entry.attachments),
        ),
      );
    }

    if (entry.history.isNotEmpty) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass History',
          value: 'Снимков истории: ${entry.history.length}',
        ),
      );
    }

    if (entry.otp != null &&
        (!otpWasImported || entry.otp?.parseError != null)) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass OTP',
          value: _serializeOtp(entry.otp!),
          fieldType: CustomFieldType.concealed,
        ),
      );
    }

    if (!options.importOtps && entry.otp != null) {
      result.add(
        _CustomFieldSeed(
          label: 'KeePass OTP Disabled',
          value: 'OTP не был импортирован, потому что опция отключена.',
        ),
      );
    }

    return result;
  }

  String? _buildCustomDataSection(List<FrbKeepassCustomDataItem> items) {
    if (items.isEmpty) {
      return null;
    }

    final lines = items
        .map((item) {
          final value = _stringifyCustomDataItem(item);
          return '- ${item.key}: ${value ?? '<empty>'}';
        })
        .join('\n');

    return 'KeePass custom data\n$lines';
  }

  String? _buildAttachmentSection(List<FrbKeepassAttachment> attachments) {
    if (attachments.isEmpty) {
      return null;
    }

    final lines = attachments
        .map((attachment) {
          return '- ${attachment.key}: ${attachment.size} bytes'
              '${attachment.protected ? ', protected' : ''}';
        })
        .join('\n');

    return 'KeePass attachments\n$lines';
  }

  String? _buildAutotypeSection(FrbKeepassAutoType? autotype) {
    if (autotype == null) {
      return null;
    }

    final lines = <String>[
      'Enabled: ${autotype.enabled}',
      if (_clean(autotype.defaultSequence) != null)
        'Default sequence: ${autotype.defaultSequence}',
      if (autotype.dataTransferObfuscation != null)
        'Obfuscation: ${autotype.dataTransferObfuscation}',
      if (autotype.associations.isNotEmpty) ...[
        'Associations:',
        ...autotype.associations.map(
          (association) => '- ${association.window}: ${association.sequence}',
        ),
      ],
    ];

    return 'KeePass auto-type\n${lines.join('\n')}';
  }

  String? _buildOtpSection(FrbKeepassOtp? otp) {
    if (otp == null) {
      return null;
    }

    final lines = <String>[
      'Raw value: ${otp.rawValue}',
      if (_clean(otp.label) != null) 'Label: ${otp.label}',
      if (_clean(otp.issuer) != null) 'Issuer: ${otp.issuer}',
      if (_clean(otp.secret) != null) 'Secret: ${otp.secret}',
      if (otp.period != null) 'Period: ${otp.period}',
      if (otp.digits != null) 'Digits: ${otp.digits}',
      if (_clean(otp.algorithm) != null) 'Algorithm: ${otp.algorithm}',
      if (_clean(otp.parseError) != null) 'Parse error: ${otp.parseError}',
    ];

    return 'KeePass OTP\n${lines.join('\n')}';
  }

  String? _buildHistorySection(List<FrbKeepassHistoryEntry> history) {
    if (history.isEmpty) {
      return null;
    }

    final buffer = StringBuffer('KeePass history\n');
    for (var index = 0; index < history.length; index++) {
      final item = history[index];
      buffer.writeln('Snapshot ${index + 1}');
      if (_clean(item.title) != null) {
        buffer.writeln('Title: ${item.title}');
      }
      if (_clean(item.username) != null) {
        buffer.writeln('Username: ${item.username}');
      }
      if (_clean(item.url) != null) {
        buffer.writeln('URL: ${item.url}');
      }
      if (_clean(item.notes) != null) {
        buffer.writeln('Notes: ${item.notes}');
      }
      if (item.tags.isNotEmpty) {
        buffer.writeln('Tags: ${item.tags.join(', ')}');
      }
      if (_clean(item.times.lastModification) != null) {
        buffer.writeln('Modified: ${item.times.lastModification}');
      }
      if (item.attachments.isNotEmpty) {
        buffer.writeln('Attachments: ${item.attachments.length}');
      }
      if (item.otp != null && _clean(item.otp?.rawValue) != null) {
        buffer.writeln('OTP: ${item.otp!.rawValue}');
      }
      if (index != history.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  String _serializeAutotype(FrbKeepassAutoType autotype) {
    return jsonEncode({
      'enabled': autotype.enabled,
      'defaultSequence': autotype.defaultSequence,
      'dataTransferObfuscation': autotype.dataTransferObfuscation,
      'associations': autotype.associations
          .map(
            (association) => {
              'window': association.window,
              'sequence': association.sequence,
            },
          )
          .toList(),
    });
  }

  String _serializeAttachments(List<FrbKeepassAttachment> attachments) {
    return jsonEncode(
      attachments.map((attachment) {
        final inlineAllowed =
            attachment.data.length <= _attachmentInlineLimitBytes;
        return {
          'key': attachment.key,
          'size': attachment.size.toInt(),
          'protected': attachment.protected,
          'encoding': inlineAllowed ? 'base64' : 'omitted',
          'data': inlineAllowed ? base64Encode(attachment.data) : null,
        };
      }).toList(),
    );
  }

  String _serializeOtp(FrbKeepassOtp otp) {
    return jsonEncode({
      'rawValue': otp.rawValue,
      'label': otp.label,
      'issuer': otp.issuer,
      'secret': otp.secret,
      'period': otp.period?.toInt(),
      'digits': otp.digits,
      'algorithm': otp.algorithm,
      'parseError': otp.parseError,
    });
  }

  String? _stringifyCustomDataItem(FrbKeepassCustomDataItem item) {
    if (_clean(item.stringValue) != null) {
      return item.stringValue;
    }

    final binaryValue = item.binaryValue;
    if (binaryValue == null) {
      return null;
    }

    if (binaryValue.length <= _customDataInlineLimitBytes) {
      return jsonEncode({
        'valueKind': item.valueKind,
        'encoding': 'base64',
        'data': base64Encode(binaryValue),
      });
    }

    return jsonEncode({
      'valueKind': item.valueKind,
      'encoding': 'omitted',
      'size': binaryValue.length,
    });
  }

  CustomFieldType _detectFieldType(
    String key,
    String? value,
    bool isProtected,
  ) {
    if (isProtected) {
      return CustomFieldType.concealed;
    }

    final normalizedKey = _normalizeKey(key);
    final cleanValue = _clean(value);
    if (cleanValue == null) {
      return CustomFieldType.text;
    }

    if (normalizedKey.contains('url') || cleanValue.startsWith('http')) {
      return CustomFieldType.url;
    }

    if (normalizedKey.contains('mail') || cleanValue.contains('@')) {
      return CustomFieldType.email;
    }

    if (DateTime.tryParse(cleanValue) != null) {
      return CustomFieldType.date;
    }

    if (num.tryParse(cleanValue) != null) {
      return CustomFieldType.number;
    }

    return CustomFieldType.text;
  }

  String _normalizeOtpAlgorithm(String? rawValue) {
    switch (_clean(rawValue)?.toUpperCase()) {
      case 'SHA256':
        return 'SHA256';
      case 'SHA512':
        return 'SHA512';
      default:
        return 'SHA1';
    }
  }

  String? _clean(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();
}

const _defaultConsumedFieldKeys = <String>{
  'title',
  'username',
  'user name',
  'password',
  'url',
  'notes',
  'otp',
  'totp',
  'keeotp',
};

class _EnsureCategoryResult {
  final String? categoryId;
  final int createdCount;

  const _EnsureCategoryResult({
    required this.categoryId,
    required this.createdCount,
  });
}

class _EnsureTagResult {
  final List<String> tagIds;
  final int createdCount;

  const _EnsureTagResult({required this.tagIds, required this.createdCount});
}

class _ExistingCategoryRef {
  final String id;
  final CategoryType type;
  final String? parentId;

  const _ExistingCategoryRef({
    required this.id,
    required this.type,
    required this.parentId,
  });
}

class _ExistingTagRef {
  final String id;
  final TagType type;

  const _ExistingTagRef({required this.id, required this.type});
}

class _NormalizedOtp {
  final String secret;
  final String? issuer;
  final String? accountName;
  final String algorithm;
  final int digits;
  final int period;

  const _NormalizedOtp({
    required this.secret,
    required this.issuer,
    required this.accountName,
    required this.algorithm,
    required this.digits,
    required this.period,
  });
}

class _CustomFieldSeed {
  final String label;
  final String? value;
  final CustomFieldType fieldType;

  const _CustomFieldSeed({
    required this.label,
    required this.value,
    this.fieldType = CustomFieldType.text,
  });
}
