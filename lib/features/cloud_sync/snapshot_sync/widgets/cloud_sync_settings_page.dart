import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth/widgets/show_cloud_sync_auth_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/common/models/cloud_sync_provider.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/models/snapshot_sync_models.dart';
import 'package:hoplixi/features/cloud_sync/snapshot_sync/providers/current_store_sync_provider.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';

class CloudSyncSettingsPage extends ConsumerStatefulWidget {
  const CloudSyncSettingsPage({super.key});

  @override
  ConsumerState<CloudSyncSettingsPage> createState() =>
      _CloudSyncSettingsPageState();
}

class _CloudSyncSettingsPageState extends ConsumerState<CloudSyncSettingsPage> {
  CloudSyncProvider? _selectedProvider;
  String? _selectedTokenId;
  String? _pendingActionKey;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(currentStoreSyncProvider);
    final tokensAsync = ref.watch(authTokensProvider);

    return syncState.when(
      data: (status) {
        final tokens = tokensAsync.value ?? const <AuthTokenEntry>[];
        final effectiveProvider = _resolveEffectiveProvider(status, tokens);
        final providerTokens = _tokensForProvider(tokens, effectiveProvider);
        final effectiveTokenId = _resolveEffectiveTokenId(
          status,
          providerTokens,
        );
        final selectedToken = providerTokens
            .where((token) => token.id == effectiveTokenId)
            .firstOrNull;
        final isConnected = status.binding != null;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Синхронизация с облаком',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isConnected
                      ? 'Хранилище уже подключено. Здесь можно посмотреть статус и выполнить следующую синхронизацию.'
                      : 'Сначала авторизуйте облачный аккаунт, затем привяжите текущее хранилище. После подключения появятся действия для первой синхронизации.',
                ),
                const SizedBox(height: 12),
                _ConnectionSummaryCard(
                  status: status,
                  token: status.token ?? selectedToken,
                ),
                const SizedBox(height: 12),
                if (!isConnected) ...[
                  _buildSetupFlow(
                    context,
                    effectiveProvider: effectiveProvider,
                    providerTokens: providerTokens,
                    effectiveTokenId: effectiveTokenId,
                  ),
                ] else ...[
                  _buildConnectedFlow(
                    context,
                    status: status,
                    selectedToken: status.token ?? selectedToken,
                    effectiveProvider: effectiveProvider,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Ошибка синхронизации: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupFlow(
    BuildContext context, {
    required CloudSyncProvider? effectiveProvider,
    required List<AuthTokenEntry> providerTokens,
    required String? effectiveTokenId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepCard(
          step: 'Шаг 1',
          title: 'Выберите облачный сервис',
          description:
              'Выберите сервис, в котором будет храниться snapshot текущего хранилища.',
          child: DropdownButtonFormField<CloudSyncProvider>(
            initialValue: effectiveProvider,
            decoration: primaryInputDecoration(
              context,
              labelText: 'Облачный сервис',
            ),
            items: CloudSyncProvider.values
                .where((provider) => provider != CloudSyncProvider.other)
                .map(
                  (provider) => DropdownMenuItem<CloudSyncProvider>(
                    value: provider,
                    child: Text(provider.metadata.displayName),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              setState(() {
                _selectedProvider = value;
                _selectedTokenId = null;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 'Шаг 2',
          title: 'Авторизуйте аккаунт',
          description: providerTokens.isEmpty
              ? 'Для выбранного сервиса ещё нет OAuth-токена. Нажмите кнопку ниже и завершите авторизацию.'
              : 'Аккаунт уже авторизован. Можно выбрать токен и перейти к подключению.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (providerTokens.isEmpty)
                SmoothButton(
                  label: 'Авторизовать аккаунт',
                  onPressed: effectiveProvider == null
                      ? null
                      : () async {
                          await showCloudSyncAuthSheet(
                            context: context,
                            ref: ref,
                            previousRoute: _resolvePreviousRoute(context),
                            initialProvider: effectiveProvider,
                          );
                          ref.invalidate(authTokensProvider);
                          await ref.read(authTokensProvider.notifier).reload();
                          if (mounted) {
                            await ref
                                .read(currentStoreSyncProvider.notifier)
                                .loadStatus();
                          }
                        },
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: effectiveTokenId,
                  decoration: primaryInputDecoration(
                    context,
                    labelText: 'Подключаемый аккаунт',
                  ),
                  items: providerTokens
                      .map(
                        (token) => DropdownMenuItem<String>(
                          value: token.id,
                          child: Text(token.displayLabel),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _selectedTokenId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SmoothButton(
                  label: 'Авторизовать ещё один аккаунт',
                  type: SmoothButtonType.outlined,
                  onPressed: effectiveProvider == null
                      ? null
                      : () async {
                          await showCloudSyncAuthSheet(
                            context: context,
                            ref: ref,
                            previousRoute: _resolvePreviousRoute(context),
                            initialProvider: effectiveProvider,
                          );
                          ref.invalidate(authTokensProvider);
                          await ref.read(authTokensProvider.notifier).reload();
                          if (mounted) {
                            await ref
                                .read(currentStoreSyncProvider.notifier)
                                .loadStatus();
                          }
                        },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 'Шаг 3',
          title: 'Подключите хранилище',
          description: providerTokens.isEmpty
              ? 'Сначала завершите авторизацию. После этого здесь появится кнопка подключения.'
              : 'Подключение создаст облачную структуру папок для текущего хранилища и подготовит первую синхронизацию.',
          child: SmoothButton(
            label: 'Подключить синхронизацию',
            loading: _pendingActionKey == 'connect',
            onPressed: providerTokens.isEmpty || _pendingActionKey != null
                ? null
                : () async {
                    final selectedTokenId = effectiveTokenId;
                    if (selectedTokenId == null) {
                      Toaster.error(
                        title: 'Синхронизация с облаком',
                        description:
                            'Выберите OAuth-токен для подключения хранилища.',
                      );
                      return;
                    }
                    await _runAction(
                      'connect',
                      () => ref
                          .read(currentStoreSyncProvider.notifier)
                          .connect(selectedTokenId),
                    );
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedFlow(
    BuildContext context, {
    required StoreSyncStatus status,
    required AuthTokenEntry? selectedToken,
    required CloudSyncProvider? effectiveProvider,
  }) {
    final primaryAction = _buildPrimaryAction(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepCard(
          step: 'Подключено',
          title: 'Хранилище привязано к облаку',
          description: _statusDescription(status),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (primaryAction != null) primaryAction,
              if (primaryAction != null) const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SmoothButton(
                    label: 'Обновить статус',
                    type: SmoothButtonType.outlined,
                    loading: _pendingActionKey == 'refreshStatus',
                    onPressed: _pendingActionKey != null
                        ? null
                        : () => _runAction(
                            'refreshStatus',
                            () => ref
                                .read(currentStoreSyncProvider.notifier)
                                .loadStatus(),
                          ),
                  ),
                  SmoothButton(
                    label: 'Переподключить аккаунт',
                    type: SmoothButtonType.outlined,
                    onPressed: effectiveProvider == null
                        ? null
                        : () async {
                            await showCloudSyncAuthSheet(
                              context: context,
                              ref: ref,
                              previousRoute: _resolvePreviousRoute(context),
                              initialProvider: effectiveProvider,
                            );
                            ref.invalidate(authTokensProvider);
                            await ref
                                .read(authTokensProvider.notifier)
                                .reload();
                            if (mounted) {
                              await ref
                                  .read(currentStoreSyncProvider.notifier)
                                  .loadStatus();
                            }
                          },
                  ),
                  SmoothButton(
                    label: 'Отключить',
                    type: SmoothButtonType.outlined,
                    variant: SmoothButtonVariant.warning,
                    loading: _pendingActionKey == 'disconnect',
                    onPressed: _pendingActionKey != null
                        ? null
                        : () => _runAction(
                            'disconnect',
                            () => ref
                                .read(currentStoreSyncProvider.notifier)
                                .disconnect(),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 'Состояние',
          title: 'Текущий статус синхронизации',
          description:
              'Проверьте ревизии и решите, какое действие нужно дальше.',
          child: _StatusCard(status: status, token: selectedToken),
        ),
      ],
    );
  }

  Widget? _buildPrimaryAction(StoreSyncStatus status) {
    final notifier = ref.read(currentStoreSyncProvider.notifier);
    return switch (status.compareResult) {
      StoreVersionCompareResult.remoteMissing ||
      StoreVersionCompareResult.localNewer => SmoothButton(
        label: 'Загрузить локальную версию в облако',
        loading: _pendingActionKey == 'sync',
        onPressed: _pendingActionKey != null
            ? null
            : () => _runAction('sync', () => notifier.syncNow()),
      ),
      StoreVersionCompareResult.same => SmoothButton(
        label: 'Проверить синхронизацию сейчас',
        loading: _pendingActionKey == 'sync',
        onPressed: _pendingActionKey != null
            ? null
            : () => _runAction('sync', () => notifier.syncNow()),
      ),
      StoreVersionCompareResult.remoteNewer => SmoothButton(
        label: 'Скачать удалённую версию',
        loading: _pendingActionKey == 'downloadRemote',
        onPressed: _pendingActionKey != null
            ? null
            : () => _runAction(
                'downloadRemote',
                () => notifier.resolveConflictWithDownload(),
              ),
      ),
      StoreVersionCompareResult.conflict => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SmoothButton(
            label: 'Оставить локальную версию',
            loading: _pendingActionKey == 'uploadConflict',
            onPressed: _pendingActionKey != null
                ? null
                : () => _runAction(
                    'uploadConflict',
                    () => notifier.resolveConflictWithUpload(),
                  ),
          ),
          SmoothButton(
            label: 'Принять удалённую версию',
            type: SmoothButtonType.outlined,
            loading: _pendingActionKey == 'downloadConflict',
            onPressed: _pendingActionKey != null
                ? null
                : () => _runAction(
                    'downloadConflict',
                    () => notifier.resolveConflictWithDownload(),
                  ),
          ),
        ],
      ),
      StoreVersionCompareResult.differentStore => null,
    };
  }

  CloudSyncProvider? _resolveEffectiveProvider(
    StoreSyncStatus status,
    List<AuthTokenEntry> tokens,
  ) {
    return _selectedProvider ??
        status.binding?.provider ??
        status.token?.provider ??
        (tokens.isNotEmpty ? tokens.first.provider : null);
  }

  List<AuthTokenEntry> _tokensForProvider(
    List<AuthTokenEntry> tokens,
    CloudSyncProvider? provider,
  ) {
    if (provider == null) {
      return const <AuthTokenEntry>[];
    }
    return tokens
        .where((token) => token.provider == provider)
        .toList(growable: false);
  }

  String? _resolveEffectiveTokenId(
    StoreSyncStatus status,
    List<AuthTokenEntry> providerTokens,
  ) {
    final candidate =
        _selectedTokenId ?? status.binding?.tokenId ?? status.token?.id;
    if (candidate != null &&
        providerTokens.any((token) => token.id == candidate)) {
      return candidate;
    }
    return providerTokens.isNotEmpty ? providerTokens.first.id : null;
  }

  String _statusDescription(StoreSyncStatus status) {
    return switch (status.compareResult) {
      StoreVersionCompareResult.remoteMissing =>
        'В облаке ещё нет snapshot этого хранилища. Следующий шаг: отправить локальную версию.',
      StoreVersionCompareResult.localNewer =>
        'Локальная версия новее облачной. Следующий шаг: загрузить актуальный snapshot в облако.',
      StoreVersionCompareResult.same =>
        'Локальная и облачная версии совпадают. Можно просто запускать ручную синхронизацию по необходимости.',
      StoreVersionCompareResult.remoteNewer =>
        'В облаке есть более новая версия. Следующий шаг: скачать её в локальное хранилище.',
      StoreVersionCompareResult.conflict =>
        'Обнаружен конфликт: и локальная, и облачная версии были изменены. Выберите, какую версию оставить.',
      StoreVersionCompareResult.differentStore =>
        'Обнаружено несоответствие идентификаторов хранилища. Переподключите синхронизацию.',
    };
  }

  Future<void> _runAction(
    String actionKey,
    Future<void> Function() action,
  ) async {
    if (_pendingActionKey != null) {
      return;
    }
    setState(() {
      _pendingActionKey = actionKey;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      final status = ref.read(currentStoreSyncProvider).value;
      final description = switch (status?.lastResultType) {
        SnapshotSyncResultType.uploaded =>
          'Локальная snapshot-версия загружена в облако.',
        SnapshotSyncResultType.downloaded =>
          status?.requiresUnlockToApply == true
              ? 'Удалённый snapshot загружен. Разблокируйте хранилище, чтобы продолжить работу.'
              : 'Удалённый snapshot загружен.',
        SnapshotSyncResultType.noChanges =>
          'Локальная и удалённая версии уже совпадают.',
        SnapshotSyncResultType.conflict => 'Обнаружен конфликт версий.',
        _ => 'Операция выполнена.',
      };
      Toaster.success(
        title: 'Синхронизация с облаком',
        description: description,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Toaster.error(
        title: 'Синхронизация с облаком',
        description: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingActionKey = null;
        });
      }
    }
  }

  String _resolvePreviousRoute(BuildContext context) {
    try {
      return GoRouter.of(context).state.uri.toString();
    } catch (_) {
      return AppRoutesPaths.cloudSync;
    }
  }
}

class _ConnectionSummaryCard extends StatelessWidget {
  const _ConnectionSummaryCard({required this.status, required this.token});

  final StoreSyncStatus status;
  final AuthTokenEntry? token;

  @override
  Widget build(BuildContext context) {
    final isConnected = status.binding != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: isConnected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Подключено' : 'Не подключено',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Хранилище: ${status.storeName ?? 'Не выбрано'}'),
            Text(
              'Провайдер: ${status.binding?.provider.metadata.displayName ?? token?.provider.metadata.displayName ?? 'Не выбран'}',
            ),
            Text('Аккаунт: ${token?.displayLabel ?? 'Не авторизован'}'),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.child,
  });

  final String step;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.token});

  final StoreSyncStatus status;
  final AuthTokenEntry? token;

  @override
  Widget build(BuildContext context) {
    final localManifest = status.localManifest;
    final remoteManifest = status.remoteManifest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Хранилище: ${status.storeName ?? '—'}'),
        const SizedBox(height: 8),
        Text(
          'Провайдер: ${status.binding?.provider.metadata.displayName ?? '—'}',
        ),
        Text('Аккаунт: ${token?.displayLabel ?? '—'}'),
        const SizedBox(height: 12),
        Text('Локальная ревизия: ${localManifest?.revision ?? '—'}'),
        Text('Удалённая ревизия: ${remoteManifest?.revision ?? '—'}'),
        Text('Состояние: ${_compareResultLabel(status.compareResult)}'),
        Text(
          'Последняя успешная синхронизация: ${_formatSyncTime(localManifest?.sync?.syncedAt)}',
        ),
        if (status.requiresUnlockToApply) ...[
          const SizedBox(height: 8),
          const Text(
            'Удалённый snapshot уже записан локально. Разблокируйте хранилище, чтобы продолжить работу.',
          ),
        ],
      ],
    );
  }

  String _compareResultLabel(StoreVersionCompareResult result) {
    return switch (result) {
      StoreVersionCompareResult.differentStore => 'Несоответствие хранилища',
      StoreVersionCompareResult.same => 'Версии совпадают',
      StoreVersionCompareResult.localNewer => 'Локальная версия новее',
      StoreVersionCompareResult.remoteNewer => 'Удалённая версия новее',
      StoreVersionCompareResult.conflict => 'Конфликт версий',
      StoreVersionCompareResult.remoteMissing => 'Удалённой версии ещё нет',
    };
  }

  String _formatSyncTime(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return value.toLocal().toIso8601String();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
