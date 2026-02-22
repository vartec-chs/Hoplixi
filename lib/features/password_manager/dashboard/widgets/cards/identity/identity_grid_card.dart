import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class IdentityGridCard extends StatelessWidget {
  const IdentityGridCard({
    super.key,
    required this.identity,
    this.onToggleFavorite,
  });

  final IdentityCardDto identity;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
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
                    identity.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    identity.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(identity.idType, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              identity.idNumber,
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
