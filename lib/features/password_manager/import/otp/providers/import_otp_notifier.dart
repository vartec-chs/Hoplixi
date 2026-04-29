import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/smart_converter_base.dart';
import 'package:hoplixi/features/password_manager/import/otp/otp_extractor.dart';
import 'package:hoplixi/features/password_manager/import/otp/providers/import_otp_state.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entity_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/main_db/core/models/dto/otp_dto.dart';
import 'package:hoplixi/main_db/core/models/enums/entity_types.dart';
import 'package:hoplixi/main_db/providers/other/dao_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;

class ImportOtpNotifier extends Notifier<ImportOtpState> {
  final _smartConverter = SmartConverter();

  @override
  ImportOtpState build() {
    ref.onDispose(() {
      _totpTimer?.cancel();
    });
    return const ImportOtpState();
  }

  Timer? _totpTimer;

  void startTotpTimer() {
    _totpTimer?.cancel();
    _updateTotpCodes();
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTotpCodes();
    });
  }

  void _updateTotpCodes() {
    if (state.importedOtps.isEmpty) return;

    final now = DateTime.now();
    final currentSecond = now.second;
    final newRemainingSeconds = 30 - (currentSecond % 30);

    if (state.remainingSeconds != newRemainingSeconds) {
      state = state.copyWith(remainingSeconds: newRemainingSeconds);
    }
  }

  Future<void> pickImageAndDecode() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final image = img.decodeImage(bytes);

        if (image != null) {
          // Convert image to int array for ZXing
          final width = image.width;
          final height = image.height;
          final pixels = <int>[];

          for (var y = 0; y < height; y++) {
            for (var x = 0; x < width; x++) {
              final pixel = image.getPixel(x, y);
              // Convert to ARGB int format
              final a = pixel.a.toInt();
              final r = pixel.r.toInt();
              final g = pixel.g.toInt();
              final b = pixel.b.toInt();
              pixels.add((a << 24) | (r << 16) | (g << 8) | b);
            }
          }

          final luminanceSource = RGBLuminanceSource(
            width,
            height,
            Int32List.fromList(pixels),
          );
          final binaryBitmap = BinaryBitmap(HybridBinarizer(luminanceSource));
          final reader = QRCodeReader();
          final result = reader.decode(binaryBitmap);

          await importOtp(Uint8List.fromList(result.text.codeUnits));
        }
      }
    } catch (e, s) {
      logError('Error scanning QR from image', error: e, stackTrace: s);
    }
  }

  Future<void> importOtp(Uint8List decodedBytes) async {
    try {
      final uri = String.fromCharCodes(decodedBytes);
      final newOtps = parseMigrationUri(uri);

      if (newOtps.isNotEmpty) {
        final currentOtps = List<OtpData>.from(state.importedOtps);
        currentOtps.addAll(newOtps);

        // Select new items by default
        final newIndices = List.generate(
          newOtps.length,
          (index) => state.importedOtps.length + index,
        );
        final newSelected = Set<int>.from(state.selectedIndices)
          ..addAll(newIndices);

        state = state.copyWith(
          importedOtps: currentOtps,
          selectedIndices: newSelected,
        );

        startTotpTimer();
      }
    } catch (e, s) {
      logError('Error importing OTP', error: e, stackTrace: s);
    }
  }

  void toggleExpanded(int index) {
    final newExpanded = Set<int>.from(state.expandedIndices);
    if (newExpanded.contains(index)) {
      newExpanded.remove(index);
    } else {
      newExpanded.add(index);
    }
    state = state.copyWith(expandedIndices: newExpanded);
  }

  void toggleSelection(int index) {
    final newSelected = Set<int>.from(state.selectedIndices);
    if (newSelected.contains(index)) {
      newSelected.remove(index);
    } else {
      newSelected.add(index);
    }
    state = state.copyWith(selectedIndices: newSelected);
  }

  void selectAll() {
    state = state.copyWith(
      selectedIndices: List.generate(
        state.importedOtps.length,
        (i) => i,
      ).toSet(),
    );
  }

  void deselectAll() {
    state = state.copyWith(selectedIndices: {});
  }

  Future<bool> saveSelectedOtps() async {
    if (state.selectedIndices.isEmpty) return false;

    state = state.copyWith(isSaving: true);

    try {
      final otpDao = await ref.read(otpDaoProvider.future);

      // Создаём список DTO для сохранения
      final dtos = <CreateOtpDto>[];
      for (final index in state.selectedIndices) {
        final otp = state.importedOtps[index];
        final mappedType = _mapType(otp.type);

        // Нормализуем секрет через SmartConverter
        // Секрет может прийти в любом формате (строка, base32, base64, hex)
        // SmartConverter автоматически определит формат и конвертирует в base32
        final normalizedSecret = _normalizeSecretToBase32(otp.secretBase32);

        // Конвертируем нормализованный Base32 секрет в байты
        final secretBytes = normalizedSecret.codeUnits;

        dtos.add(
          CreateOtpDto(
            type: mappedType,
            secret: secretBytes,
            secretEncoding: SecretEncoding.BASE32.name,
            issuer: otp.issuer.trim().isEmpty ? null : otp.issuer.trim(),
            accountName: otp.name.trim().isEmpty ? null : otp.name.trim(),
            algorithm: _mapAlgorithm(otp.algorithm),
            digits: otp.digits,
            period: 30,
            // counter должен быть NULL для TOTP и NOT NULL для HOTP
            counter: mappedType == 'hotp' ? otp.counter : null,
          ),
        );
      }

      // Сохраняем все OTP
      await otpDao.createManyOtps(dtos);

      // Удаляем сохранённые элементы из списка
      final remainingOtps = <OtpData>[];
      for (int i = 0; i < state.importedOtps.length; i++) {
        if (!state.selectedIndices.contains(i)) {
          remainingOtps.add(state.importedOtps[i]);
        }
      }

      logInfo(
        'Successfully saved ${state.selectedIndices.length} OTPs',
        tag: 'ImportOtpNotifier',
      );

      state = state.copyWith(
        importedOtps: remainingOtps,
        selectedIndices: {},
        expandedIndices: {},
        isSaving: false,
      );

      // Триггерим обновление списка OTP (не заметок!)
      ref
          .read(dataRefreshTriggerProvider.notifier)
          .triggerEntityAdd(EntityType.otp);

      return true;
    } catch (e, s) {
      logError(
        'Failed to save OTPs',
        error: e,
        stackTrace: s,
        tag: 'ImportOtpNotifier',
      );
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  /// Нормализует секрет в Base32 (как в otp_form_provider)
  ///
  /// Использует SmartConverter для автоматического определения формата
  /// и конвертации в Base32. Секрет может прийти в любом формате:
  /// - Обычная строка
  /// - Base32 (уже в правильном формате)
  /// - Base64
  /// - Hex
  String _normalizeSecretToBase32(String secret) {
    final result = _smartConverter.toBase32(secret.trim());
    return result['base32'] ?? secret.toUpperCase();
  }

  String _mapAlgorithm(String algo) {
    switch (algo) {
      case 'SHA1':
        return 'SHA1';
      case 'SHA256':
        return 'SHA256';
      case 'SHA512':
        return 'SHA512';
      default:
        return 'SHA1';
    }
  }

  String _mapType(String type) {
    switch (type) {
      case 'TOTP':
        return 'totp';
      case 'HOTP':
        return 'hotp';
      default:
        return 'totp';
    }
  }
}

final importOtpProvider =
    NotifierProvider.autoDispose<ImportOtpNotifier, ImportOtpState>(
      ImportOtpNotifier.new,
    );
