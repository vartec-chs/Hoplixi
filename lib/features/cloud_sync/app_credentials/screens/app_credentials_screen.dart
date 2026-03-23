import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/providers/app_credentials_provider.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/screens/app_credential_editor_screen.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/widgets/app_credential_list_tile.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/widgets/app_credentials_empty_state.dart';
import 'package:hoplixi/generated/l10n/translations.g.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/notification_card.dart';

/// Экран управления OAuth app credentials.
class AppCredentialsScreen extends ConsumerWidget {
  const AppCredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.t.cloud_sync_app_credentials;
    final asyncEntries = ref.watch(appCredentialsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screen_title)),
      body: SafeArea(
        child: asyncEntries.when(
          data: (entries) => _Content(entries: entries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
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
                        ref.read(appCredentialsProvider.notifier).reload();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.add_button),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    AppCredentialEntry? entry,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppCredentialEditorScreen(initialEntry: entry),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.entries});

  final List<AppCredentialEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.t.cloud_sync_app_credentials;
    final builtinEntries = entries.where((entry) => entry.isBuiltin).toList();
    final userEntries = entries.where((entry) => !entry.isBuiltin).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(appCredentialsProvider.notifier).reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoNotificationCard(text: l10n.screen_description),
          const SizedBox(height: 16),
          _SectionHeader(
            title: l10n.builtin_section_title,
            subtitle: l10n.builtin_section_description,
          ),
          const SizedBox(height: 8),
          if (builtinEntries.isEmpty)
            Text(l10n.builtin_empty_description)
          else
            ...builtinEntries.map(
              (entry) => AppCredentialListTile(entry: entry),
            ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: l10n.custom_section_title,
            subtitle: l10n.custom_section_description,
          ),
          const SizedBox(height: 8),
          if (userEntries.isEmpty)
            AppCredentialsEmptyState(
              onCreatePressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppCredentialEditorScreen(),
                  ),
                );
              },
            )
          else
            ...userEntries.map(
              (entry) => AppCredentialListTile(
                entry: entry,
                onEdit: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AppCredentialEditorScreen(initialEntry: entry),
                    ),
                  );
                },
                onDelete: () async {
                  await _confirmDelete(context, ref, entry);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppCredentialEntry entry,
  ) async {
    final l10n = context.t.cloud_sync_app_credentials;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.delete_dialog_title),
          content: Text(l10n.delete_dialog_description(Name: entry.name)),
          actions: [
            SmoothButton(
              label: l10n.cancel_button,
              type: SmoothButtonType.text,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            SmoothButton(
              label: l10n.delete_action,
              variant: SmoothButtonVariant.error,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(appCredentialsProvider.notifier).deleteUserEntry(entry.id);
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
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
