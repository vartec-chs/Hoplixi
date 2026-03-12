import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_item.freezed.dart';
part 'history_item.g.dart';

/// Тип элемента истории обмена.
enum HistoryItemType { fileSent, fileReceived, textSent, textReceived }

/// Один элемент истории обмена внутри сессии.
@freezed
sealed class HistoryItem with _$HistoryItem {
  const factory HistoryItem({
    required HistoryItemType type,
    required String content,
    required DateTime timestamp,
    String? deviceName,
    String? filePath,
  }) = _HistoryItem;

  const HistoryItem._();

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);

  bool get isSent =>
      type == HistoryItemType.fileSent || type == HistoryItemType.textSent;

  bool get isFile =>
      type == HistoryItemType.fileSent || type == HistoryItemType.fileReceived;
}
