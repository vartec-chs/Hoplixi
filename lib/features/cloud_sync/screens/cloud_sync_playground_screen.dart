import 'dart:async';

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
import 'package:hoplixi/features/onboarding/application/showcase_controller.dart';
import 'package:hoplixi/features/onboarding/domain/app_guide_id.dart';
import 'package:hoplixi/features/onboarding/domain/guide_start_mode.dart';
import 'package:hoplixi/features/onboarding/presentation/custom_showcase_tooltip.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_help_button.dart';
import 'package:hoplixi/features/onboarding/presentation/showcase_registration.dart';
import 'package:hoplixi/routing/paths.dart';
import 'package:showcaseview/showcaseview.dart';

class CloudSyncPlaygroundScreen extends ConsumerStatefulWidget {
  const CloudSyncPlaygroundScreen({super.key});

  @override
  ConsumerState<CloudSyncPlaygroundScreen> createState() =>
      _CloudSyncPlaygroundScreenState();
}

const _cloudSyncShowcaseScope = 'cloud_sync_playground_guide';

class _CloudSyncPlaygroundScreenState
    extends ConsumerState<CloudSyncPlaygroundScreen> {
  late final CloudSyncPlaygroundGuideKeys _guideKeys;

  @override
  void initState() {
    super.initState();
    _guideKeys = CloudSyncPlaygroundGuideKeys();
    registerAppGuideShowcase(
      scope: _cloudSyncShowcaseScope,
      onFinish: _markCloudSyncGuideSeen,
      onDismiss: (_) => _markCloudSyncGuideSeen(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_startCloudSyncGuide(GuideStartMode.auto));
    });
  }

  Future<void> _startCloudSyncGuide(GuideStartMode mode) async {
    final controller = ref.read(showcaseControllerProvider.notifier);
    if (mode == GuideStartMode.auto &&
        !await controller.shouldAutoStart(AppGuideId.cloudSyncPlayground)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final keys = _guideKeys.sequence
        .where((key) => key.currentContext != null)
        .toList(growable: false);
    if (keys.isEmpty) {
      return;
    }

    final showcaseView = ShowcaseView.getNamed(_cloudSyncShowcaseScope);
    if (showcaseView.isShowcaseRunning) {
      return;
    }

    showcaseView.startShowCase(keys, delay: const Duration(milliseconds: 250));
  }

  void _markCloudSyncGuideSeen() {
    if (!mounted) {
      return;
    }
    unawaited(
      ref
          .read(showcaseControllerProvider.notifier)
          .markSeen(AppGuideId.cloudSyncPlayground),
    );
  }

  @override
  void dispose() {
    ShowcaseView.getNamed(_cloudSyncShowcaseScope).unregister();
    super.dispose();
  }

  static const double _desktopBreakpoint = 1100;
  static const double _maxDesktopContentWidth = 1380;

  @override
  Widget build(BuildContext context) {
    final credentialsAsync = ref.watch(appCredentialsProvider);
    final tokensAsync = ref.watch(authTokensProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync'),
        actions: [
          ShowcaseHelpButton(
            keys: _guideKeys.sequence,
            scope: _cloudSyncShowcaseScope,
            tooltip: 'Показать подсказки Cloud Sync',
          ),
        ],
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
                padding: EdgeInsets.all(isDesktop ? 24 : 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxDesktopContentWidth,
                    ),
                    child: isDesktop
                        ? _DesktopCloudSyncLayout(
                            credentialsAsync: credentialsAsync,
                            tokensAsync: tokensAsync,
                            guideKeys: _guideKeys,
                          )
                        : _CompactCloudSyncLayout(
                            credentialsAsync: credentialsAsync,
                            tokensAsync: tokensAsync,
                            guideKeys: _guideKeys,
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

class CloudSyncPlaygroundGuideKeys {
  final header = GlobalKey();
  final healthPanel = GlobalKey();
  final accessPanel = GlobalKey();
  final providerReadinessPanel = GlobalKey();
  final driveStoragePanel = GlobalKey();

  List<GlobalKey> get sequence => [
    header,
    healthPanel,
    accessPanel,
    providerReadinessPanel,
    driveStoragePanel,
  ];
}

Widget _wrapCloudSyncShowcase({
  required GlobalKey key,
  required String title,
  required String description,
  required Widget child,
}) {
  return Showcase.withWidget(
    key: key,
    scope: _cloudSyncShowcaseScope,
    container: CustomShowcaseTooltip(title: title, description: description),
    child: child,
  );
}

class _DesktopCloudSyncLayout extends StatelessWidget {
  const _DesktopCloudSyncLayout({
    required this.credentialsAsync,
    required this.tokensAsync,
    required this.guideKeys,
  });

  final AsyncValue<List<AppCredentialEntry>> credentialsAsync;
  final AsyncValue<List<AuthTokenEntry>> tokensAsync;
  final CloudSyncPlaygroundGuideKeys guideKeys;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _wrapCloudSyncShowcase(
                key: guideKeys.header,
                title: 'Cloud Sync Center',
                description:
                    'Здесь собраны быстрые действия для авторизации, credentials и проверки storage API.',
                child: const CloudSyncPlaygroundHeader(isDesktop: true),
              ),
              const SizedBox(height: 20),
              _wrapCloudSyncShowcase(
                key: guideKeys.providerReadinessPanel,
                title: 'Provider readiness',
                description:
                    'Показывает готовность провайдеров и наличие нужных credentials и tokens.',
                child: CloudSyncProviderReadinessPanel(
                  credentialsAsync: credentialsAsync,
                  tokensAsync: tokensAsync,
                  useGrid: true,
                ),
              ),
              const SizedBox(height: 20),
              _wrapCloudSyncShowcase(
                key: guideKeys.driveStoragePanel,
                title: 'Drive Storage API',
                description:
                    'Здесь можно проверить файловые операции и поведение storage-слоя.',
                child: CloudSyncDriveStoragePanel(
                  tokensAsync: tokensAsync,
                  useGrid: true,
                ),
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
              _wrapCloudSyncShowcase(
                key: guideKeys.healthPanel,
                title: 'Health overview',
                description:
                    'Быстрый статус по credentials и tokens для оценки состояния окружения.',
                child: CloudSyncHealthPanel(
                  credentialsAsync: credentialsAsync,
                  tokensAsync: tokensAsync,
                ),
              ),
              const SizedBox(height: 20),
              _wrapCloudSyncShowcase(
                key: guideKeys.accessPanel,
                title: 'Access',
                description:
                    'Переход к авторизации и управлению доступом для выбранного провайдера.',
                child: const CloudSyncAccessPanel(),
              ),
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
    required this.guideKeys,
  });

  final AsyncValue<List<AppCredentialEntry>> credentialsAsync;
  final AsyncValue<List<AuthTokenEntry>> tokensAsync;
  final CloudSyncPlaygroundGuideKeys guideKeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wrapCloudSyncShowcase(
          key: guideKeys.header,
          title: 'Cloud Sync Center',
          description:
              'Быстрые действия для авторизации, App Credentials и проверки storage API.',
          child: const CloudSyncPlaygroundHeader(),
        ),
        const SizedBox(height: 16),
        _wrapCloudSyncShowcase(
          key: guideKeys.healthPanel,
          title: 'Health overview',
          description:
              'Показывает текущий статус credentials и tokens в одном месте.',
          child: CloudSyncHealthPanel(
            credentialsAsync: credentialsAsync,
            tokensAsync: tokensAsync,
          ),
        ),
        const SizedBox(height: 16),
        _wrapCloudSyncShowcase(
          key: guideKeys.accessPanel,
          title: 'Access',
          description:
              'Открывает быстрый доступ к авторизации и управлению доступом.',
          child: const CloudSyncAccessPanel(),
        ),
        const SizedBox(height: 16),
        _wrapCloudSyncShowcase(
          key: guideKeys.providerReadinessPanel,
          title: 'Provider readiness',
          description:
              'Проверяет готовность выбранных провайдеров и связанных учетных данных.',
          child: CloudSyncProviderReadinessPanel(
            credentialsAsync: credentialsAsync,
            tokensAsync: tokensAsync,
          ),
        ),
        const SizedBox(height: 16),
        _wrapCloudSyncShowcase(
          key: guideKeys.driveStoragePanel,
          title: 'Drive Storage API',
          description:
              'Здесь можно тестировать файловые операции и поведение storage API.',
          child: CloudSyncDriveStoragePanel(tokensAsync: tokensAsync),
        ),
      ],
    );
  }
}
