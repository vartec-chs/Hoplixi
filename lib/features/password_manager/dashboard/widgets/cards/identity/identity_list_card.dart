import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class IdentityListCard extends StatelessWidget {
  const IdentityListCard({
    super.key,
    required this.identity,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final IdentityCardDto identity;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      identity.idType,
      identity.idNumber,
      if (identity.fullName?.isNotEmpty == true) identity.fullName!,
      if (identity.verified) 'verified',
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text(identity.name),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                identity.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
            ),
            IconButton(
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
      ),
    );
  }
}
