import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';

class AuthProviderListTile extends StatelessWidget {
  const AuthProviderListTile({
    super.key,
    required this.provider,
    required this.onTap,
  });

  final CloudSyncProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = provider.metadata;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(metadata.icon),
        title: Text(metadata.displayName),
        subtitle: Text(
          metadata.scopes.isEmpty ? provider.id : metadata.scopes.first,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
