/// Утилита для декодирования QR-кодов и штрихкодов из изображений.
///
/// Стратегии декодирования (по приоритету):
/// 1. flutter_zxing path-based без ограничения размера
/// 2. flutter_zxing с raw lum-байтами (явный контроль формата + горизонтальные полосы)
/// 3. zxing2 pure-Dart fallback для QR (несколько бинаризаторов + инверсия + повороты)
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

// Максимальная длина стороны при конвертации в сырые lum-байты
const _maxLumSide = 1600;

/// Результат декодирования кода из изображения.
class BarcodeDecodeResult {
  /// Расшифрованный текст кода.
  final String text;

  /// Человекочитаемое название формата (например, «QR-код», «EAN-13»).
  final String formatName;

  const BarcodeDecodeResult({required this.text, required this.formatName});
}

/// Декодирует QR-код и/или штрихкод из [file].
///
/// [enableQrCode] — QR, DataMatrix, Aztec, PDF417 и прочие 2D.
/// [enableBarcode] — Code128, EAN-13, UPC, Code39, Codabar и прочие 1D.
Future<BarcodeDecodeResult?> decodeBarcodeFromFile(
  File file, {
  bool enableQrCode = true,
  bool enableBarcode = false,
}) async {
  int formatMask = Format.none;
  if (enableQrCode) formatMask |= Format.matrixCodes;
  if (enableBarcode) formatMask |= Format.linearCodes;
  if (formatMask == Format.none) return null;

  // — Стратегия 1: path-based без ограничения разрешения ———————————————————
  // Ключевое отличие от дефолта: maxSize=10000 вместо 768 — не даём ZXing
  // подрезать изображение, что критично для тонких полос 1D штрихкодов.
  try {
    final code = await zx.readBarcodeImagePathString(
      file.path,
      DecodeParams(
        format: formatMask,
        tryHarder: true,
        tryRotate: true,
        tryInverted: true,
        maxSize: 10000,
      ),
    );
    final r = _codeToResult(code);
    if (r != null) return r;
  } catch (_) {}

  // — Стратегия 2: raw lum-байты (явный контроль пикселей) ——————————————————
  // Передаём ZXing чистые байты яркости с точными размерами.
  // Для 1D дополнительно пробуем горизонтальные полосы и усиленный контраст.
  try {
    final fileBytes = await file.readAsBytes();
    final decoded = img.decodeImage(fileBytes);
    if (decoded != null) {
      final image = _resizeIfNeeded(decoded);

      // 2a. Полное изображение
      var r = _tryRawLum(image, formatMask);
      if (r != null) return r;

      if (enableBarcode) {
        // 2b. Горизонтальные полосы (штрихкод может занимать только часть высоты)
        r = _tryHorizontalStrips(image, formatMask);
        if (r != null) return r;

        // 2c. Усиленный контраст (помогает при нечётком фото)
        final enhanced = img.adjustColor(img.Image.from(image), contrast: 1.5);
        r = _tryRawLum(enhanced, formatMask);
        if (r != null) return r;

        // 2d. Усиленный контраст + полосы
        r = _tryHorizontalStrips(enhanced, formatMask);
        if (r != null) return r;
      }

      // 2e. zxing2 pure-Dart fallback для QR
      if (enableQrCode) {
        return _tryQrStrategies(image);
      }
    }
  } catch (_) {}

  return null;
}

// ---------------------------------------------------------------------------
// Стратегии декодирования
// ---------------------------------------------------------------------------

/// Пробует декодировать [image] через ZXing с raw lum-байтами.
BarcodeDecodeResult? _tryRawLum(img.Image image, int formatMask) {
  try {
    final lum = _toLumBytes(image);
    final code = zx.readBarcode(
      lum,
      DecodeParams(
        imageFormat: ImageFormat.lum,
        format: formatMask,
        width: image.width,
        height: image.height,
        tryHarder: true,
        tryRotate: true,
        tryInverted: true,
      ),
    );
    return _codeToResult(code);
  } catch (_) {
    return null;
  }
}

