class ParsedVaultLink {
  const ParsedVaultLink({
    required this.itemId,
    this.entityId,
    this.isLegacyNoteLink = false,
  });

  final String itemId;
  final String? entityId;
  final bool isLegacyNoteLink;
}

final RegExp _vaultLinkPattern = RegExp(r'vault://([a-z_]+)/([a-f0-9-]+)');
final RegExp _legacyNoteLinkPattern = RegExp(r'note://([a-f0-9-]+)');

String buildVaultItemLinkUrl({
  required String entityId,
  required String itemId,
}) => 'vault://$entityId/$itemId';

ParsedVaultLink? parseVaultLink(String rawValue) {
  final vaultMatch = _vaultLinkPattern.firstMatch(rawValue);
  if (vaultMatch != null) {
    return ParsedVaultLink(
      entityId: vaultMatch.group(1),
      itemId: vaultMatch.group(2)!,
    );
  }

  final legacyMatch = _legacyNoteLinkPattern.firstMatch(rawValue);
  if (legacyMatch != null) {
    return ParsedVaultLink(
      entityId: 'notes',
      itemId: legacyMatch.group(1)!,
      isLegacyNoteLink: true,
    );
  }

  return null;
}

List<String> extractLinkedItemIds(String rawValue) {
  final ids = <String>{};

  for (final match in _vaultLinkPattern.allMatches(rawValue)) {
    final itemId = match.group(2);
    if (itemId != null) {
      ids.add(itemId);
    }
  }

  for (final match in _legacyNoteLinkPattern.allMatches(rawValue)) {
    final itemId = match.group(1);
    if (itemId != null) {
      ids.add(itemId);
    }
  }

  return ids.toList();
}
