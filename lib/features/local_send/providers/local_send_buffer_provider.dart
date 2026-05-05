import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/local_send/providers/transfer_provider.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/share_text_formatter.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';

final localSendBufferProvider =
    NotifierProvider<LocalSendBufferNotifier, List<ShareableField>>(
      LocalSendBufferNotifier.new,
    );

class LocalSendBufferNotifier extends Notifier<List<ShareableField>> {
  @override
  List<ShareableField> build() => const [];

  bool get hasBuffer => state.isNotEmpty;

  int get itemCount => state.length;

  void addToBuffer(Iterable<ShareableField> fields) {
    final bufferedFields = fields
        .where((field) => field.isNotEmpty)
        .toList(growable: false);

    if (bufferedFields.isEmpty) {
      return;
    }

    state = List<ShareableField>.unmodifiable(bufferedFields);
  }

  void clearBuffer() {
    state = const [];
  }

  String buildText() {
    return buildShareTextFromFields(state);
  }

  Future<bool> send() async {
    if (state.isEmpty) return false;

    final transfer = ref.read(transferProvider.notifier);
    final text = buildText();

    if (text.trim().isEmpty) {
      return false;
    }

    await transfer.sendText(text);
    return true;
  }
}
