import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class ApiKeyListCard extends StatelessWidget {
  const ApiKeyListCard({
    super.key,
    required this.apiKey,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
    this.onOpenHistory,
  });

  final ApiKeyCardDto apiKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(apiKey.name),
        subtitle: Text(
          [
            apiKey.service,
            if (apiKey.environment?.isNotEmpty == true) apiKey.environment!,
            if (apiKey.tokenType?.isNotEmpty == true) apiKey.tokenType!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Избранное',
              onPressed: onToggleFavorite,
              icon: Icon(
                apiKey.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: apiKey.isFavorite ? cs.error : null,
              ),
            ),
            IconButton(
              tooltip: 'История',
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
      ),
    );
  }
}
