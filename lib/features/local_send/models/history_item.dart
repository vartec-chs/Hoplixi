import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/local_send/models/encrypted_transfer_envelope.dart';

part 'history_item.freezed.dart';
part 'history_item.g.dart';

/// Тип элемента истории обмена.
enum HistoryItemType {
  fileSent,
  fileReceived,
  textSent,
  textReceived,
  authTokensSent,
  authTokensReceived,
}

/// Один элемент истории обмена внутри сессии.
@freezed
sealed class HistoryItem with _$HistoryItem {
  const factory HistoryItem({
    required HistoryItemType type,
    required String content,
    required DateTime timestamp,
    String? deviceName,
    String? filePath,
    EncryptedTransferEnvelope? encryptedEnvelope,
  }) = _HistoryItem;

  const HistoryItem._();

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);

  bool get isSent =>
      type == HistoryItemType.fileSent ||
      type == HistoryItemType.textSent ||
      type == HistoryItemType.authTokensSent;

  bool get isFile =>
      type == HistoryItemType.fileSent || type == HistoryItemType.fileReceived;

  bool get isText =>
      type == HistoryItemType.textSent || type == HistoryItemType.textReceived;

  bool get isAuthTokenPayload =>
      type == HistoryItemType.authTokensSent ||
      type == HistoryItemType.authTokensReceived;
}
