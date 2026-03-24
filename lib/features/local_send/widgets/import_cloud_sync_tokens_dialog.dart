import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/local_send/models/encrypted_transfer_envelope.dart';
import 'package:hoplixi/features/local_send/services/local_send_secure_payload_crypto_service.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

Future<void> showCloudSyncTokensImportDialog(
  BuildContext context,
  WidgetRef ref, {
  required EncryptedTransferEnvelope envelope,
  String? deviceName,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) =>
        ImportCloudSyncTokensDialog(envelope: envelope, deviceName: deviceName),
  );
}

class ImportCloudSyncTokensDialog extends ConsumerStatefulWidget {
  const ImportCloudSyncTokensDialog({
    super.key,
    required this.envelope,
    this.deviceName,
  });

  final EncryptedTransferEnvelope envelope;
  final String? deviceName;

  @override
  ConsumerState<ImportCloudSyncTokensDialog> createState() =>
      _ImportCloudSyncTokensDialogState();
}

class _ImportCloudSyncTokensDialogState
    extends ConsumerState<ImportCloudSyncTokensDialog> {
  final LocalSendSecurePayloadCryptoService _cryptoService =
      const LocalSendSecurePayloadCryptoService();
  late final TextEditingController _passwordController;

  bool _isImporting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.deviceName?.trim();
    final hasDeviceName = deviceName != null && deviceName.isNotEmpty;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: const Text('Импортировать OAuth-токены'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasDeviceName
                  ? 'Получен защищённый пакет OAuth-токенов от $deviceName.'
                  : 'Получен защищённый пакет OAuth-токенов.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Для импорта введите пароль, который использовался при отправке. '
              'После успешной расшифровки токены будут добавлены в локальное хранилище cloud sync.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_isImporting,
              decoration: primaryInputDecoration(
                context,
                labelText: 'Пароль',
                hintText: 'Введите пароль защищённого пакета',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SmoothButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          label: 'Отмена',
          type: .text,
        ),
        SmoothButton(
          onPressed: _isImporting ? null : _handleImport,
          label: _isImporting ? 'Импорт...' : 'Импортировать',
          type: .filled,
        ),
      ],
    );
  }

  Future<void> _handleImport() async {
    setState(() {
      _isImporting = true;
      _errorText = null;
    });

    try {
      final payload = await _cryptoService.decryptCloudSyncTokens(
        envelope: widget.envelope,
        password: _passwordController.text.trim(),
      );
      final result = await ref
          .read(authTokensProvider.notifier)
          .importTokens(payload.tokens);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      Toaster.success(
        title: 'OAuth-токены импортированы',
        description:
            'Создано: ${result.created}, обновлено: ${result.updated}.',
      );
    } on LocalSendSecurePayloadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Не удалось импортировать OAuth-токены: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}
