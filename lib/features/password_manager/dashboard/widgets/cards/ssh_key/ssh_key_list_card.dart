import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class SshKeyListCard extends StatelessWidget {
  const SshKeyListCard({
    super.key,
    required this.sshKey,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final SshKeyCardDto sshKey;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(sshKey.name),
        subtitle: Text(
          [
            if (sshKey.keyType?.isNotEmpty == true) sshKey.keyType!,
            if (sshKey.fingerprint?.isNotEmpty == true) sshKey.fingerprint!,
            if (sshKey.usage?.isNotEmpty == true) sshKey.usage!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                sshKey.isFavorite ? Icons.favorite : Icons.favorite_border,
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
