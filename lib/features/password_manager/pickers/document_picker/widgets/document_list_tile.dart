import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

/// Элемент списка документов в пикере
class DocumentListTile extends StatelessWidget {
  final DocumentCardDto document;
  final VoidCallback onTap;
  final Widget? trailing;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.onTap,
    this.trailing,
  });

  String? _buildSubtitle() {
    final parts = <String>[];
    if (document.document.documentType != null) {
      parts.add(document.document.documentType!.name);
    }
    if ((document.document.pageCount ?? 0) > 0) {
      parts.add('${document.document.pageCount} стр.');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = _buildSubtitle();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.description_outlined,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        document.item.name,
        style: textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing:
          trailing ??
          (document.item.isFavorite
              ? Icon(Icons.star, color: colorScheme.primary, size: 20)
              : null),
      onTap: onTap,
    );
  }
}
