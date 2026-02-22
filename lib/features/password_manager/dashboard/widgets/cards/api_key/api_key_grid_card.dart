import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class ApiKeyGridCard extends StatelessWidget {
  const ApiKeyGridCard({
    super.key,
    required this.apiKey,
    this.onToggleFavorite,
    this.onTogglePin,
    this.onToggleArchive,
    this.onDelete,
    this.onRestore,
  });

  final ApiKeyCardDto apiKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    apiKey.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    apiKey.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: apiKey.isFavorite ? cs.error : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(apiKey.service, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              apiKey.maskedKey ?? '••••••••',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
