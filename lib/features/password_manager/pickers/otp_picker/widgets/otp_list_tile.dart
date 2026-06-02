import 'package:flutter/material.dart';
import 'package:hoplixi/vault_db/core/models/dto/dto.dart';

/// Элемент списка OTP
class OtpListTile extends StatelessWidget {
  final OtpCardDto otp;
  final VoidCallback onTap;
  final Widget? trailing;

  const OtpListTile({
    super.key,
    required this.otp,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final title = otp.data.issuer ?? otp.data.accountName ?? otp.item.name;
    final subtitle = otp.data.issuer != null ? otp.data.accountName : null;

    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.timer,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      trailing:
          trailing ??
          (otp.item.isFavorite
              ? Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                )
              : null),
      onTap: onTap,
    );
  }
}
