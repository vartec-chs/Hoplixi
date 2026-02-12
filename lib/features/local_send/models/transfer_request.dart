import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/local_send/models/device_info.dart';

part 'transfer_request.freezed.dart';
part 'transfer_request.g.dart';

/// Метаданные одного файла для передачи.
@freezed
abstract class FileMetadata with _$FileMetadata {
  const factory FileMetadata({
    /// Имя файла.
    required String name,

    /// Размер в байтах.
    required int size,

    /// MIME-тип (например, "image/png").
    required String mimeType,
  }) = _FileMetadata;

  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);
}

/// Запрос на передачу данных между устройствами.
@freezed
abstract class TransferRequest with _$TransferRequest {
  const factory TransferRequest({
    /// Устройство-отправитель.
    required DeviceInfo senderDevice,

    /// Список файлов для передачи.
    @Default([]) List<FileMetadata> files,

    /// Текстовое сообщение (опционально).
    String? text,
  }) = _TransferRequest;

  factory TransferRequest.fromJson(Map<String, dynamic> json) =>
      _$TransferRequestFromJson(json);
}
