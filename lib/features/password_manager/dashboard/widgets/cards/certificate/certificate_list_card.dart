import 'package:flutter/material.dart';
import 'package:hoplixi/main_store/models/dto/index.dart';

class CertificateListCard extends StatelessWidget {
  const CertificateListCard({
    super.key,
    required this.certificate,
    this.onToggleFavorite,
    this.onOpenHistory,
  });

  final CertificateCardDto certificate;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (certificate.issuer?.isNotEmpty == true) certificate.issuer!,
      if (certificate.subject?.isNotEmpty == true) certificate.subject!,
      if (certificate.fingerprint?.isNotEmpty == true) certificate.fingerprint!,
    ].join(' • ');

    return Card(
      child: ListTile(
        title: Text(certificate.name),
        subtitle: Text(
          subtitle.isEmpty ? 'Сертификат' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                certificate.isFavorite ? Icons.favorite : Icons.favorite_border,
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
