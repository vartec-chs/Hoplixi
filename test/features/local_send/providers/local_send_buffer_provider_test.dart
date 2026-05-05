import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/local_send/providers/local_send_buffer_provider.dart';
import 'package:hoplixi/features/password_manager/forms/shared/share/shareable_field.dart';

void main() {
  group('localSendBufferProvider', () {
    late ProviderContainer container;
    late LocalSendBufferNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(localSendBufferProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('stores shareable fields in buffer', () {
      notifier.addToBuffer([
        const ShareableField(id: 'name', label: 'Имя', value: 'Alice'),
        const ShareableField(id: 'login', label: 'Логин', value: 'alice'),
      ]);

      final payload = container.read(localSendBufferProvider);

      expect(payload, hasLength(2));
      expect(payload.first.label, 'Имя');
      expect(payload.last.value, 'alice');
    });

    test('builds text from buffer fields', () {
      notifier.addToBuffer([
        const ShareableField(id: 'name', label: 'Имя', value: 'Alice'),
        const ShareableField(id: 'login', label: 'Логин', value: 'alice'),
      ]);

      expect(notifier.buildText(), 'Имя: Alice\n\nЛогин: alice');
    });

    test('clears payload', () {
      notifier.addToBuffer([
        const ShareableField(id: 'name', label: 'Имя', value: 'Alice'),
      ]);
      notifier.clearBuffer();

      expect(container.read(localSendBufferProvider), isEmpty);
    });
  });
}
