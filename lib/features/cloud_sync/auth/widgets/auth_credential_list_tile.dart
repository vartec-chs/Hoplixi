import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/auth/models/auth_credential_option.dart';

class AuthCredentialListTile extends StatelessWidget {
  const AuthCredentialListTile({
    super.key,
    required this.option,
    required this.builtinLabel,
    required this.customLabel,
    this.unavailableReason,
    this.onTap,
  });

  final AuthCredentialOption option;
  final String builtinLabel;
  final String customLabel;
  final String? unavailableReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = option.entry;
    final isEnabled = option.isSupported && onTap != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          enabled: isEnabled,
          onTap: isEnabled ? onTap : null,
          title: Text(entry.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.clientId),
              if (unavailableReason != null && unavailableReason!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    unavailableReason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              entry.isBuiltin ? builtinLabel : customLabel,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}
