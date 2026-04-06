import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/shared/utils/vault_link_utils.dart';

void main() {
  group('buildVaultItemLinkUrl', () {
    test('builds the new vault link format', () {
      expect(
        buildVaultItemLinkUrl(entityId: 'passwords', itemId: 'item-123'),
        'vault://passwords/item-123',
      );
    });
  });

  group('parseVaultLink', () {
    test('parses vault links', () {
      final link = parseVaultLink('vault://documents/abc-123');

      expect(link, isNotNull);
      expect(link!.entityId, 'documents');
      expect(link.itemId, 'abc-123');
      expect(link.isLegacyNoteLink, isFalse);
    });

    test('parses legacy note links', () {
      final link = parseVaultLink('note://abc-123');

      expect(link, isNotNull);
      expect(link!.entityId, 'notes');
      expect(link.itemId, 'abc-123');
      expect(link.isLegacyNoteLink, isTrue);
    });

    test('handles prefixed urls produced by quill', () {
      final link = parseVaultLink('https://vault://files/abc-123');

      expect(link, isNotNull);
      expect(link!.entityId, 'files');
      expect(link.itemId, 'abc-123');
    });
  });

  group('extractLinkedItemIds', () {
    test('extracts both vault and legacy note ids without duplicates', () {
      final deltaJson = '''
      [
        {"insert":"Password","attributes":{"link":"vault://passwords/a1b2c3d4-e5f6-7890-abcd-ef1234567890"}},
        {"insert":"Note","attributes":{"link":"note://f1e2d3c4-b5a6-7890-abcd-ef1234567890"}},
        {"insert":"Again","attributes":{"link":"vault://passwords/a1b2c3d4-e5f6-7890-abcd-ef1234567890"}}
      ]
      ''';

      final ids = extractLinkedItemIds(deltaJson);

      expect(
        ids,
        containsAll(<String>[
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'f1e2d3c4-b5a6-7890-abcd-ef1234567890',
        ]),
      );
      expect(ids.length, 2);
    });
  });
}
