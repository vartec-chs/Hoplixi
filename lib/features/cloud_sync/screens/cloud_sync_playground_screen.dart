import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/models/app_credential_entry.dart';
import 'package:hoplixi/features/cloud_sync/app_credentials/providers/app_credentials_provider.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/models/auth_token_entry.dart';
import 'package:hoplixi/features/cloud_sync/auth_tokens/providers/auth_tokens_provider.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_access_panel.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_drive_storage_panel.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_health_panel.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_playground_header.dart';
import 'package:hoplixi/features/cloud_sync/playground/widgets/cloud_sync_provider_readiness_panel.dart';
import 'package:hoplixi/routing/paths.dart';

class CloudSyncPlaygroundScreen extends ConsumerWidget {
  const CloudSyncPlaygroundScreen({super.key});

  static const double _desktopBreakpoint = 1100;
  static const double _maxDesktopContentWidth = 1380;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsAsync = ref.watch(appCredentialsProvider);
    final tokensAsync = ref.watch(authTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRoutesPaths.home);
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(appCredentialsProvider.notifier).reload(),
              ref.read(authTokensProvider.notifier).reload(),
            ]);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxDesktopContentWidth,
                    ),
                    child: isDesktop
                        ? _DesktopCloudSyncLayout(
                            credentialsAsync: credentialsAsync,
                            tokensAsync: tokensAsync,
                          )
                        : _CompactCloudSyncLayout(
                            credentialsAsync: credentialsAsync,
                            tokensAsync: tokensAsync,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DesktopCloudSyncLayout extends StatelessWidget {
  const _DesktopCloudSyncLayout({
    required this.credentialsAsync,
    required this.tokensAsync,
  });

  final AsyncValue<List<AppCredentialEntry>> credentialsAsync;
  final AsyncValue<List<AuthTokenEntry>> tokensAsync;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CloudSyncPlaygroundHeader(isDesktop: true),
              const SizedBox(height: 20),
              CloudSyncProviderReadinessPanel(
                credentialsAsync: credentialsAsync,
                tokensAsync: tokensAsync,
                useGrid: true,
              ),
              const SizedBox(height: 20),
              CloudSyncDriveStoragePanel(
                tokensAsync: tokensAsync,
                useGrid: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CloudSyncHealthPanel(
                credentialsAsync: credentialsAsync,
                tokensAsync: tokensAsync,
              ),
              const SizedBox(height: 20),
              const CloudSyncAccessPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactCloudSyncLayout extends StatelessWidget {
  const _CompactCloudSyncLayout({
    required this.credentialsAsync,
    required this.tokensAsync,
  });

  final AsyncValue<List<AppCredentialEntry>> credentialsAsync;
  final AsyncValue<List<AuthTokenEntry>> tokensAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CloudSyncPlaygroundHeader(),
        const SizedBox(height: 16),
        CloudSyncHealthPanel(
          credentialsAsync: credentialsAsync,
          tokensAsync: tokensAsync,
        ),
        const SizedBox(height: 16),
        const CloudSyncAccessPanel(),
        const SizedBox(height: 16),
        CloudSyncProviderReadinessPanel(
          credentialsAsync: credentialsAsync,
          tokensAsync: tokensAsync,
        ),
        const SizedBox(height: 16),
        CloudSyncDriveStoragePanel(tokensAsync: tokensAsync),
      ],
    );
  }
}