/// Разрезает изображение на перекрывающиеся горизонтальные полосы и пробует
/// декодировать каждую. Критично для 1D штрихкодов, занимающих узкую полосу.
BarcodeDecodeResult? _tryHorizontalStrips(img.Image image, int formatMask) {
  final h = image.height;
  // верхняя половина, нижняя половина, средняя половина, средняя треть
  final strips = [
    (0, h ~/ 2),
    (h ~/ 2, h),
    (h ~/ 4, 3 * h ~/ 4),
    (h ~/ 3, 2 * h ~/ 3),
  ];

  for (final (y1, y2) in strips) {
    if (y2 - y1 < 20) continue;
    try {
      final strip = img.copyCrop(
        image,
        x: 0,
        y: y1,
        width: image.width,
        height: y2 - y1,
      );
      final r = _tryRawLum(strip, formatMask);
      if (r != null) return r;
    } catch (_) {}
  }
  return null;
}

// ---------------------------------------------------------------------------
// Вспомогательные функции
// ---------------------------------------------------------------------------

/// Конвертирует [img.Image] в плоский массив байтов яркости (1 байт/пиксель).
Uint8List _toLumBytes(img.Image image) {
  final w = image.width;
  final h = image.height;
  final lum = Uint8List(w * h);
  var idx = 0;
  for (final pixel in image) {
    lum[idx++] = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114)
        .round()
        .clamp(0, 255);
  }
  return lum;
}

/// Уменьшает изображение до [_maxLumSide] пикселей по длинной стороне.
img.Image _resizeIfNeeded(img.Image image) {
  if (image.width <= _maxLumSide && image.height <= _maxLumSide) return image;
  return image.width >= image.height
      ? img.copyResize(image, width: _maxLumSide)
      : img.copyResize(image, height: _maxLumSide);
}

BarcodeDecodeResult? _codeToResult(Code code) {
  if (!code.isValid || code.text == null || code.text!.isEmpty) return null;
  return BarcodeDecodeResult(
    text: code.text!,
    formatName: code.format != null ? _formatName(code.format!) : 'Штрихкод',
  );
}

String _formatName(int format) {
  const names = <int, String>{
    Format.qrCode: 'QR-код',
    Format.microQRCode: 'Micro QR',
    Format.rmqrCode: 'rMQR',
    Format.aztec: 'Aztec',
    Format.dataMatrix: 'Data Matrix',
    Format.pdf417: 'PDF417',
    Format.maxiCode: 'MaxiCode',
    Format.code128: 'Code 128',
    Format.code93: 'Code 93',
    Format.code39: 'Code 39',
    Format.codabar: 'Codabar',
    Format.ean13: 'EAN-13',
    Format.ean8: 'EAN-8',
    Format.upca: 'UPC-A',
    Format.upce: 'UPC-E',
    Format.itf: 'ITF',
    Format.dataBar: 'GS1 DataBar',
    Format.dataBarExpanded: 'GS1 DataBar Exp',
  };
  return names[format] ?? zx.barcodeFormatName(format);
}

// ---------------------------------------------------------------------------
// zxing2 QR fallback (pure Dart, множество стратегий бинаризации)
// ---------------------------------------------------------------------------

BarcodeDecodeResult? _tryQrStrategies(img.Image original) {
  var result = _tryQrOnImage(original);
  if (result != null) return result;

  final inverted = img.invert(img.Image.from(original));
  result = _tryQrOnImage(inverted);
  if (result != null) return result;

  for (final angle in [90, 180, 270]) {
    final rotated = img.copyRotate(original, angle: angle);
    result = _tryQrOnImage(rotated);
    if (result != null) return result;
  }

  return null;
}

BarcodeDecodeResult? _tryQrOnImage(img.Image image) {
  final source = _toRgbLuminanceSource(image);
  final reader = QRCodeReader();

  try {
    final bitmap = BinaryBitmap(GlobalHistogramBinarizer(source));
    final res = reader.decode(bitmap);
    return BarcodeDecodeResult(text: res.text, formatName: 'QR-код');
  } on NotFoundException {
    // Продолжаем
  }

  try {
    final bitmap = BinaryBitmap(HybridBinarizer(source));
    final res = reader.decode(bitmap);
    return BarcodeDecodeResult(text: res.text, formatName: 'QR-код');
  } on NotFoundException {
    // Не найдено
  }

  return null;
}

RGBLuminanceSource _toRgbLuminanceSource(img.Image image) {
  final converted = image.convert(numChannels: 4);
  final int32List = converted
      .getBytes(order: img.ChannelOrder.abgr)
      .buffer
      .asInt32List();
  return RGBLuminanceSource(converted.width, converted.height, int32List);
}
