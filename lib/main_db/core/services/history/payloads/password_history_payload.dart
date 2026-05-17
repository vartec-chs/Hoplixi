import '../../../tables/vault_items/vault_items.dart';
import '../models/history_field_snapshot.dart';
import '../models/history_payload.dart';

class PasswordHistoryPayload extends HistoryPayload {
  const PasswordHistoryPayload({
    this.login,
    this.email,
    this.password,
    this.url,
    this.expiresAt,
  });

  final String? login;
  final String? email;
  final String? password;
  final String? url;
  final DateTime? expiresAt;

  @override
  VaultItemType get type => VaultItemType.password;

  @override
  List<HistoryFieldSnapshot<Object?>> diffFields() {
    return [
      HistoryFieldSnapshot<String>(
        key: 'password.login',
        label: 'Login',
        value: login,
      ),
      HistoryFieldSnapshot<String>(
        key: 'password.email',
        label: 'Email',
        value: email,
      ),
      HistoryFieldSnapshot<String>(
        key: 'password.password',
        label: 'Password',
        value: password,
        isSensitive: true,
      ),
      HistoryFieldSnapshot<String>(
        key: 'password.url',
        label: 'URL',
        value: url,
      ),
      HistoryFieldSnapshot<DateTime>(
        key: 'password.expiresAt',
        label: 'Expires at',
        value: expiresAt,
      ),
    ];
  }
}
