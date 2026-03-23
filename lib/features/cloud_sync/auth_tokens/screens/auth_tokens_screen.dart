import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/widgets/auth_token_card.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/widgets/auth_token_details_sheet.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/widgets/auth_tokens_empty_state.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

/// Экран просмотра сохранённых OAuth токенов.
class AuthTokensScreen extends ConsumerWidget {
  const AuthTokensScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.t.cloud_sync_auth_tokens;
    final asyncTokens = ref.watch(authTokensProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screen_title)),
      body: SafeArea(
        child: asyncTokens.when(
          data: (tokens) {
            if (tokens.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoNotificationCard(text: l10n.screen_description),
                    const SizedBox(height: 16),
                    AuthTokensEmptyState(
                      onReloadPressed: () {
                        ref.read(authTokensProvider.notifier).reload();
                      },
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(authTokensProvider.notifier).reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InfoNotificationCard(text: l10n.screen_description),
                  const SizedBox(height: 16),
                  ...tokens.map(
                    (token) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AuthTokenCard(
                        token: token,
                        onTap: () async {
                          await showAuthTokenDetailsSheet(
                            context: context,
                            token: token,
                            onDelete: () async {
                              try {
                                await ref
                                    .read(authTokensProvider.notifier)
                                    .deleteToken(token.id);
                                Toaster.success(
                                  title: l10n.delete_success_title,
                                  description: l10n.delete_success_description,
                                );
                              } catch (_) {
                                Toaster.error(
                                  title: l10n.delete_error_title,
                                  description: l10n.delete_error_description,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorNotificationCard(text: l10n.load_error_description),
                    const SizedBox(height: 16),
                    SmoothButton(
                      label: l10n.reload_button,
                      onPressed: () {
                        ref.read(authTokensProvider.notifier).reload();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
