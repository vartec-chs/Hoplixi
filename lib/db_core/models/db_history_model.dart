import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_history_model.freezed.dart';
part 'db_history_model.g.dart';

@freezed
@immutable
sealed class DatabaseEntry with _$DatabaseEntry {
  const factory DatabaseEntry({
    required String path,
    required String name,
    required String dbId,
    String? description,
    String? password,
    required bool savePassword,
    DateTime? lastAccessed,
    DateTime? createdAt,
  }) = _DatabaseEntry;

  factory DatabaseEntry.fromJson(Map<String, dynamic> json) =>
      _$DatabaseEntryFromJson(json);
}
