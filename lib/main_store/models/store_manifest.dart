import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_manifest.freezed.dart';
part 'store_manifest.g.dart';

@freezed
sealed class StoreManifest with _$StoreManifest {
  const factory StoreManifest({
    /// Версия формата манифеста.
    @Default(1) int version,

    /// Идентификатор хранилища (UUID v4).
    required String storeId,

    /// Временная метка последнего изменения (Unix timestamp, ms).
    required int lastModified,
  }) = _StoreManifest;

  const StoreManifest._();

  factory StoreManifest.fromJson(Map<String, dynamic> json) =>
      _$StoreManifestFromJson(json);
}
