import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/errors/app_error.dart';
import 'package:hoplixi/core/errors/error_enums/validation_errors.dart';
import 'package:path/path.dart' as p;
import 'package:result_dart/result_dart.dart';
import 'package:uuid/uuid.dart';

class VaultKeyFile {
  static const int currentVersion = 1;
  static const int secretLength = 32;

  const VaultKeyFile({
    required this.version,
    required this.id,
    required this.secret,
    this.hint,
  });

  final int version;
  final String id;
  final Uint8List secret;
  final String? hint;

  factory VaultKeyFile.generate({String? hint}) {
    return VaultKeyFile(
      version: currentVersion,
      id: const Uuid().v4(),
      secret: _secureRandomBytes(secretLength),
      hint: VaultKeyFileSecurity.sanitizeHint(hint),
    );
  }

  factory VaultKeyFile.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != currentVersion) {
      throw const FormatException('Unsupported key file version');
    }

    final id = (json['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      throw const FormatException('Key file id is required');
    }

    final secretRaw = (json['secret'] as String?)?.trim() ?? '';
    final secret = _decodeSecret(secretRaw);
    if (secret.length != secretLength) {
      throw const FormatException('Key file secret must be 32 bytes');
    }

    final hint = VaultKeyFileSecurity.sanitizeHint(json['hint'] as String?);

    return VaultKeyFile(
      version: currentVersion,
      id: id,
      secret: secret,
      hint: hint,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'id': id,
      'secret': base64UrlEncode(secret),
      'hint': hint,
    };
  }

  static Uint8List _decodeSecret(String value) {
    try {
      return Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));
    } catch (_) {
      throw const FormatException('Key file secret must be base64url');
    }
  }

  static Uint8List _secureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

class VaultKeyFileSecurity {
  const VaultKeyFileSecurity._();

  static String? sanitizeHint(String? value) {
    final hint = value?.trim();
    if (hint == null || hint.isEmpty) {
      return null;
    }
    if (hint.length > 80) {
      throw const FormatException('Key file hint is too long');
    }
    if (containsUnsafeHintMaterial(hint)) {
      throw const FormatException('Key file hint contains unsafe material');
    }
    return hint;
  }

  static bool containsUnsafeHintMaterial(String value) {
    final hint = value.trim();
    if (hint.isEmpty) {
      return false;
    }

    final looksLikePath =
        RegExp(
          r'(^[a-zA-Z]:[\\/])|(^/)|(^~[\\/])|(\\\\)|(/[^\s]+/)',
        ).hasMatch(hint) ||
        p.isAbsolute(hint);
    if (looksLikePath) {
      return true;
    }

    final lower = hint.toLowerCase();
    const sensitiveLabels = <String>[
      'secret',
      'password',
      'master password',
      'private key',
      'key material',
      'base64',
      'derived key',
      'device key',
    ];
    if (sensitiveLabels.any(lower.contains)) {
      return true;
    }

    final compact = hint.replaceAll(RegExp(r'\s+'), '');
    final looksLikeBase64 = RegExp(
      r'^[A-Za-z0-9_-]{32,}={0,2}$',
    ).hasMatch(compact);
    final looksLikeHex = RegExp(r'^[a-fA-F0-9]{32,}$').hasMatch(compact);
    return looksLikeBase64 || looksLikeHex;
  }
}

class VaultKeyFileService {
  const VaultKeyFileService();

  Future<ResultDart<VaultKeyFile, AppError>> pickAndRead() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions:  [MainConstants.keyFileExtension.substring(1)],
      );
      final path = result?.files.single.path;
      if (path == null || path.trim().isEmpty) {
        return Failure(
          AppError.validation(
            code: ValidationErrorCode.emptyField,
            message: 'Файл ключа не выбран',
            timestamp: DateTime.now(),
          ),
        );
      }
      return readFromPath(path);
    } catch (error, stackTrace) {
      return Failure(_buildReadError(error, stackTrace));
    }
  }

  Future<ResultDart<VaultKeyFile, AppError>> readFromPath(String path) async {
    try {
      final raw = await File(path).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Key file root must be a JSON object');
      }
      return Success(VaultKeyFile.fromJson(decoded));
    } catch (error, stackTrace) {
      return Failure(_buildReadError(error, stackTrace));
    }
  }

  Future<ResultDart<VaultKeyFile, AppError>> createAndSave({
    required String suggestedFileName,
    String? hint,
  }) async {
    try {
      final keyFile = VaultKeyFile.generate(hint: hint);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Сохранить JSON key file',
        fileName: suggestedFileName.endsWith(MainConstants.keyFileExtension)
            ? suggestedFileName
            : '$suggestedFileName${MainConstants.keyFileExtension}',
        type: FileType.custom,
        allowedExtensions:  [MainConstants.keyFileExtension.substring(1)],
        bytes: Uint8List.fromList(
          utf8.encode(
            const JsonEncoder.withIndent('  ').convert(keyFile.toJson()),
          ),
        ),
      );
      if (path == null || path.trim().isEmpty) {
        return Failure(
          AppError.validation(
            code: ValidationErrorCode.emptyField,
            message: 'Файл ключа не сохранён',
            timestamp: DateTime.now(),
          ),
        );
      }
      return Success(keyFile);
    } catch (error, stackTrace) {
      return Failure(_buildReadError(error, stackTrace));
    }
  }

  AppError _buildReadError(Object error, StackTrace stackTrace) {
    return AppError.validation(
      code: ValidationErrorCode.invalidFormat,
      message: 'Некорректный JSON key file',
      cause: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
  }
}
