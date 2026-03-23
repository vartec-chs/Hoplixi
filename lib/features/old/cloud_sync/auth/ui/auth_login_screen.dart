import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/models/oauth_login_state.dart';
import 'package:hoplixi/features/old/cloud_sync/auth/providers/auth_login_provider.dart';
import 'package:hoplixi/features/old/cloud_sync/oauth_apps/models/oauth_apps.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// UI для OAuth авторизации с выбором провайдера
class OAuthLoginScreen extends ConsumerWidget {
  const OAuthLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(authLoginProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подключение облачного хранилища'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(authLoginProvider.notifier).reload(),
            tooltip: 'Обновить список провайдеров',
          ),
        ],
      ),
      body: loginState.when(
        data: (state) => _buildContent(context, ref, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $error'),
              const SizedBox(height: 16),
              SmoothButton(
                label: 'Повторить',
                onPressed: () => ref.read(authLoginProvider.notifier).reload(),
                type: SmoothButtonType.filled,
                variant: SmoothButtonVariant.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    OAuthLoginState state,
  ) {
    // Если токен получен - показываем успех
    if (state.loginStatus == LoginStatus.success && state.token != null) {
      return _buildSuccessView(context, ref, state);
    }

    // Если провайдер выбран - показываем экран авторизации
    if (state.selectedProviderId != null) {
      return _buildLoginView(context, ref, state);
    }

    // Показываем список провайдеров для выбора
    return _buildProviderSelection(context, ref, state);
  }

  /// Экран выбора провайдера
  Widget _buildProviderSelection(
    BuildContext context,
    WidgetRef ref,
    OAuthLoginState state,
  ) {
    if (state.availableApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет доступных провайдеров',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте OAuth приложения в настройках',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Выберите облачное хранилище',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.availableApps.length,
            itemBuilder: (context, index) {
              final app = state.availableApps[index];
              return _ProviderCard(
                app: app,
                onTap: () =>
                    ref.read(authLoginProvider.notifier).selectProvider(app.id),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Экран авторизации для выбранного провайдера
  Widget _buildLoginView(
    BuildContext context,
    WidgetRef ref,
    OAuthLoginState state,
  ) {
    final isLoading =
        state.loginStatus == LoginStatus.loggingIn ||
        state.loginStatus == LoginStatus.autoLogin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Шапка с информацией о провайдере
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: isLoading
                    ? null
                    : () => ref.read(authLoginProvider.notifier).reset(),
              ),
              const SizedBox(width: 8),
              _ProviderIcon(type: state.selectedApp!.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.selectedApp!.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      state.selectedApp!.type.name,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Сообщение об ошибке
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Список ошибок процесса авторизации
                if (state.authErrors.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ошибки авторизации:',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...state.authErrors.map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 28),
                            child: Text(
                              '• $error',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Сохраненные аккаунты
                if (state.savedAccounts.isNotEmpty) ...[
                  Text(
                    'Сохраненные аккаунты',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...state.savedAccounts.map(
                    (account) => _SavedAccountCard(
                      account: account,
                      isLoading:
                          isLoading &&
                          state.loginStatus == LoginStatus.autoLogin,
                      onTap: isLoading
                          ? null
                          : () => ref
                                .read(authLoginProvider.notifier)
                                .tryAutoLogin(account.userName),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Кнопка отмены для автоматической авторизации
                  if (isLoading && state.loginStatus == LoginStatus.autoLogin)
                    SmoothButton(
                      label: 'Отменить',
                      onPressed: () =>
                          ref.read(authLoginProvider.notifier).cancel(),
                      type: SmoothButtonType.outlined,
                      variant: SmoothButtonVariant.normal,
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ],

                // Новый вход
                Text(
                  state.savedAccounts.isEmpty
                      ? 'Авторизация'
                      : 'Добавить новый аккаунт',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Откроется окно браузера для авторизации в ${state.selectedApp!.type.name}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                if (isLoading &&
                    state.loginStatus == LoginStatus.loggingIn) ...[
                  // Кнопка отмены во время авторизации
                  SmoothButton(
                    label: 'Отменить авторизацию',
                    onPressed: () =>
                        ref.read(authLoginProvider.notifier).cancel(),
                    type: SmoothButtonType.outlined,
                    variant: SmoothButtonVariant.normal,
                  ),
                  const SizedBox(height: 12),
                  // Индикатор загрузки с текстом
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          'Ожидание авторизации в браузере...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ] else
                  SmoothButton(
                    label: 'Войти через ${state.selectedApp!.type.name}',
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authLoginProvider.notifier).login(),
                    type: SmoothButtonType.filled,

                    loading:
                        isLoading && state.loginStatus == LoginStatus.loggingIn,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Экран успешной авторизации
  Widget _buildSuccessView(
    BuildContext context,
    WidgetRef ref,
    OAuthLoginState state,
  ) {
    // Показываем toast об успехе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Toaster.success(
        title: 'Успешная авторизация',
        description: 'Подключен аккаунт: ${state.token!.userName}',
      );
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Успешная авторизация',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.selectedApp!.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Аккаунт: ${state.token!.userName}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          SmoothButton(
            label: 'Готово',
            onPressed: () => Navigator.of(context).pop(state.token),
            type: SmoothButtonType.filled,
          ),
          const SizedBox(height: 8),
          SmoothButton(
            label: 'Подключить другой аккаунт',
            onPressed: () => ref.read(authLoginProvider.notifier).reset(),
            type: SmoothButtonType.text,
            variant: SmoothButtonVariant.normal,
          ),
        ],
      ),
    );
  }
}

/// Карточка провайдера для выбора
class _ProviderCard extends StatelessWidget {
  final OauthApps app;
  final VoidCallback onTap;

  const _ProviderCard({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ProviderIcon(type: app.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      app.type.name,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Иконка провайдера
class _ProviderIcon extends StatelessWidget {
  final OauthAppsType type;

  const _ProviderIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      OauthAppsType.google => (Icons.cloud, Colors.blue),
      OauthAppsType.dropbox => (Icons.cloud_queue, const Color(0xFF0061FF)),
      OauthAppsType.onedrive => (Icons.cloud_circle, const Color(0xFF0078D4)),
      OauthAppsType.yandex => (Icons.cloud_done, Colors.red),
      OauthAppsType.other => (Icons.cloud_outlined, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

/// Карточка сохраненного аккаунта
class _SavedAccountCard extends StatelessWidget {
  final SavedAccount account;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SavedAccountCard({
    required this.account,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.userName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.login, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
