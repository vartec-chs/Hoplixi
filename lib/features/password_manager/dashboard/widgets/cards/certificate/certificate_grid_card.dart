import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class CertificateGridCard extends StatelessWidget {
  const CertificateGridCard({
    super.key,
    required this.certificate,
    this.onToggleFavorite,
  });

  final CertificateCardDto certificate;
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
                    certificate.name,
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
                    certificate.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              certificate.issuer ?? 'Unknown issuer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              certificate.validTo != null
                  ? 'Valid to: ${certificate.validTo!.toIso8601String().split('T').first}'
                  : 'No expiry date',
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
