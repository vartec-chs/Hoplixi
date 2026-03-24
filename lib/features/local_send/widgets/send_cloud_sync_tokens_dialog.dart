import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/local_send/models/cloud_sync_tokens_transfer_payload.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class SendCloudSyncTokensDialogResult {
  const SendCloudSyncTokensDialogResult({
    required this.password,
    required this.tokens,
    required this.exportMode,
  });

  final String password;
  final List<AuthTokenEntry> tokens;
  final CloudSyncTokenExportMode exportMode;
}

class SendCloudSyncTokensDialog extends ConsumerStatefulWidget {
  const SendCloudSyncTokensDialog({super.key});

  @override
  ConsumerState<SendCloudSyncTokensDialog> createState() =>
      _SendCloudSyncTokensDialogState();
}

class _SendCloudSyncTokensDialogState
    extends ConsumerState<SendCloudSyncTokensDialog> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  int _step = 0;
  String? _passwordError;
  CloudSyncTokenExportMode _exportMode =
      CloudSyncTokenExportMode.withoutRefresh;
  final Set<String> _selectedTokenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokensAsync = ref.watch(authTokensProvider);
    final tokens = tokensAsync.value ?? const <AuthTokenEntry>[];

    return AlertDialog(
      insetPadding: const EdgeInsets.all(12),
      title: Text(_titleForStep()),
      content: SizedBox(
        width: 520,
        child: switch (_step) {
          0 => _buildWarningStep(context),
          1 => _buildPasswordStep(context),
          _ => _buildSelectionStep(context, tokensAsync, tokens),
        },
      ),
      actions: _buildActions(context, tokens),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    List<AuthTokenEntry> tokens,
  ) {
    final actions = <Widget>[
      SmoothButton(
        onPressed: () => Navigator.pop(context),
        label: _step == 0 ? 'Отмена' : 'Закрыть',
        type: .text,
      ),
    ];

    if (_step > 0) {
      actions.add(
        SmoothButton(
          onPressed: () {
            setState(() {
              _passwordError = null;
              _step -= 1;
            });
          },
          label: 'Назад',
          type: .text,
        ),
      );
    }

    if (_step < 2) {
      actions.add(
        SmoothButton(
          onPressed: () => _handleNext(tokens),
          label: 'Далее',
          type: .filled,
        ),
      );
    } else {
      actions.add(
        SmoothButton(
          onPressed: _selectedTokenIds.isEmpty
              ? null
              : () {
                  final selectedTokens = tokens
                      .where((token) => _selectedTokenIds.contains(token.id))
                      .toList(growable: false);
                  Navigator.pop(
                    context,
                    SendCloudSyncTokensDialogResult(
                      password: _passwordController.text.trim(),
                      tokens: selectedTokens,
                      exportMode: _exportMode,
                    ),
                  );
                },
          label: 'Отправить',
          type: .filled,
        ),
      );
    }

    return actions;
  }

  Widget _buildWarningStep(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                  const SizedBox(width: 10),
                  Text(
                    'Опасная операция',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'OAuth-токены дают доступ к вашим облачным аккаунтам. '
                'Передавайте их только на доверенное устройство и только через '
                'пароль, который получатель знает заранее.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'На следующем шаге нужно придумать пароль для шифрования пакета. '
          'Без него получатель не сможет импортировать токены.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Пароль',
            hintText: 'Минимум 8 символов',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Подтвердите пароль',
            hintText: 'Повторите пароль для шифрования',
          ),
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 12),
          Text(
            _passwordError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionStep(
    BuildContext context,
    AsyncValue<List<AuthTokenEntry>> tokensAsync,
    List<AuthTokenEntry> tokens,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выберите, что именно отправить получателю.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SegmentedButton<CloudSyncTokenExportMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment<CloudSyncTokenExportMode>(
              value: CloudSyncTokenExportMode.withoutRefresh,
              label: Text('Без refresh'),
              icon: Icon(Icons.shield_outlined),
            ),
            ButtonSegment<CloudSyncTokenExportMode>(
              value: CloudSyncTokenExportMode.full,
              label: Text('Полный экспорт'),
              icon: Icon(Icons.key_outlined),
            ),
          ],
          selected: <CloudSyncTokenExportMode>{_exportMode},
          onSelectionChanged: (selection) {
            setState(() {
              _exportMode = selection.first;
            });
          },
        ),
        const SizedBox(height: 12),
        Text(
          _exportMode == CloudSyncTokenExportMode.withoutRefresh
              ? 'Рекомендуется. Переносится access token и служебные данные без refresh token.'
              : 'Передаёт access token, refresh token и весь сохранённый набор полей.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        tokensAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 220,
            child: Center(
              child: Text('Не удалось загрузить OAuth-токены: $error'),
            ),
          ),
          data: (loadedTokens) {
            if (loadedTokens.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'В cloud sync ещё нет сохранённых OAuth-токенов для отправки.',
                  ),
                ),
              );
            }

            return SizedBox(
              height: 260,
              child: Column(
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTokenIds
                              ..clear()
                              ..addAll(loadedTokens.map((token) => token.id));
                          });
                        },
                        child: const Text('Выбрать все'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(_selectedTokenIds.clear);
                        },
                        child: const Text('Снять выбор'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: loadedTokens.length,
                      itemBuilder: (context, index) {
                        final token = loadedTokens[index];
                        final isSelected = _selectedTokenIds.contains(token.id);

                        return CheckboxListTile(
                          value: isSelected,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selectedTokenIds.add(token.id);
                              } else {
                                _selectedTokenIds.remove(token.id);
                              }
                            });
                          },
                          title: Text(token.displayLabel),
                          subtitle: Text(
                            '${token.provider.metadata.displayName}'
                            '${token.hasRefreshToken ? ' • есть refresh token' : ' • без refresh token'}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleNext(List<AuthTokenEntry> tokens) {
    if (_step == 1) {
      final password = _passwordController.text.trim();
      final confirmation = _confirmPasswordController.text.trim();
      if (password.length < 8) {
        setState(() {
          _passwordError = 'Пароль должен быть не короче 8 символов.';
        });
        return;
      }
      if (password != confirmation) {
        setState(() {
          _passwordError = 'Пароли не совпадают.';
        });
        return;
      }
    }

    setState(() {
      _passwordError = null;
      _step += 1;
      if (_step == 2 && tokens.isNotEmpty && _selectedTokenIds.isEmpty) {
        _selectedTokenIds.add(tokens.first.id);
      }
    });
  }

  String _titleForStep() {
    return switch (_step) {
      0 => 'Отправить OAuth-токены',
      1 => 'Пароль для шифрования',
      _ => 'Выбор OAuth-токенов',
    };
  }
}
